module Pdfbox::Pdmodel::Interactive::Action
  class PDActionThread < PDAction
    SUB_TYPE = "Thread"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def d : Cos::Base?
      cos_object[Cos::Name.new("D")]?
    end

    def d=(destination : Cos::Base) : Cos::Base
      cos_object[Cos::Name.new("D")] = destination
      destination
    end

    def file : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification?
      Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(cos_object[Cos::Name.new("F")]?)
    end

    def file=(fs : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification) : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification
      cos_object[Cos::Name.new("F")] = fs.cos_object
      fs
    end

    def b : Cos::Base?
      cos_object[Cos::Name.new("B")]?
    end

    def b=(bead_or_thread : Cos::Base) : Cos::Base
      cos_object[Cos::Name.new("B")] = bead_or_thread
      bead_or_thread
    end
  end
end
