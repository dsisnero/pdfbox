require "../pdfbox"
require "option_parser"

module Tools
  class ExtractText
    STD_ENCODING = "UTF-8"

    @always_next = false
    @to_console = false
    @debug = false
    @encoding = STD_ENCODING
    @end_page = Int32::MAX
    @to_html = false
    @to_md = false
    @ignore_beads = false
    @password = ""
    @rotation_magic = false
    @sort = false
    @start_page = 1
    @infile : String? = nil
    @outfile : String? = nil
    @add_file_name = false
    @append = false

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

      validate_output_mode || return 1
      configure_output_path(infile)
      emit_encoding_warnings
      process_document(infile)
    rescue ex : IO::Error
      @err.puts("Error extracting text for document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    end

    private def reset : Nil
      @always_next = false
      @to_console = false
      @debug = false
      @encoding = STD_ENCODING
      @end_page = Int32::MAX
      @to_html = false
      @to_md = false
      @ignore_beads = false
      @password = ""
      @rotation_magic = false
      @sort = false
      @start_page = 1
      @infile = nil
      @outfile = nil
      @add_file_name = false
      @append = false
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("--alwaysNext", "Process next page despite IOException") { @always_next = true }
        parser.on("--console", "Send text to console instead of file") { @to_console = true }
        parser.on("--debug", "Enable debug output") { @debug = true }
        parser.on("--encoding ENCODING", "Output encoding") { |value| @encoding = value }
        parser.on("--endPage PAGE", "Last page to extract") { |value| @end_page = value.to_i }
        parser.on("--html", "Output HTML") { @to_html = true }
        parser.on("--md", "Output Markdown") { @to_md = true }
        parser.on("--ignoreBeads", "Disable separation by beads") { @ignore_beads = true }
        parser.on("--password PASSWORD", "PDF password") { |value| @password = value }
        parser.on("--rotationMagic", "Analyze rotated text") { @rotation_magic = true }
        parser.on("--sort", "Sort text before writing") { @sort = true }
        parser.on("--startPage PAGE", "First page to extract") { |value| @start_page = value.to_i }
        parser.on("-i FILE", "--input FILE", "Input PDF file") { |value| @infile = value }
        parser.on("-o FILE", "--output FILE", "Output text file") { |value| @outfile = value }
        parser.on("--addFileName", "Print PDF file name to output") { @add_file_name = true }
        parser.on("--append", "Append to output file") { @append = true }
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

    private def build_stripper : Pdfbox::Text::PDFTextStripper
      stripper = if @to_html
                   Tools::PDFText2HTML.new
                 else
                   Pdfbox::Text::PDFTextStripper.new
                 end
      stripper.sort_by_position = @sort
      stripper.should_separate_by_beads = !@ignore_beads
      stripper.start_page = @start_page
      stripper.end_page = @end_page
      stripper
    end

    private def create_output_writer : IO
      if @to_console
        NonClosingIO.new(@out)
      else
        mode = @append ? "a" : "w"
        outfile = @outfile || raise "Output path not configured"
        File.new(outfile, mode)
      end
    end

    private def validate_output_mode : Bool
      if @to_html && @to_md
        @err.puts("You can't set md and html at the same time")
        return false
      end
      true
    end

    private def configure_output_path(infile : String) : Nil
      ext = if @to_html
              ".html"
            elsif @to_md
              ".md"
            else
              ".txt"
            end
      @outfile ||= Path[infile].expand.to_s.sub(/\.[^.\/\\]+\z/, "") + ext
    end

    private def emit_encoding_warnings : Nil
      if @to_html && @encoding != STD_ENCODING
        @encoding = STD_ENCODING
        @out.puts("The encoding parameter is ignored when writing html output.")
      end

      if @to_console && @encoding
        @out.puts("The encoding parameter is ignored when writing to the console.")
      end
    end

    private def process_document(infile : String) : Int32
      document = Pdfbox::Loader.load_pdf(infile, @password)
      begin
        process_loaded_document(document, infile)
      ensure
        document.close
      end
      0
    end

    private def process_loaded_document(document : Pdfbox::Pdmodel::Document, infile : String) : Nil
      output = create_output_writer
      begin
        write_extracted_output(document, infile, output)
      ensure
        output.close unless @to_console
      end
    end

    private def write_extracted_output(document : Pdfbox::Pdmodel::Document, infile : String, output : IO) : Nil
      if @add_file_name
        output << "PDF file: #{infile}\n"
      end

      if @debug
        @err.puts("Writing to #{@outfile}")
      end

      stripper = build_stripper
      if @to_html
        stripper.write_text(document, output)
      else
        extract_pages(@start_page, Math.min(@end_page, document.number_of_pages), stripper, document, output)
      end

      extract_embedded_pdfs(document, stripper, output)
      output.flush
    end

    private def extract_pages(start_page : Int32, end_page : Int32, stripper : Pdfbox::Text::PDFTextStripper,
                              document : Pdfbox::Pdmodel::Document, output : IO) : Nil
      page = start_page
      while page <= end_page
        stripper.start_page = page
        stripper.end_page = page
        stripper.write_text(document, output)
        page += 1
      end
    end

    private def extract_embedded_pdfs(document : Pdfbox::Pdmodel::Document, stripper : Pdfbox::Text::PDFTextStripper, output : IO) : Nil
      catalog = document.document_catalog
      names = catalog.try(&.names)
      embedded_files = names.try(&.embedded_files)
      embedded_file_names = embedded_files.try(&.names)
      return unless embedded_file_names

      embedded_file_names.each do |name, spec|
        if @debug
          @err.puts("Processing embedded file #{name}:")
        end

        file = spec.embedded_file
        next unless file
        next unless file.subtype == "application/pdf"

        if @debug
          @err.puts("  is PDF (size=#{file.length})")
        end

        io = file.create_input_stream
        next unless io

        sub_document = Pdfbox::Pdmodel::Document.load(io)
        begin
          if @to_html
            stripper.write_text(sub_document, output)
          else
            extract_pages(1, sub_document.number_of_pages, stripper, sub_document, output)
          end
        ensure
          sub_document.close
        end
      end
    end

    private class NonClosingIO < IO
      def initialize(@io : IO)
      end

      def read(slice : Bytes) : Int32
        @io.read(slice)
      end

      def write(slice : Bytes) : Nil
        @io.write(slice)
      end

      def flush : Nil
        @io.flush
      end

      def close : Nil
      end
    end
  end
end
