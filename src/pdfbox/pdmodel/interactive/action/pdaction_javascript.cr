module Pdfbox::Pdmodel::Interactive::Action
  class PDActionJavaScript < PDAction
    SUB_TYPE = "JavaScript"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def action : String?
      value = cos_object[Cos::Name.new("JS")]?
      case value
      when Cos::String
        value.value
      when Cos::Stream
        value.create_input_stream.gets_to_end
      else
        nil
      end
    end

    def action=(script : String) : String
      cos_object[Cos::Name.new("JS")] = Cos::String.new(script)
      script
    end
  end
end
