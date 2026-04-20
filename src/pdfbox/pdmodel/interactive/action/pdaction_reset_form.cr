module Pdfbox::Pdmodel::Interactive::Action
  class PDActionResetForm < PDAction
    SUB_TYPE = "ResetForm"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def fields : Cos::Array?
      cos_object[Cos::Name.new("Fields")]?.as?(Cos::Array)
    end

    def fields=(fields : Cos::Array) : Cos::Array
      cos_object[Cos::Name.new("Fields")] = fields
      fields
    end

    def flags : Int32
      cos_object.get_int(Cos::Name.new("Flags"), 0_i64).to_i
    end

    def flags=(flags : Int32) : Int32
      cos_object.set_int("Flags", flags)
      flags
    end
  end
end
