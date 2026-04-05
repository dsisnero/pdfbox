require "../pdfbox"
require "option_parser"

module Tools
  class TextToPDF
    FONT_SCALE           = 1000.0_f32
    DEFAULT_FONT_SIZE    =   10.0_f32
    DEFAULT_LINE_SPACING =   1.05_f32
    DEFAULT_MARGIN       =   40.0_f32

    @infile : String? = nil
    @outfile : String? = nil
    @page_size = "Letter"
    @landscape = false
    @font_size = DEFAULT_FONT_SIZE
    @line_spacing = DEFAULT_LINE_SPACING
    @margins = [DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN]
    @standard_font = "Helvetica"
    @ttf_path : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infile = @infile
      unless infile
        @err.puts("Missing required option: -i")
        return 1
      end

      outfile = @outfile
      unless outfile
        @err.puts("Missing required option: -o")
        return 1
      end

      process_document(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error converting text to PDF [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
      @page_size = "Letter"
      @landscape = false
      @font_size = DEFAULT_FONT_SIZE
      @line_spacing = DEFAULT_LINE_SPACING
      @margins = [DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN, DEFAULT_MARGIN]
      @standard_font = "Helvetica"
      @ttf_path = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The text file to convert") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The generated PDF file (required)") { |value| @outfile = value }
        parser.on("-fontSize SIZE", "--fontSize SIZE", "Font size (default: #{DEFAULT_FONT_SIZE})") { |value| @font_size = value.to_f32 }
        parser.on("--lineSpacing FACTOR", "Line height factor (default: #{DEFAULT_LINE_SPACING})") { |value| @line_spacing = value.to_f32 }
        parser.on("--landscape", "Set orientation to landscape") { @landscape = true }
        parser.on("-pageSize SIZE", "--pageSize SIZE", "Page size: Letter, Legal, A0-A6 (default: Letter)") { |value| @page_size = value }
        parser.on("--margins L,R,T,B", "Margins: left,right,top,bottom (default: 40,40,40,40)") do |value|
          parts = value.split(',').map(&.strip.to_f32)
          case parts.size
          when 1 then @margins = [parts[0], parts[0], parts[0], parts[0]]
          when 4 then @margins = parts
          else        raise ArgumentError.new("Margins must be 1 or 4 values: L,R,T,B")
          end
        end
        parser.on("-standardFont NAME", "--standardFont NAME", "Standard font: Helvetica, Courier, Times-Roman, etc.") { |value| @standard_font = value }
        parser.on("-ttf FILE", "--ttf FILE", "TTF font file to use") { |value| @ttf_path = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox fromtext [options]

          Options:
            -i, --input FILE         The text file to convert
            -o, --output FILE        The generated PDF file (required)
            -fontSize SIZE           Font size (default: #{DEFAULT_FONT_SIZE})
            --lineSpacing FACTOR     Line height factor (default: #{DEFAULT_LINE_SPACING})
            --landscape              Set orientation to landscape
            -pageSize SIZE           Page size: Letter, Legal, A0-A6 (default: Letter)
            --margins L,R,T,B        Margins (default: 40,40,40,40)
            -standardFont NAME       Standard font (default: Helvetica)
            -ttf FILE                TTF font file to use
            -h, --help               Show this help

          Example:
            pdfbox fromtext -i notes.txt -o notes.pdf
            pdfbox fromtext -i readme.txt -o readme.pdf -fontSize 12 -pageSize A4
          HELP
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-o", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process_document(infile : String, outfile : String) : Int32
      unless File.exists?(infile)
        @err.puts("Error: Input file does not exist: #{infile}")
        return 1
      end

      doc = Pdfbox::Pdmodel::Document.create

      font_name = parse_standard_font(@standard_font)
      font = Pdfbox::Pdmodel::Font::PDType1Font.new(font_name)

      media_box = page_size_rectangle(@page_size)
      actual_media_box = if @landscape
                           Pdfbox::Pdmodel::Rectangle.from_dimensions(media_box.height, media_box.width)
                         else
                           media_box
                         end

      font_height = font.bounding_box.height / FONT_SCALE
      line_height = font_height * @font_size * @line_spacing
      left_margin = @margins[0]
      right_margin = @margins[1]
      top_margin = @margins[2]
      bottom_margin = @margins[3]

      text_is_empty = true
      page : Pdfbox::Pdmodel::Page? = nil
      content_stream : Pdfbox::Pdmodel::PDPageContentStream? = nil
      y = 0.0_f32

      File.each_line(infile) do |raw_line|
        text_is_empty = false
        line = raw_line.chomp("\r")
        words = line.split(' ', remove_empty: false)

        line_index = 0
        while line_index < words.size
          next_line_parts = [] of String
          add_space = false

          loop do
            word = words[line_index]
            if add_space
              candidate = (next_line_parts + [""]).join(" ") + word
              width = (font.get_string_width(candidate) / FONT_SCALE) * @font_size
              break if width >= actual_media_box.width - left_margin - right_margin
            end
            next_line_parts << word
            add_space = true
            line_index += 1
            break if line_index >= words.size
          end

          drawn_text = next_line_parts.join(" ")

          if page.nil? || y - line_height < bottom_margin
            if cs = content_stream
              cs.end_text
              cs.close
            end

            page = Pdfbox::Pdmodel::Page.new
            page.not_nil!.media_box = actual_media_box
            doc.add_page(page.not_nil!)

            content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page.not_nil!)
            content_stream.not_nil!.set_font(font, @font_size)
            content_stream.not_nil!.begin_text

            y = actual_media_box.height - top_margin
            y += line_height - font_height * @font_size
            content_stream.not_nil!.new_line_at_offset(left_margin, y)
          end

          content_stream.not_nil!.new_line_at_offset(0, -line_height)
          y -= line_height
          content_stream.not_nil!.show_text(drawn_text)
        end
      end

      if text_is_empty
        empty_page = Pdfbox::Pdmodel::Page.new
        empty_page.media_box = actual_media_box
        doc.add_page(empty_page)
      end

      if cs = content_stream
        cs.end_text
        cs.close
      end

      doc.save(outfile)
      @out.puts("Successfully created #{outfile}") if @out.tty?
      0
    end

    private def page_size_rectangle(size : String) : Pdfbox::Pdmodel::Rectangle
      case size.downcase
      when "letter"  then Pdfbox::Pdmodel::PageSizes::LETTER
      when "legal"   then Pdfbox::Pdmodel::PageSizes::LEGAL
      when "tabloid" then Pdfbox::Pdmodel::PageSizes::TABLOID
      when "a0"      then Pdfbox::Pdmodel::PageSizes::A0
      when "a1"      then Pdfbox::Pdmodel::PageSizes::A1
      when "a2"      then Pdfbox::Pdmodel::PageSizes::A2
      when "a3"      then Pdfbox::Pdmodel::PageSizes::A3
      when "a4"      then Pdfbox::Pdmodel::PageSizes::A4
      when "a5"      then Pdfbox::Pdmodel::PageSizes::A5
      when "a6"      then Pdfbox::Pdmodel::PageSizes::A6
      else
        Pdfbox::Pdmodel::PageSizes::LETTER
      end
    end

    FONT_NAMES = {
      "Helvetica"             => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA,
      "Helvetica-Bold"        => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD,
      "Helvetica-Oblique"     => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_OBLIQUE,
      "Helvetica-BoldOblique" => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD_OBLIQUE,
      "Courier"               => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER,
      "Courier-Bold"          => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER_BOLD,
      "Courier-Oblique"       => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER_OBLIQUE,
      "Courier-BoldOblique"   => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::COURIER_BOLD_OBLIQUE,
      "Times-Roman"           => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_ROMAN,
      "Times-Bold"            => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_BOLD,
      "Times-Italic"          => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_ITALIC,
      "Times-BoldItalic"      => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::TIMES_BOLD_ITALIC,
      "Symbol"                => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::SYMBOL,
      "ZapfDingbats"          => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS,
    } of String => Pdfbox::Pdmodel::Font::Standard14Fonts::FontName

    private def parse_standard_font(name : String) : Pdfbox::Pdmodel::Font::Standard14Fonts::FontName
      FONT_NAMES[name]? || Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA
    end
  end
end
