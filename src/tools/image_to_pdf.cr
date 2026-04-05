require "../pdfbox"
require "option_parser"

module Tools
  class ImageToPDF
    @infiles : Array(String) = [] of String
    @outfile : String? = nil
    @page_size = "Letter"
    @landscape = false
    @auto_orientation = false
    @resize = false

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infiles = @infiles
      if infiles.empty?
        @err.puts("Missing required option: -i")
        return 1
      end

      outfile = @outfile
      unless outfile
        @err.puts("Missing required option: -o")
        return 1
      end

      process_documents(infiles, outfile)
    rescue ex : IO::Error
      @err.puts("Error converting image to PDF [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infiles.clear
      @outfile = nil
      @page_size = "Letter"
      @landscape = false
      @auto_orientation = false
      @resize = false
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "Image files to convert (can be specified multiple times)") { |value| @infiles << value }
        parser.on("-o FILE", "--output FILE", "The generated PDF file (required)") { |value| @outfile = value }
        parser.on("-pageSize SIZE", "--pageSize SIZE", "Page size: Letter, Legal, A0-A6 (default: Letter)") { |value| @page_size = value }
        parser.on("--landscape", "Set orientation to landscape") { @landscape = true }
        parser.on("--autoOrientation", "Auto orientation based on image proportion") { @auto_orientation = true }
        parser.on("--resize", "Resize image to fill page") { @resize = true }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox fromimage [options]

          Options:
            -i, --input FILE         Image files to convert (can be specified multiple times)
            -o, --output FILE        The generated PDF file (required)
            -pageSize SIZE           Page size: Letter, Legal, A0-A6 (default: Letter)
            -landscape               Set orientation to landscape
            -autoOrientation         Auto orientation based on image proportion
            -resize                  Resize image to fill page
            -h, --help               Show this help

          Example:
            pdfbox fromimage -i photo.jpg -o output.pdf
            pdfbox fromimage -i page1.png -i page2.jpg -o combined.pdf -pageSize A4 -autoOrientation
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

    private def process_documents(infiles : Array(String), outfile : String) : Int32
      infiles.each do |infile|
        unless File.exists?(infile)
          @err.puts("Error: Input file does not exist: #{infile}")
          return 1
        end
      end

      media_box = page_size_rectangle(@page_size)
      doc = Pdfbox::Pdmodel::Document.create

      infiles.each do |infile|
        pd_image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file(infile, doc)

        actual_media_box = media_box
        if (@auto_orientation && pd_image.width > pd_image.height) || @landscape
          actual_media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(
            media_box.height,
            media_box.width
          )
        end

        page = Pdfbox::Pdmodel::Page.new
        page.media_box = actual_media_box
        doc.add_page(page)

        content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(doc, page)
        if @resize
          content_stream.draw_image(pd_image, 0, 0, actual_media_box.width, actual_media_box.height)
        else
          content_stream.draw_image(pd_image, 0, 0, pd_image.width, pd_image.height)
        end
        content_stream.close
      end

      doc.save(outfile)
      @out.puts("Successfully created #{outfile} from #{infiles.size} image(s)") if @out.tty?
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
  end
end
