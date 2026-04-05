require "../pdfbox"
require "option_parser"

module Tools
  class Merge
    @infiles : Array(String) = [] of String
    @outfile : String? = nil
    @password = ""

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infiles = @infiles
      unless infiles.any?
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
      @err.puts("Error merging documents [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infiles.clear
      @outfile = nil
      @password = ""
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--password PASSWORD", "The password for encrypted PDFs") { |value| @password = value }
        parser.on("-i FILE", "--input FILE", "PDF files to merge (can be specified multiple times)") { |value| @infiles << value }
        parser.on("-o FILE", "--output FILE", "The merged PDF file (required)") { |value| @outfile = value }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox merge [options]

          Options:
            --password PASSWORD    The password for encrypted PDFs
            -i, --input FILE       PDF files to merge (can be specified multiple times)
            -o, --output FILE      The merged PDF file (required)
            -h, --help             Show this help

          Example:
            pdfbox merge -i file1.pdf -i file2.pdf -o merged.pdf
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
      # Check if input files exist
      infiles.each do |infile|
        unless File.exists?(infile)
          @err.puts("Error: Input file does not exist: #{infile}")
          return 1
        end
      end

      # Create new document
      merged_doc = Pdfbox::Pdmodel::Document.create

      # Process each input file
      infiles.each_with_index do |infile, _|
        begin
          # Load document
          document = Pdfbox::Loader.load_pdf(infile, @password)

          # Check if document is encrypted and we don't have permission
          if document.encryption && !document.current_access_permission.can_extract_content?
            @err.puts("Error: Cannot extract pages from encrypted document #{infile} without proper permissions")
            return 1
          end

          # Extract all pages using PageExtractor
          extractor = Pdfbox::Multipdf::PageExtractor.new(document, 1, document.number_of_pages)
          extracted_doc = extractor.extract

          # Add pages to merged document
          extracted_doc.pages.each do |page|
            merged_doc.add_page(page)
          end

          @err.puts("Added #{document.number_of_pages} pages from #{File.basename(infile)}") if @err.tty?
        rescue ex : IO::Error
          if ex.message.to_s.downcase.includes?("password")
            @err.puts("Error: Incorrect password for #{infile} or unable to decrypt")
          else
            @err.puts("Error loading #{infile}: #{ex.message}")
          end
          return 4
        end
      end

      # Save merged document
      merged_doc.save(outfile)

      @out.puts("Successfully merged #{infiles.size} files to #{outfile}") if @out.tty?
      0
    end
  end
end
