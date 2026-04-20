require "../pdfbox"
require "option_parser"

module Tools
  class ExtractXMP
    @page = 0
    @password = ""
    @to_console = false
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

      process_document(infile)
    rescue ex : IO::Error
      @err.puts("Error extracting XMP for document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    end

    private def reset : Nil
      @page = 0
      @password = ""
      @to_console = false
      @infile = nil
      @outfile = nil
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-page PAGE", "Extract the XMP information from a specific page (1 based)") do |value|
          @page = value.to_i
        end
        parser.on("-password PASSWORD", "The password for the PDF or certificate in keystore") do |value|
          @password = value
        end
        parser.on("-console", "Send text to console instead of file") do
          @to_console = true
        end
        parser.on("-i FILE", "--input FILE", "The PDF file (required)") do |value|
          @infile = value
        end
        parser.on("-o FILE", "--output FILE", "The exported XML file") do |value|
          @outfile = value
        end
        parser.on("-h", "--help", "Show this help") do
          @out.puts(parser)
          exit 0
        end
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      # Convert --option=value to --option value for OptionParser
      normalized = [] of String
      args.each do |arg|
        if arg.starts_with?("--") && arg.includes?('=')
          parts = arg.split('=', 2)
          normalized << parts[0]
          normalized << parts[1] unless parts[1].empty?
        else
          normalized << arg
        end
      end
      normalized
    end

    private def process_document(infile : String) : Int32
      # Determine output file
      outfile = if @to_console
                  nil
                elsif @outfile
                  @outfile
                else
                  # Java: FilenameUtils.removeExtension(infile.getAbsolutePath()) + ".xml"
                  base = File.basename(infile, File.extname(infile))
                  dir = File.dirname(infile)
                  File.join(dir, "#{base}.xml")
                end

      # Load document
      document = Pdfbox::Loader.load_pdf(infile, @password)

      # Get metadata
      meta = if @page == 0
               # Get from document catalog
               catalog = document.document_catalog
               return 1 unless catalog
               catalog.metadata
             else
               # Get from specific page (1-based in Java, 0-based in our array)
               if @page > document.page_count
                 @err.puts("Page #{@page} doesn't exist")
                 return 1
               end
               # Note: Our pages array is 0-based, Java getPage is 0-based for page index
               page = document.pages[@page - 1]?
               return 1 unless page
               page.metadata
             end

      unless meta
        @err.puts("No XMP metadata available")
        return 1
      end

      # Export XMP metadata
      xmp_io = meta.export_xmp_metadata
      xmp_data = xmp_io.gets_to_end

      if @to_console
        @out.write(xmp_data.to_slice)
        @out.flush
      else
        # Java: Files.write(outfile.toPath(), meta.toByteArray())
        File.write(outfile.as(String), xmp_data)
      end

      0
    ensure
      document.try(&.close)
    end
  end
end
