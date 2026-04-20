require "../pdfbox"
require "option_parser"

module Tools
  class ExportXFDF
    @infile : String? = nil
    @outfile : String? = nil

    def initialize(@out : IO = STDOUT, @err : IO = STDERR)
    end

    def call(args : Array(String)) : Int32
      reset
      build_option_parser.parse(normalize_args(args))

      unless @infile
        @err.puts("Missing required option: -i")
        return 1
      end

      infile = @infile.as(String)
      outfile = @outfile || default_output(infile, ".xfdf")
      export(infile, outfile)
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    rescue ex : IO::Error
      @err.puts("Error exporting XFDF data [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    end

    private def reset : Nil
      @infile = nil
      @outfile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The PDF file to export") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "The XFDF data file") { |value| @outfile = value }
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

    private def export(infile : String, outfile : String) : Int32
      pdf = Pdfbox::Loader.load_pdf(infile)
      begin
        form = pdf.document_catalog.try(&.acro_form)
        unless form
          @err.puts("Error: This PDF does not contain a form.")
          return 1
        end
        form.export_fdf.save_xfdf(outfile)
      ensure
        pdf.close
      end
      0
    end

    private def default_output(infile : String, extension : String) : String
      base = File.join(File.dirname(infile), File.basename(infile, File.extname(infile)))
      "#{base}#{extension}"
    end
  end
end
