module Pdfbox::Pdmodel::Interactive
  class PlainText
    FONT_SCALE = 1000.0_f32

    module TextAttribute
      WIDTH = "width"
    end

    @paragraphs : Array(Paragraph)

    class Paragraph
      @text : String
      @queued_segments : Array(String)?

      def initialize(@text : String)
      end

      def text : String
        @text
      end

      def lines(font : Pdfbox::Pdmodel::Font::PDFont, font_size : Number, width : Number) : Array(Line)
        available_width = width.to_f32
        return [] of Line if available_width <= 0.0_f32

        scale = font_size.to_f32 / FONT_SCALE
        text_lines = [] of Line
        text_line = Line.new
        line_width = 0.0_f32
        pending_segments = segments.dup

        until pending_segments.empty?
          segment = pending_segments.shift
          word = segment
          word_width = font.get_string_width(word) * scale
          word_needs_split = false
          split_offset = word.size

          line_width += word_width

          if line_width >= available_width && trailing_whitespace?(word)
            line_width -= font.get_string_width(word[-1].to_s) * scale
          end

          if line_width >= available_width && !text_line.words.empty?
            text_line.width = text_line.calculate_width(font, font_size)
            text_lines << text_line
            text_line = Line.new
            line_width = font.get_string_width(word) * scale
          end

          if word.size > 1 && word_width > available_width && text_line.words.empty?
            word_needs_split = true
            split_offset = fitting_prefix_length(font, word, scale, available_width)
            word = prefix_by_char_count(word, split_offset)
            word_width = font.get_string_width(word) * scale
            line_width = word_width
          end

          text_line.add_word(Word.new(word, word_width))

          if word_needs_split
            remaining = suffix_by_char_count(segment, split_offset)
            pending_segments.unshift(remaining) unless remaining.empty?
          end
        end

        text_line.width = text_line.calculate_width(font, font_size)
        text_lines << text_line
        text_lines
      end

      private def segments : Array(String)
        queued = @queued_segments
        return queued unless queued.nil?

        built = [] of String
        chars = @text.chars
        index = 0
        while index < chars.size
          if chars[index].whitespace?
            start = index
            index += 1
            while index < chars.size && chars[index].whitespace?
              index += 1
            end
            built << chars[start...index].join
          else
            start = index
            while index < chars.size && !chars[index].whitespace?
              index += 1
            end
            while index < chars.size && chars[index].whitespace?
              index += 1
            end
            built << chars[start...index].join
          end
        end

        @queued_segments = built
        built
      end

      private def fitting_prefix_length(font : Pdfbox::Pdmodel::Font::PDFont, word : String, scale : Float32, width : Float32) : Int32
        chars = word.chars
        split_offset = chars.size
        while split_offset > 1
          split_offset -= 1
          substring = chars[0, split_offset].join
          return split_offset.to_i32 if font.get_string_width(substring) * scale < width
        end
        1
      end

      private def prefix_by_char_count(text : String, count : Int) : String
        text.chars[0, count].join
      end

      private def suffix_by_char_count(text : String, count : Int) : String
        chars = text.chars
        return "" if count >= chars.size
        chars[count..].join
      end

      private def trailing_whitespace?(text : String) : Bool
        last = text[-1]?
        !last.nil? && last.whitespace?
      end
    end

    class Line
      @words = [] of Word
      property width : Float32 = 0.0_f32

      def words : Array(Word)
        @words
      end

      def calculate_width(font : Pdfbox::Pdmodel::Font::PDFont, font_size : Number) : Float32
        scale = font_size.to_f32 / FONT_SCALE
        calculated_width = 0.0_f32

        @words.each_with_index do |word, index|
          calculated_width += word.width
          text = word.text
          if index == @words.size - 1 && !text.empty? && text[-1].whitespace?
            calculated_width -= font.get_string_width(text[-1].to_s) * scale
          end
        end

        calculated_width
      end

      def inter_word_spacing(width : Number) : Float32
        return 0.0_f32 if @words.size <= 1
        (width.to_f32 - @width) / (@words.size - 1)
      end

      def add_word(word : Word) : Word
        @words << word
        word
      end
    end

    class Word
      @text : String
      @width : Float32

      def initialize(@text : String, @width : Float32)
      end

      def text : String
        @text
      end

      def width : Float32
        @width
      end
    end

    def initialize(text_value : String)
      if text_value.empty?
        @paragraphs = [Paragraph.new("")]
        return
      end

      parts = split_by_line_breaks(text_value.gsub('\t', ' '))
      @paragraphs = Array(Paragraph).new(parts.size)
      parts.each do |part|
        @paragraphs << Paragraph.new(part.empty? ? " " : part)
      end
    end

    def initialize(list_value : Array(String))
      @paragraphs = Array(Paragraph).new(list_value.size)
      list_value.each do |part|
        @paragraphs << Paragraph.new(part)
      end
    end

    def paragraphs : Array(Paragraph)
      @paragraphs
    end

    private def split_by_line_breaks(text : String) : Array(String)
      parts = [] of String
      current = ""
      previous_was_cr = false

      text.each_char do |char|
        if previous_was_cr && char == '\n'
          previous_was_cr = false
          next
        end

        if line_break_char?(char)
          parts << current
          current = ""
          previous_was_cr = (char == '\r')
        else
          current += char
          previous_was_cr = false
        end
      end
      parts << current
      parts
    end

    private def line_break_char?(char : Char) : Bool
      char == '\n' ||
        char == '\r' ||
        char == '\v' ||
        char == '\f' ||
        char.ord == 0x85 ||
        char.ord == 0x2028 ||
        char.ord == 0x2029
    end
  end
end
