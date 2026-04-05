require "../pdfbox"
require "option_parser"

module Tools
  class ImportXFDF
    @infile : String? = nil
    @outfile : String? = nil
    @data_file : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      build_option_parser.parse(normalize_args(args))

      unless @infile
        @err.puts("Missing required option: -i")
        return 1
      end

      unless @data_file
        @err.puts("Missing required option: --data")
        return 1
      end

      import(@infile.not_nil!, @outfile || @infile.not_nil!, @data_file.not_nil!)
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    rescue ex : IO::Error
      @err.puts("Error importing XFDF data [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
      @data_file = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The PDF file to import to") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The PDF file to save to") { |value| @outfile = value }
        parser.on("--data FILE", "The XFDF data file to import from") { |value| @data_file = value }
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

    private def import(infile : String, outfile : String, data_file : String) : Int32
      pdf = Pdfbox::Loader.load_pdf(infile)
      begin
        form = pdf.document_catalog.try(&.acro_form)
        return 1 unless form
        form.import_fdf(Pdfbox::Loader.load_xfdf(data_file))
        form.need_appearances = true
        pdf.save(outfile)
      ensure
        pdf.close
      end
      0
    end
  end
end
