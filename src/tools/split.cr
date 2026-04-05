require "../pdfbox"
require "option_parser"

module Tools
  class Split
    @password = ""
    @split = -1
    @start_page = -1
    @end_page = -1
    @output_prefix : String? = nil
    @infile : String? = nil

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

      output_prefix = @output_prefix || File.basename(infile, File.extname(infile))

      process_document(infile, output_prefix)
    rescue ex : IO::Error
      @err.puts("Error splitting document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @password = ""
      @split = -1
      @start_page = -1
      @end_page = -1
      @output_prefix = nil
      @infile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--password PASSWORD", "The password to decrypt the document") { |value| @password = value }
        parser.on("--split SPLIT", "Split after this many pages (default 1, if startPage and endPage are unset)") { |value| @split = value.to_i }
        parser.on("--startPage START", "Start page (1-based)") { |value| @start_page = value.to_i }
        parser.on("--endPage END", "End page (1-based)") { |value| @end_page = value.to_i }
        parser.on("--outputPrefix PREFIX", "The filename prefix for split files") { |value| @output_prefix = value }
        parser.on("-i FILE", "--input FILE", "The PDF file to split (required)") { |value| @infile = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox split [options]

          Options:
            --password PASSWORD    The password to decrypt the document
            --split SPLIT          Split after this many pages (default 1, if startPage and endPage are unset)
            --startPage START      Start page (1-based)
            --endPage END          End page (1-based)
            --outputPrefix PREFIX  The filename prefix for split files
            -i, --input FILE       The PDF file to split (required)
            -h, --help             Show this help

          Examples:
            # Split every page into separate files
            pdfbox split -i input.pdf

            # Split every 2 pages
            pdfbox split -i input.pdf --split 2

            # Extract pages 3-5
            pdfbox split -i input.pdf --startPage 3 --endPage 5

            # Extract from page 3 to end
            pdfbox split -i input.pdf --startPage 3

            # Extract first 5 pages
            pdfbox split -i input.pdf --endPage 5
          HELP
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-h"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process_document(infile : String, output_prefix : String) : Int32
      # Check if input file exists
      unless File.exists?(infile)
        @err.puts("Input file not found: #{infile}")
        return 1
      end

      # Load document
      document = Pdfbox::Loader.load_pdf(infile, @password)
      total_pages = document.number_of_pages

      # Determine split strategy
      if @start_page != -1 || @end_page != -1
        # Extract page range
        start_page = @start_page != -1 ? @start_page : 1
        end_page = @end_page != -1 ? @end_page : total_pages

        # Validate page range
        if start_page < 1 || start_page > total_pages
          @err.puts("Start page #{start_page} is out of range (1-#{total_pages})")
          return 1
        end

        if end_page < 1 || end_page > total_pages
          @err.puts("End page #{end_page} is out of range (1-#{total_pages})")
          return 1
        end

        if start_page > end_page
          @err.puts("Start page (#{start_page}) cannot be greater than end page (#{end_page})")
          return 1
        end

        # Extract single range
        extractor = Pdfbox::Multipdf::PageExtractor.new(document, start_page, end_page)
        extracted = extractor.extract

        output_file = "#{output_prefix}-#{start_page}-#{end_page}.pdf"
        extracted.save(output_file)
        @out.puts("Created: #{output_file} (pages #{start_page}-#{end_page})")

        extracted.close
      else
        # Split by page count
        split_at = @split != -1 ? @split : 1

        if split_at < 1
          @err.puts("Split value must be at least 1")
          return 1
        end

        page_count = 0
        file_index = 1

        while page_count < total_pages
          start_page = page_count + 1
          end_page = Math.min(page_count + split_at, total_pages)

          extractor = Pdfbox::Multipdf::PageExtractor.new(document, start_page, end_page)
          extracted = extractor.extract

          output_file = "#{output_prefix}-#{file_index}.pdf"
          extracted.save(output_file)
          @out.puts("Created: #{output_file} (pages #{start_page}-#{end_page})")

          extracted.close

          page_count += split_at
          file_index += 1
        end
      end

      document.close
      0
    end
  end
end
