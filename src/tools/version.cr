module Tools
  class Version
    @out : IO

    def initialize(@out : IO = STDOUT)
    end

    def get_version(command_name : String = "version") : Array(String)
      version = Pdfbox::VERSION
      if version
        ["#{command_name} [#{version}]"]
      else
        ["unknown"]
      end
    end

    def call(command_name : String = "version") : Int32
      @out.puts(get_version(command_name)[0])
      0
    end
  end
end
