module Pdfbox::Pdmodel::Interactive::Action
  class PDActionNamed < PDAction
    SUB_TYPE = "Named"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def n : String?
      cos_object.get_name_as_string(Cos::Name.new("N"))
    end

    def n=(name : String) : String
      cos_object.set_name("N", name)
      name
    end
  end
end
