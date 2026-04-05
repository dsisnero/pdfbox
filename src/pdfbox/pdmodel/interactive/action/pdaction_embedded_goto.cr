module Pdfbox::Pdmodel::Interactive::Action
  class PDActionEmbeddedGoTo < PDAction
    SUB_TYPE = "GoToE"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def destination : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination?
      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(cos_object[Cos::Name.new("D")]?)
    end

    def destination=(destination : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination
      if page_destination = destination.as?(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
        page = page_destination.cos_object[0]?
        if page && !page.is_a?(Cos::Integer) && !page.is_a?(Cos::Null)
          raise ArgumentError.new("Destination of a GoToE action must be an integer")
        end
      end
      cos_object[Cos::Name.new("D")] = destination.cos_object
      destination
    end

    def file : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification?
      Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification.create_fs(cos_object[Cos::Name.new("F")]?)
    end

    def file=(fs : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification) : Pdfbox::Pdmodel::Common::Filespecification::PDFileSpecification
      cos_object[Cos::Name.new("F")] = fs.cos_object
      fs
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

    def target_directory : PDTargetDirectory?
      cos_object["T"]?.as?(Cos::Dictionary).try { |dict| PDTargetDirectory.new(dict) }
    end

    def target_directory=(target_directory : PDTargetDirectory) : PDTargetDirectory
      cos_object[Cos::Name.new("T")] = target_directory.cos_object
      target_directory
    end
  end
end
