module Pdfbox::Pdmodel::Interactive::Action
  class PDActionURI < PDAction
    SUB_TYPE = "URI"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def uri : String?
      value = cos_object[Cos::Name.new("URI")]?
      case value
      when Cos::String
        value.value
      else
        nil
      end
    end

    def uri=(value : String) : String
      cos_object.set_string("URI", value)
      value
    end

    def track_mouse_position? : Bool
      bool = cos_object[Cos::Name.new("IsMap")]?
      bool.is_a?(Cos::Boolean) ? bool.value : false
    end

    def track_mouse_position=(value : Bool) : Bool
      cos_object.set_boolean("IsMap", value)
      value
    end
  end
end
