require "../pdfbox"
require "option_parser"

module Tools
  class WriteDecodedDoc
    @infile : String? = nil
    @outfile : String? = nil
    @password = ""
    @skip_images = false

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      parser = build_option_parser
      parser.parse(normalize_args(args))

      infile = @infile
      unless infile
        @err.puts("Missing required input file")
        return 1
      end

      outfile = @outfile
      unless outfile
        outfile = calculate_output_filename(infile)
      end

      process(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error writing decoded PDF [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
      @password = ""
      @skip_images = false
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.banner = "Usage: pdfbox decode [options] inputfile [outputfile]"
        parser.on("-password PASSWORD", "The password to decrypt the document") { |value| @password = value }
        parser.on("-skipImages", "Don't uncompress images") { @skip_images = true }
        parser.on("-h", "--help", "Show this help") do
          @out.puts <<-HELP
          Usage: pdfbox decode [options] inputfile [outputfile]

          Writes a PDF document with all streams decoded.

          Options:
            -password PASSWORD        The password to decrypt the document
            -skipImages               Don't uncompress images
            -h, --help                Show this help

          Examples:
            pdfbox decode input.pdf
            pdfbox decode input.pdf output_decoded.pdf
            pdfbox decode -password secret input.pdf
          HELP
          exit 0
        end
        parser.unknown_args do |args, _|
          @infile = args[0] if args.size > 0
          @outfile = args[1] if args.size > 1
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-h"}.includes?(arg)
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

      doc = Pdfbox::Pdmodel::Document.load(infile)

      # Re-save without compression to produce decoded output.
      # This removes object streams and cross-reference streams,
      # making the PDF content readable for debugging.
      doc.save(outfile, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)

      @out.puts("Decoded PDF saved to #{outfile}") if @out.tty?
      0
    end

    private def calculate_output_filename(filename : String) : String
      if filename.downcase.ends_with?(".pdf")
        "#{filename[0...-4]}_unc.pdf"
      else
        "#{filename}_unc.pdf"
      end
    end
  end
end
