module Pdfbox::Pdmodel::Interactive::Action
  class PDActionMovie < PDAction
    SUB_TYPE = "Movie"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end
  end
end
