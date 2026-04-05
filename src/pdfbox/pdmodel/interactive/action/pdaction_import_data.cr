module Pdfbox::Pdmodel::Interactive::Action
  class PDActionImportData < PDAction
    SUB_TYPE = "ImportData"

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
  end
end
