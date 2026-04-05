module Pdfbox::Pdmodel::Interactive::Action
  class PDWindowsLaunchParams
    OPERATION_OPEN  = "open"
    OPERATION_PRINT = "print"

    @params : Cos::Dictionary

    def initialize
      @params = Cos::Dictionary.new
    end

    def initialize(@params : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @params
    end

    def filename : String?
      @params.get_string(Cos::Name.new("F"))
    end

    def filename=(file : String) : String
      @params.set_string("F", file)
      file
    end

    def directory : String?
      @params.get_string(Cos::Name.new("D"))
    end

    def directory=(dir : String) : String
      @params.set_string("D", dir)
      dir
    end

    def operation : String
      @params.get_string(Cos::Name.new("O"), OPERATION_OPEN).to_s
    end

    def operation=(op : String) : String
      @params.set_string("O", op)
      op
    end

    def execute_param : String?
      @params.get_string(Cos::Name.new("P"))
    end

    def execute_param=(param : String) : String
      @params.set_string("P", param)
      param
    end
  end
end
