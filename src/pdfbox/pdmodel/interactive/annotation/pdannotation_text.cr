module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationText < PDAnnotationMarkup
    include AppearanceHandlerSupport

    NAME_COMMENT       = "Comment"
    NAME_KEY           = "Key"
    NAME_NOTE          = "Note"
    NAME_HELP          = "Help"
    NAME_NEW_PARAGRAPH = "NewParagraph"
    NAME_PARAGRAPH     = "Paragraph"
    NAME_INSERT        = "Insert"
    NAME_CIRCLE        = "Circle"
    NAME_CROSS         = "Cross"
    NAME_STAR          = "Star"
    NAME_CHECK         = "Check"
    NAME_RIGHT_ARROW   = "RightArrow"
    NAME_RIGHT_POINTER = "RightPointer"
    NAME_UP_ARROW      = "UpArrow"
    NAME_UP_LEFT_ARROW = "UpLeftArrow"
    NAME_CROSS_HAIRS   = "CrossHairs"
    SUB_TYPE           = "Text"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def open? : Bool
      boolean_value(Cos::Name.new("Open"), false)
    end

    def open=(value : Bool) : Bool
      cos_object.set_boolean("Open", value)
      value
    end

    def name : String
      cos_object.get_name_as_string(Cos::Name::NAME) || NAME_NOTE
    end

    def name=(value : String) : String
      cos_object.set_name(Cos::Name::NAME, value)
      value
    end

    def state : String?
      cos_object.get_string(Cos::Name.new("State"))
    end

    def state=(value : String) : String
      cos_object.set_string(Cos::Name.new("State"), value)
      value
    end

    def state_model : String?
      cos_object.get_string(Cos::Name.new("StateModel"))
    end

    def state_model=(value : String) : String
      cos_object.set_string(Cos::Name.new("StateModel"), value)
      value
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDTextAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end
