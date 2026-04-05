require "../pdfbox"
require "option_parser"

module Tools
  class PrintPDF
    enum Duplex
      Document
      Simplex
      Duplex
      Tumble

      def self.parse(value : String) : self
        case value.downcase
        when "document" then Document
        when "simplex"  then Simplex
        when "duplex"   then Duplex
        when "tumble"   then Tumble
        else
          raise ArgumentError.new("Unknown duplex mode: #{value}")
        end
      end
    end

    abstract class Backend
      record Submission, printer : String?, duplex : String?, tray : String?, media_size : String?, silent : Bool

      abstract def available_printers : Array(String)
      abstract def default_printer_name : String?
      abstract def available_trays(printer : String?) : Array(String)
      abstract def available_media_sizes(printer : String?) : Array(String)
      abstract def submit(infile : String, submission : Submission, stdout_io : IO, stderr_io : IO) : Int32
      abstract def unimplemented_options : Array(String)
    end

    class CupsBackend < Backend
      def available_printers : Array(String)
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("lpstat", ["-p"], output: output, error: error)
        return [] of String unless status.success?

        output.to_s.lines.compact_map do |line|
          if match = line.match(/^printer\s+(\S+)/)
            match[1]
          end
        end
      end

      def default_printer_name : String?
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("lpstat", ["-d"], output: output, error: error)
        return nil unless status.success?

        if match = output.to_s.match(/system default destination:\s+(.+)\s*$/)
          match[1].strip
        end
      end

      def available_trays(printer : String?) : Array(String)
        parse_lpoptions_values(printer, "InputSlot")
      end

      def available_media_sizes(printer : String?) : Array(String)
        parse_lpoptions_values(printer, "PageSize", "media")
      end

      def submit(infile : String, submission : Submission, stdout_io : IO, stderr_io : IO) : Int32
        args = [] of String
        if printer = submission.printer
          args << "-d"
          args << printer
        end
        if duplex = submission.duplex
          args << "-o"
          args << duplex
        end
        if tray = submission.tray
          args << "-o"
          args << "InputSlot=#{tray}"
        end
        if media_size = submission.media_size
          args << "-o"
          args << "media=#{media_size}"
        end
        args << infile
        Process.run("lp", args, output: stdout_io, error: stderr_io).exit_code
      end

      def unimplemented_options : Array(String)
        ["orientation", "border", "dpi", "noCenter", "noColorOpt", "silentPrint"] of String
      end

      private def parse_lpoptions_values(printer : String?, *keys : String) : Array(String)
        args = [] of String
        if printer
          args += ["-p", printer]
        elsif default = default_printer_name
          args += ["-p", default]
        end
        args << "-l"

        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("lpoptions", args, output: output, error: error)
        return [] of String unless status.success?

        output.to_s.each_line do |line|
          keys.each do |key|
            next unless line.starts_with?("#{key}/")
            _, raw_values = line.split(':', 2)
            next unless raw_values
            return raw_values.split.map(&.lchop('*'))
          end
        end

        [] of String
      end
    end

    class WindowsBackend < Backend
      def available_printers : Array(String)
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("powershell", powershell_args("(Get-Printer | Select-Object -ExpandProperty Name) -join \"`n\""), output: output, error: error)
        return [] of String unless status.success?
        output.to_s.lines.map(&.strip).reject(&.empty?)
      rescue File::Error
        [] of String
      end

      def default_printer_name : String?
        output = IO::Memory.new
        error = IO::Memory.new
        status = Process.run("powershell", powershell_args("(Get-CimInstance Win32_Printer | Where-Object Default -eq $true | Select-Object -First 1 -ExpandProperty Name)"), output: output, error: error)
        return nil unless status.success?
        value = output.to_s.strip
        value.empty? ? nil : value
      rescue File::Error
        nil
      end

      def available_trays(printer : String?) : Array(String)
        _ = printer
        [] of String
      end

      def available_media_sizes(printer : String?) : Array(String)
        _ = printer
        [] of String
      end

      def submit(infile : String, submission : Submission, stdout_io : IO, stderr_io : IO) : Int32
        _ = stdout_io
        if printer = submission.printer
          escaped_file = powershell_single_quote(infile)
          escaped_printer = powershell_single_quote(printer)
          command = "Start-Process -FilePath #{escaped_file} -Verb PrintTo -ArgumentList #{escaped_printer} -Wait"
        else
          escaped_file = powershell_single_quote(infile)
          command = "Start-Process -FilePath #{escaped_file} -Verb Print -Wait"
        end

        status = Process.run("powershell", powershell_args(command), output: Process::Redirect::Close, error: stderr_io)
        status.exit_code
      rescue ex : File::Error
        stderr_io.puts(ex.message)
        1
      end

      def unimplemented_options : Array(String)
        ["orientation", "duplex", "tray", "mediaSize", "border", "dpi", "noCenter", "noColorOpt", "silentPrint"] of String
      end

      private def powershell_args(command : String) : Array(String)
        ["-NoProfile", "-NonInteractive", "-Command", command]
      end

      private def powershell_single_quote(value : String) : String
        "'" + value.gsub("'", "''") + "'"
      end
    end

    class UnsupportedBackend < Backend
      def available_printers : Array(String)
        [] of String
      end

      def default_printer_name : String?
        nil
      end

      def available_trays(printer : String?) : Array(String)
        _ = printer
        [] of String
      end

      def available_media_sizes(printer : String?) : Array(String)
        _ = printer
        [] of String
      end

      def submit(infile : String, submission : Submission, stdout_io : IO, stderr_io : IO) : Int32
        _ = infile
        _ = submission
        _ = stdout_io
        stderr_io.puts("Printing is not supported on this platform in the Crystal port.")
        1
      end

      def unimplemented_options : Array(String)
        ["orientation", "duplex", "tray", "mediaSize", "border", "dpi", "noCenter", "noColorOpt", "silentPrint"] of String
      end
    end

    @infile : String? = nil
    @password = ""
    @silent_print = false
    @printer_name : String? = nil
    @orientation = Pdfbox::Printing::Orientation::AUTO
    @duplex = Duplex::Document
    @tray : String? = nil
    @media_size : String? = nil
    @border = false
    @dpi = 0
    @no_center = false
    @no_color_opt = false

    def initialize(@out : IO = STDOUT, @err : IO = STDERR, @backend : Backend = self.class.default_backend)
    end

    def self.default_backend : Backend
      {% if flag?(:win32) %}
        WindowsBackend.new
      {% elsif flag?(:darwin) || flag?(:linux) %}
        CupsBackend.new
      {% else %}
        UnsupportedBackend.new
      {% end %}
    end

    def call(args : Array(String)) : Int32
      reset
      build_option_parser.parse(normalize_args(args))

      unless @infile
        @err.puts("Missing required option: -i")
        return 1
      end

      infile = @infile || raise ::IO::Error.new("Missing required option: -i")
      document = load_printable_document(infile, @password)
      begin
        unless document.current_access_permission.can_print?
          raise ::IO::Error.new("You do not have permission to print")
        end

        printer = resolve_printer_name
        validate_requested_option("Tray", @tray, @backend.available_trays(printer))
        validate_requested_option("media size", @media_size, @backend.available_media_sizes(printer))
        warn_for_unimplemented_options

        submission = Backend::Submission.new(
          printer: printer,
          duplex: duplex_option(document),
          tray: validated_value(@tray, @backend.available_trays(printer)),
          media_size: validated_value(@media_size, @backend.available_media_sizes(printer)),
          silent: @silent_print
        )

        exit_code = @backend.submit(infile, submission, @out, @err)
        unless exit_code == 0
          raise ::IO::Error.new("print backend exited with status #{exit_code}")
        end
      ensure
        document.close
      end
      0
    rescue ex : ArgumentError
      @err.puts("Error: #{ex.message}")
      1
    rescue ex : IO::Error
      @err.puts("Error printing document [#{ex.class.name.split("::").last}]: #{ex.message}")
      4
    end

    private def reset : Nil
      @infile = nil
      @password = ""
      @silent_print = false
      @printer_name = nil
      @orientation = Pdfbox::Printing::Orientation::AUTO
      @duplex = Duplex::Document
      @tray = nil
      @media_size = nil
      @border = false
      @dpi = 0
      @no_center = false
      @no_color_opt = false
    end

    private def build_option_parser : OptionParser
      OptionParser.new do |parser|
        parser.on("-i FILE", "--input FILE", "The PDF file to print") { |value| @infile = value }
        parser.on("--password PASSWORD", "The password to decrypt the document") { |value| @password = value }
        parser.on("--silentPrint", "Print without printer dialog box") { @silent_print = true }
        parser.on("--printerName NAME", "Print to specific printer") { |value| @printer_name = value }
        parser.on("--orientation VALUE", "Print using orientation") { |value| @orientation = Pdfbox::Printing::Orientation.parse(value) }
        parser.on("--duplex VALUE", "Print using duplex") { |value| @duplex = Duplex.parse(value) }
        parser.on("--tray VALUE", "Print using tray") { |value| @tray = value }
        parser.on("--mediaSize VALUE", "Print using media size name") { |value| @media_size = value }
        parser.on("--border", "Print with border") { @border = true }
        parser.on("--dpi VALUE", "Render into intermediate image with specific dpi and then print") { |value| @dpi = value.to_i }
        parser.on("--noCenter", "Align top-left instead of centering") { @no_center = true }
        parser.on("--noColorOpt", "Disable color optimizations") { @no_color_opt = true }
      end
    end

    private def normalize_args(args : Array(String)) : Array(String)
      args.map do |arg|
        if arg.starts_with?('-') && !arg.starts_with?("--") && arg.size > 2 && !{"-i"}.includes?(arg)
          "--#{arg.byte_slice(1)}"
        else
          arg
        end
      end
    end

    protected def load_printable_document(infile : String, password : String) : Pdfbox::Pdmodel::Document
      Pdfbox::Loader.load_pdf(infile, password)
    end

    private def resolve_printer_name : String?
      requested = @printer_name
      return nil unless requested

      printers = @backend.available_printers
      return requested if printers.any? { |printer| printer.compare(requested, case_insensitive: true) == 0 }

      if default = @backend.default_printer_name
        @err.puts("printer '#{requested}' not found, using default '#{default}'")
      else
        @err.puts("printer '#{requested}' not found, using system default printer")
      end
      show_available_printers(printers)
      nil
    end

    private def show_available_printers(printers : Array(String)) : Nil
      @err.puts("Available printer names:")
      printers.each { |printer| @err.puts(printer) }
    end

    private def validate_requested_option(label : String, requested : String?, supported : Array(String)) : Nil
      return unless requested
      return if supported.empty?
      return if supported.includes?(requested)

      @err.puts("#{label} '#{requested}' not supported, ignored. Valid values: #{supported}")
    end

    private def validated_value(requested : String?, supported : Array(String)) : String?
      return requested if requested && supported.empty?
      return requested if requested && supported.includes?(requested)
      nil
    end

    private def warn_for_unimplemented_options : Nil
      # Keep this table-driven so Java-compatible option growth doesn't explode cyclomatic complexity.
      ignored = [] of String
      unsupported = @backend.unimplemented_options.to_set
      ignored.concat(unimplemented_option_warnings(unsupported))
      return if ignored.empty?

      @err.puts("Warning: partial print parity, currently ignoring #{ignored.join(", ")}")
    end

    private def unimplemented_option_warnings(unsupported : Set(String)) : Array(String) # ameba:disable Metrics/CyclomaticComplexity
      warnings = [] of String
      warnings << "orientation=#{@orientation.to_s.downcase}" if unsupported.includes?("orientation") && @orientation != Pdfbox::Printing::Orientation::AUTO
      warnings << "duplex=#{@duplex.to_s.downcase}" if unsupported.includes?("duplex") && @duplex != Duplex::Document
      warnings << "tray=#{@tray}" if unsupported.includes?("tray") && @tray
      warnings << "mediaSize=#{@media_size}" if unsupported.includes?("mediaSize") && @media_size
      warnings << "border" if unsupported.includes?("border") && @border
      warnings << "dpi=#{@dpi}" if unsupported.includes?("dpi") && @dpi != 0
      warnings << "noCenter" if unsupported.includes?("noCenter") && @no_center
      warnings << "noColorOpt" if unsupported.includes?("noColorOpt") && @no_color_opt
      warnings << "silentPrint" if unsupported.includes?("silentPrint") && @silent_print
      warnings
    end

    private def duplex_option(document : Pdfbox::Pdmodel::Document) : String?
      case @duplex
      when Duplex::Simplex
        "sides=one-sided"
      when Duplex::Duplex
        "sides=two-sided-long-edge"
      when Duplex::Tumble
        "sides=two-sided-short-edge"
      when Duplex::Document
        duplex_option_from_document(document)
      end
    end

    private def duplex_option_from_document(document : Pdfbox::Pdmodel::Document) : String?
      catalog = document.document_catalog
      return nil unless catalog

      case catalog.viewer_preferences.try(&.duplex)
      when Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::DuplexFlipLongEdge
        "sides=two-sided-long-edge"
      when Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::DuplexFlipShortEdge
        "sides=two-sided-short-edge"
      when Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::Simplex
        "sides=one-sided"
      else
        nil
      end
    end
  end
end
