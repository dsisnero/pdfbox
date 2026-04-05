require "../pdfbox"
require "option_parser"

module Tools
  class Overlay
    @infile : String? = nil
    @outfile : String? = nil
    @default_overlay : String? = nil
    @first_page_overlay : String? = nil
    @last_page_overlay : String? = nil
    @odd_page_overlay : String? = nil
    @even_page_overlay : String? = nil
    @use_all_pages : String? = nil
    @position = "BACKGROUND"
    @adjust_rotation = false

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

      process(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error adding overlay(s) to PDF [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
      @default_overlay = nil
      @first_page_overlay = nil
      @last_page_overlay = nil
      @odd_page_overlay = nil
      @even_page_overlay = nil
      @use_all_pages = nil
      @position = "BACKGROUND"
      @adjust_rotation = false
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The PDF input file (required)") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The PDF output file (required)") { |value| @outfile = value }
        parser.on("--default FILE", "The default overlay file") { |value| @default_overlay = value }
        parser.on("--odd FILE", "Overlay file used for odd pages") { |value| @odd_page_overlay = value }
        parser.on("--even FILE", "Overlay file used for even pages") { |value| @even_page_overlay = value }
        parser.on("--first FILE", "Overlay file used for the first page") { |value| @first_page_overlay = value }
        parser.on("--last FILE", "Overlay file used for the last page") { |value| @last_page_overlay = value }
        parser.on("--useAllPages FILE", "Overlay file used for all pages (repeating)") { |value| @use_all_pages = value }
        parser.on("--position POS", "FOREGROUND or BACKGROUND (default: BACKGROUND)") { |value| @position = value }
        parser.on("--adjustRotation", "Adjust rotation for rotated source pages") { @adjust_rotation = true }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox overlay [options]

          Adds an overlay to a PDF document.

          Options:
            -i, --input FILE          The PDF input file (required)
            -o, --output FILE         The PDF output file (required)
            --default FILE            Default overlay file
            --odd FILE                Overlay for odd pages
            --even FILE               Overlay for even pages
            --first FILE              Overlay for first page
            --last FILE               Overlay for last page
            --useAllPages FILE        Overlay for all pages (repeating)
            --position POS            FOREGROUND or BACKGROUND (default)
            --adjustRotation          Adjust rotation for rotated pages
            -h, --help                Show this help

          Example:
            pdfbox overlay -i input.pdf -o output.pdf --default watermark.pdf
            pdfbox overlay -i input.pdf -o output.pdf --odd odd.pdf --even even.pdf
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

    private def process(infile : String, outfile : String) : Int32
      unless File.exists?(infile)
        @err.puts("Input file not found: #{infile}")
        return 1
      end

      overlayer = Pdfbox::Multipdf::Overlay.new

      # Java: overlayer.setOverlayPosition(position)
      position = case @position.upcase
                 when "FOREGROUND" then Pdfbox::Multipdf::Overlay::Position::FOREGROUND
                 else                   Pdfbox::Multipdf::Overlay::Position::BACKGROUND
                 end
      overlayer.position = position

      # Java: overlayer.setFirstPageOverlayFile(...)
      if fp = @first_page_overlay
        overlayer.set_first_page_overlay_file(fp)
      end

      # Java: overlayer.setLastPageOverlayFile(...)
      if lp = @last_page_overlay
        overlayer.set_last_page_overlay_file(lp)
      end

      # Java: overlayer.setOddPageOverlayFile(...)
      if op = @odd_page_overlay
        overlayer.set_odd_page_overlay_file(op)
      end

      # Java: overlayer.setEvenPageOverlayFile(...)
      if ep = @even_page_overlay
        overlayer.set_even_page_overlay_file(ep)
      end

      # Java: overlayer.setAllPagesOverlayFile(...)
      if ap = @use_all_pages
        overlayer.set_all_pages_overlay_file(ap)
      end

      # Java: overlayer.setDefaultOverlayFile(...)
      if df = @default_overlay
        overlayer.set_default_overlay_file(df)
      end

      # Java: overlayer.setInputFile(...)
      overlayer.set_input_file(infile)

      # Java: overlayer.setAdjustRotation(adjustRotation)
      overlayer.adjust_rotation = @adjust_rotation

      # Java: PDDocument result = overlayer.overlay(specificPageOverlayFile)
      result = overlayer.overlay

      # Java: result.save(outfile)
      result.save(outfile)

      0
    ensure
      # Java: overlayer.close()
      overlayer.try(&.close)
    end
  end
end
