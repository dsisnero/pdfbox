# A link annotation
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationLink < PDAnnotation
    include AppearanceHandlerSupport

    HIGHLIGHT_MODE_NONE    = "N"
    HIGHLIGHT_MODE_INVERT  = "I"
    HIGHLIGHT_MODE_OUTLINE = "O"
    HIGHLIGHT_MODE_PUSH    = "P"
    SUB_TYPE               = "Link"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def action : Action::PDAction?
      Action::PDActionFactory.create_action(cos_object.get_dictionary(Cos::Name.new("A")))
    end

    def action=(value : Action::PDAction) : Action::PDAction
      cos_object[Cos::Name.new("A")] = value.cos_object
      value
    end

    def border_style : PDBorderStyleDictionary?
      cos_object.get_dictionary(Cos::Name.new("BS")).try { |entry| PDBorderStyleDictionary.new(entry) }
    end

    def border_style=(value : PDBorderStyleDictionary) : PDBorderStyleDictionary
      cos_object[Cos::Name.new("BS")] = value.cos_object
      value
    end

    def destination : DocumentNavigation::Destination::PDDestination?
      DocumentNavigation::Destination::PDDestination.create(cos_object[Cos::Name.new("Dest")]?)
    end

    def destination=(value : DocumentNavigation::Destination::PDDestination) : DocumentNavigation::Destination::PDDestination
      cos_object[Cos::Name.new("Dest")] = value.cos_object.as(Cos::Base)
      value
    end

    def highlight_mode : String
      cos_object.get_name_as_string(Cos::Name.new("H")) || HIGHLIGHT_MODE_INVERT
    end

    def highlight_mode=(value : String?) : String?
      if value.nil?
        cos_object.delete(Cos::Name.new("H"))
        return
      end

      unless {HIGHLIGHT_MODE_NONE, HIGHLIGHT_MODE_INVERT, HIGHLIGHT_MODE_OUTLINE, HIGHLIGHT_MODE_PUSH}.includes?(value)
        raise ArgumentError.new("Valid values for highlighting mode are 'N', 'I', 'O', 'P' or 'T'")
      end
      cos_object.set_name(Cos::Name.new("H"), value)
      value
    end

    def previous_uri : Action::PDActionURI?
      cos_object.get_dictionary(Cos::Name.new("PA")).try { |entry| Action::PDActionURI.new(entry) }
    end

    def previous_uri=(value : Action::PDActionURI) : Action::PDActionURI
      cos_object[Cos::Name.new("PA")] = value.cos_object
      value
    end

    def quad_points : Array(Float64)?
      cos_object.get_array(Cos::Name.new("QuadPoints")).try(&.to_float_array)
    end

    def quad_points=(values : Enumerable(Number)) : Array(Float64)
      float_values = values.map(&.to_f64).to_a
      cos_object[Cos::Name.new("QuadPoints")] = cos_array_of_numbers(float_values)
      float_values
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDLinkAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end
