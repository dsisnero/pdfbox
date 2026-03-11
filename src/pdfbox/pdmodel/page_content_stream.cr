module Pdfbox::Pdmodel
  # Minimal PDPageContentStream implementation for text-writing parity paths.
  class PDPageContentStream
    @page : Page
    @buffer : ::IO::Memory
    @closed = false

    def initialize(@document : Document, @page : Page)
      @buffer = ::IO::Memory.new
    end

    def begin_text : Nil
      @buffer << "BT\n"
    end

    def new_line_at_offset(tx : Float64 | Int, ty : Float64 | Int) : Nil
      @buffer << format_number(tx) << ' ' << format_number(ty) << " Td\n"
    end

    def set_font(_font : Font::PDFont, font_size : Float64 | Int) : Nil
      @buffer << "/F1 " << format_number(font_size) << " Tf\n"
    end

    def show_text(text : String) : Nil
      escaped = text.gsub("\\", "\\\\").gsub("(", "\\(").gsub(")", "\\)")
      @buffer << '(' << escaped << ") Tj\n"
    end

    def end_text : Nil
      @buffer << "ET\n"
    end

    def close : Nil
      return if @closed
      @closed = true

      stream = Cos::Stream.new(data: @buffer.to_slice)
      @page.contents = stream
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
