module Pdfbox::Pdmodel
  # Minimal PDPageContentStream implementation for text-writing parity paths.
  class PDPageContentStream
    @page : Page
    @buffer : ::IO::Memory
    @closed = false
    @font_name : String?

    def initialize(@document : Document, @page : Page)
      @buffer = ::IO::Memory.new
    end

    def begin_text : Nil
      @buffer << "BT\n"
    end

    def new_line_at_offset(tx : Float64 | Int, ty : Float64 | Int) : Nil
      @buffer << format_number(tx) << ' ' << format_number(ty) << " Td\n"
    end

    def set_font(font : Font::PDFont, font_size : Float64 | Int) : Nil
      # Add font to page resources
      add_font_to_resources(font)
      @buffer << "/#{@font_name} " << format_number(font_size) << " Tf\n"
    end

    def show_text(text : String) : Nil
      # Get the current font from the page resources
      font = get_current_font
      if font
        # Encode the text using the font's encoding
        encoded = encode_text(text, font)
        escaped = String.new(encoded).gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
        @buffer << '(' << escaped << ") Tj\n"
      else
        # Fallback: write text as-is (UTF-8)
        escaped = text.gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
        @buffer << '(' << escaped << ") Tj\n"
      end
    end

    private def get_current_font : Font::PDFont?
      font_name = @font_name
      return nil unless font_name

      cos_page = @page.cos_object
      return nil unless cos_page

      resources = cos_page[Cos::Name.new("Resources")]?
      return nil unless resources

      if resources.is_a?(Cos::Object)
        resources = resources.object
      end

      return nil unless resources.is_a?(Cos::Dictionary)

      fonts = resources[Cos::Name.new("Font")]?
      return nil unless fonts

      if fonts.is_a?(Cos::Object)
        fonts = fonts.object
      end

      return nil unless fonts.is_a?(Cos::Dictionary)

      font_dict = fonts[Cos::Name.new(font_name)]?
      return nil unless font_dict

      if font_dict.is_a?(Cos::Object)
        font_dict = font_dict.object
      end

      return nil unless font_dict.is_a?(Cos::Dictionary)

      Font::PDFontFactory.create_font(font_dict)
    end

    private def encode_text(text : String, font : Font::PDFont) : Bytes
      # Use the font's public encode method
      font.encode(text)
    end

    def end_text : Nil
      @buffer << "ET\n"
    end

    def close : Nil
      return if @closed
      @closed = true

      stream = Cos::Stream.new
      encoded_output = stream.create_output_stream(Cos::Name::FLATE_DECODE)
      encoded_output.write(@buffer.to_slice)
      encoded_output.close
      @page.contents = stream
    end

    private def add_font_to_resources(font : Font::PDFont) : Nil
      return if @font_name

      # Get or create page resources
      cos_page = @page.cos_object
      return unless cos_page

      resources = cos_page[Cos::Name.new("Resources")]?
      unless resources
        resources = Cos::Dictionary.new
        cos_page[Cos::Name.new("Resources")] = resources
      end

      if resources.is_a?(Cos::Object)
        resources = resources.object
      end

      return unless resources.is_a?(Cos::Dictionary)

      # Get or create font dictionary
      fonts = resources[Cos::Name.new("Font")]?
      unless fonts
        fonts = Cos::Dictionary.new
        resources[Cos::Name.new("Font")] = fonts
      end

      if fonts.is_a?(Cos::Object)
        fonts = fonts.object
      end

      return unless fonts.is_a?(Cos::Dictionary)

      # Generate font name and add to resources
      font_name = "F#{fonts.size + 1}"
      @font_name = font_name
      fonts[Cos::Name.new(font_name)] = font.cos_object
    end

    private def format_number(value : Float64 | Int) : String
      if value.is_a?(Int)
        value.to_s
      else
        value.round == value ? value.to_i.to_s : value.to_s
      end
    end
  end
end
