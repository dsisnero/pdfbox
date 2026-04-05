module Pdfbox::Pdmodel::Interactive::Action
  class PDActionHide < PDAction
    SUB_TYPE = "Hide"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def t : Cos::Base?
      cos_object[Cos::Name.new("T")]?
    end

    def t=(target : Cos::Base) : Cos::Base
      cos_object[Cos::Name.new("T")] = target
      target
    end

    def h : Bool
      hidden = cos_object[Cos::Name.new("H")]?.as?(Cos::Boolean)
      hidden ? hidden.value : true
    end

    def h=(hidden : Bool) : Bool
      cos_object[Cos::Name.new("H")] = Cos::Boolean.get(hidden)
      hidden
    end
  end
end
