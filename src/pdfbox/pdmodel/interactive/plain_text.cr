module Pdfbox::Pdmodel::Interactive
  class PlainText
    @paragraphs : Array(Paragraph)

    class Paragraph
      @text : String

      def initialize(@text : String)
      end

      def text : String
        @text
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
        # Acrobat prints a space for an empty paragraph.
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
