require "../pdfbox"

module Tools
  class PDFText2HTML < Pdfbox::Text::PDFTextStripper
    private INITIAL_PDF_TO_HTML_BYTES = 8192

    @font_state = FontState.new

    def initialize
      super()
      self.line_separator = LINE_SEPARATOR
      self.paragraph_start = "<p>"
      self.paragraph_end = "</p>#{LINE_SEPARATOR}"
      self.page_start = "<div style=\"page-break-before:always; page-break-after:always\">"
      self.page_end = "</div>#{LINE_SEPARATOR}"
      self.article_start = LINE_SEPARATOR
      self.article_end = LINE_SEPARATOR
    end

    def start_document(document : Pdfbox::Pdmodel::Document) : Nil
      title = document.document_information.try(&.title) || ""
      html = String.build(INITIAL_PDF_TO_HTML_BYTES) do |io|
        io << "<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01 Transitional//EN\"\n"
        io << "\"http://www.w3.org/TR/html4/loose.dtd\">\n"
        io << "<html><head>"
        io << "<title>" << self.class.escape(title) << "</title>\n"
        io << "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\">\n"
        io << "</head>\n<body>\n"
      end
      write_string_raw(html)
    end

    def end_document(document : Pdfbox::Pdmodel::Document) : Nil
      write_string_raw("</body></html>")
    end

    protected def render_text_positions(text_positions : Array(Pdfbox::Text::TextPosition)) : String
      ordered = ordered_text_positions(text_positions)
      lines = line_groups_for(ordered)

      write_page_start
      start_article
      lines.each do |line|
        write_paragraph_start
        write_string(line.map(&.visually_ordered_unicode).join, line)
        write_paragraph_end
      end
      end_article
      write_page_end
      ""
    end

    protected def start_article(is_ltr : Bool) : Nil
      if is_ltr
        write_string_raw("<div>")
      else
        write_string_raw("<div dir=\"RTL\">")
      end
    end

    protected def end_article : Nil
      super
      write_string_raw("</div>")
    end

    protected def write_string(text : String, text_positions : Array(Pdfbox::Text::TextPosition)) : Nil
      write_string_raw(@font_state.push(text, text_positions))
    end

    protected def write_string(chars : String) : Nil
      super(self.class.escape(chars))
    end

    protected def write_paragraph_end : Nil
      write_string_raw(@font_state.clear)
      super
    end

    def self.escape(chars : String) : String
      String.build do |io|
        chars.each_char do |char|
          append_escaped(io, char)
        end
      end
    end

    private def self.append_escaped(io : IO, char : Char) : Nil
      codepoint = char.ord
      if codepoint < 32 || codepoint > 126
        io << "&#" << codepoint << ';'
        return
      end

      case char
      when '"'
        io << "&quot;"
      when '&'
        io << "&amp;"
      when '<'
        io << "&lt;"
      when '>'
        io << "&gt;"
      else
        io << char
      end
    end

    private class FontState
      @state_list = [] of String
      @state_set = Set(String).new

      def push(text : String, text_positions : Array(Pdfbox::Text::TextPosition)) : String
        String.build do |io|
          if text.size == text_positions.size
            chars = text.each_char.to_a
            chars.each_with_index do |char, index|
              push(io, char.to_s, text_positions[index])
            end
          elsif !text.empty?
            if text_positions.empty?
              io << text
            else
              first_char = text.each_char.first
              push(io, first_char.to_s, text_positions[0])
              io << PDFText2HTML.escape(text.byte_slice(first_char.bytesize))
            end
          end
        end
      end

      def clear : String
        String.build do |io|
          close_until(io, nil)
          @state_list.clear
          @state_set.clear
        end
      end

      private def push(io : IO, text : String, text_position : Pdfbox::Text::TextPosition) : Nil
        bold = false
        italics = false

        if font = text_position.font
          if descriptor = font.font_descriptor
            bold = bold?(descriptor)
            italics = italic?(descriptor)
          end
        end

        io << (bold ? open("b") : close("b"))
        io << (italics ? open("i") : close("i"))
        io << PDFText2HTML.escape(text)
      end

      private def open(tag : String) : String
        return "" if @state_set.includes?(tag)
        @state_list << tag
        @state_set << tag
        "<#{tag}>"
      end

      private def close(tag : String) : String
        return "" unless @state_set.includes?(tag)

        tags = String.build do |io|
          index = close_until(io, tag)
          @state_list.delete_at(index)
          @state_set.delete(tag)
          while index < @state_list.size
            io << open_tag(@state_list[index])
            index += 1
          end
        end
        tags
      end

      private def close_until(io : IO, end_tag : String?) : Int32
        index = @state_list.size - 1
        while index >= 0
          tag = @state_list[index]
          io << close_tag(tag)
          return index if tag == end_tag
          index -= 1
        end
        -1
      end

      private def open_tag(tag : String) : String
        "<#{tag}>"
      end

      private def close_tag(tag : String) : String
        "</#{tag}>"
      end

      private def bold?(descriptor : Pdfbox::Pdmodel::Font::PDFontDescriptor) : Bool
        descriptor.force_bold? || descriptor.font_name.to_s.includes?("Bold")
      end

      private def italic?(descriptor : Pdfbox::Pdmodel::Font::PDFontDescriptor) : Bool
        descriptor.italic? || descriptor.font_name.to_s.includes?("Italic")
      end
    end
  end
end
