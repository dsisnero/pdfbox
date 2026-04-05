module Pdfbox::Pdmodel::Interactive::Action
  class PDActionRemoteGoTo < PDAction
    SUB_TYPE = "GoToR"

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

    def d : Cos::Base?
      cos_object[Cos::Name.new("D")]?
    end

    def d=(destination : Cos::Base) : Cos::Base
      cos_object[Cos::Name.new("D")] = destination
      destination
    end

    def open_in_new_window : OpenMode
      value = cos_object[Cos::Name.new("NewWindow")]?
      if bool = value.as?(Cos::Boolean)
        bool.value ? OpenMode::NewWindow : OpenMode::SameWindow
      else
        OpenMode::UserPreference
      end
    end

    def open_in_new_window=(value : OpenMode) : OpenMode
      case value
      when .user_preference?
        cos_object.delete(Cos::Name.new("NewWindow"))
      when .same_window?
        cos_object.set_boolean("NewWindow", false)
      when .new_window?
        cos_object.set_boolean("NewWindow", true)
      end
      value
    end
  end
end
