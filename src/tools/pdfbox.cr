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
      exit_code = 0
      command_groups(args).each do |group|
        command = group.first
        command_args = group[1..]
        exit_code = case command
                    when "version"
                      Version.new(@out).call("version")
                    when "debug"
                      handle_debug
                    when "export:text"
                      ExtractText.new(@out, @err).call(command_args)
                    else
                      @err.puts("Command '#{command}' not yet implemented")
                      0
                    end
      end
      exit_code
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

    private def command_groups(args : Array(String)) : Array(Array(String))
      groups = [] of Array(String)
      current = [] of String
      args.each_with_index do |arg, index|
        if index > 0 && available_subcommands.includes?(arg)
          groups << current unless current.empty?
          current = [arg]
        else
          current << arg
        end
      end
      groups << current unless current.empty?
      groups
    end
  end
end
