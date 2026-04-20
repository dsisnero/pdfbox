module Pdfbox::Pdmodel::Interactive
  class PlainTextFormatter
    FONT_SCALE = 1000.0_f32

    class Builder
      @contents : Pdfbox::Pdmodel::PDPageContentStream
      @appearance_style : AppearanceStyle?
      @wrap_lines = false
      @width = 0.0_f32
      @text_content : PlainText?
      @text_alignment = TextAlign::LEFT
      @horizontal_offset = 0.0_f32
      @vertical_offset = 0.0_f32

      def initialize(@contents : Pdfbox::Pdmodel::PDPageContentStream)
      end

      def style(value : AppearanceStyle) : self
        @appearance_style = value
        self
      end

      def wrap_lines(value : Bool) : self
        @wrap_lines = value
        self
      end

      def width(value : Number) : self
        @width = value.to_f32
        self
      end

      def text_align(alignment : Int) : self
        @text_alignment = TextAlign.value_of(alignment)
        self
      end

      def text_align(alignment : TextAlign) : self
        @text_alignment = alignment
        self
      end

      def text(value : PlainText) : self
        @text_content = value
        self
      end

      def initial_offset(horizontal_offset : Number, vertical_offset : Number) : self
        @horizontal_offset = horizontal_offset.to_f32
        @vertical_offset = vertical_offset.to_f32
        self
      end

      def build : PlainTextFormatter
        PlainTextFormatter.new(self)
      end

      getter contents, appearance_style, wrap_lines, width, text_content, text_alignment, horizontal_offset, vertical_offset
    end

    @appearance_style : AppearanceStyle
    @wrap_lines : Bool
    @width : Float32
    @contents : Pdfbox::Pdmodel::PDPageContentStream
    @text_content : PlainText?
    @text_alignment : TextAlign
    @horizontal_offset : Float32
    @vertical_offset : Float32

    def initialize(builder : Builder)
      @appearance_style = builder.appearance_style || raise ArgumentError.new("appearance_style is required")
      @wrap_lines = builder.wrap_lines
      @width = builder.width
      @contents = builder.contents
      @text_content = builder.text_content
      @text_alignment = builder.text_alignment
      @horizontal_offset = builder.horizontal_offset
      @vertical_offset = builder.vertical_offset
    end

    def format : Nil
      text_content = @text_content
      return if text_content.nil? || text_content.paragraphs.empty?

      is_first_paragraph = true
      text_content.paragraphs.each do |paragraph|
        if @wrap_lines
          process_lines(paragraph.lines(font, @appearance_style.font_size, @width), is_first_paragraph)
          is_first_paragraph = false
        else
          start_offset = start_offset_for_paragraph(paragraph)
          @contents.new_line_at_offset(@horizontal_offset + start_offset, @vertical_offset)
          @contents.show_text(paragraph.text)
        end
      end
    end

    private def process_lines(lines : Array(PlainText::Line), is_first_paragraph : Bool) : Nil
      last_pos = 0.0_f32

      lines.each_with_index do |line, line_index|
        start_offset = 0.0_f32
        inter_word_spacing = 0.0_f32

        case @text_alignment
        when TextAlign::CENTER
          start_offset = (@width - line.width) / 2.0_f32
        when TextAlign::RIGHT
          start_offset = @width - line.width
        when TextAlign::JUSTIFY
          inter_word_spacing = line.inter_word_spacing(@width) if line_index != lines.size - 1
        end

        offset = -last_pos + start_offset + @horizontal_offset

        if line_index == 0 && is_first_paragraph
          @contents.new_line_at_offset(offset, @vertical_offset)
        else
          @vertical_offset -= @appearance_style.leading
          @contents.new_line_at_offset(offset, -@appearance_style.leading)
        end

        last_pos += offset

        words = line.words
        words.each_with_index do |word, word_index|
          @contents.show_text(word.text)
          next if word_index == words.size - 1

          @contents.new_line_at_offset(word.width + inter_word_spacing, 0.0_f32)
          last_pos += word.width + inter_word_spacing
        end
      end

      @horizontal_offset -= last_pos
    end

    private def start_offset_for_paragraph(paragraph : PlainText::Paragraph) : Float32
      line_width = font.get_string_width(paragraph.text) * @appearance_style.font_size / FONT_SCALE
      return 0.0_f32 unless line_width < @width

      case @text_alignment
      when TextAlign::CENTER
        (@width - line_width) / 2.0_f32
      when TextAlign::RIGHT
        @width - line_width
      else
        0.0_f32
      end
    end

    private def font : Pdfbox::Pdmodel::Font::PDFont
      @appearance_style.font || raise ArgumentError.new("appearance_style.font is required")
    end
  end
end
