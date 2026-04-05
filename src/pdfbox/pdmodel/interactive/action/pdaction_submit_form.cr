module Pdfbox::Pdmodel::Interactive::Action
  class PDActionSubmitForm < PDAction
    SUB_TYPE = "SubmitForm"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def file : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification?
      Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(cos_object[Cos::Name.new("F")]?)
    end

    def file=(fs : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification) : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification
      cos_object[Cos::Name.new("F")] = fs.cos_object
      fs
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
