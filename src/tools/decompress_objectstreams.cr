require "../pdfbox"
require "option_parser"

module Tools
  class DecompressObjectstreams
    @infile : String? = nil
    @outfile : String? = nil

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

      outfile = @outfile || infile
      process(infile, outfile)
    rescue ex : IO::Error
      @err.puts("Error processing file [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The PDF file to decompress") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The decompressed PDF file") { |value| @outfile = value }
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i", "-o"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    private def process(infile : String, outfile : String) : Int32
      doc = Pdfbox::Pdmodel::Document.load(infile)
      begin
        doc.save(outfile, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
      ensure
        doc.close
      end
      0
    end
  end
end
