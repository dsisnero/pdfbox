module Tools
  class PDFBox
    HEADLESS_ERROR = "Unmatched argument at index 0: 'debug'"

    getter? headless : Bool

    def initialize(@out : IO = STDOUT, @err : IO = STDERR, @headless : Bool = self.class.headless?)
    end

    def self.headless? : Bool
      value = ENV["JAVA_AWT_HEADLESS"]?
      value && value.downcase == "true"
    end

    def available_subcommands : Array(String)
      commands = [] of String
      commands << "debug" unless @headless
      commands.concat(%w(
        decrypt
        encrypt
        decode
        export:images
        export:xmp
        export:text
        export:fdf
        export:xfdf
        import:fdf
        import:xfdf
        overlay
        print
        render
        merge
        split
        fromimage
        fromtext
        version
        help
      ))
      commands
    end

    def execute(args : Array(String)) : Int32
      return subcommand_required if args.empty?

      command = args.first
      case command
      when "version"
        Version.new(@out).call("version")
      when "debug"
        handle_debug
      else
        @err.puts("Command '#{command}' not yet implemented")
        0
      end
    end

    def self.main(args : Array(String), stdout_io : IO = STDOUT, stderr_io : IO = STDERR, headless : Bool = headless?) : Int32
      PDFBox.new(stdout_io, stderr_io, headless).execute(args)
    end

    private def subcommand_required : Int32
      @err.puts("Error: Subcommand required")
      2
    end

    private def handle_debug : Int32
      if @headless
        @err.puts(HEADLESS_ERROR)
      else
        @out.puts("debug")
      end
      0
    end
  end
end
