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
      return nil unless value.is_a?(Cos::String)

      bytes = value.bytes
      if bytes.size >= 2
        # UTF-16 (BE or LE) - let Cos::String#value decode the BOM
        if (bytes[0] == 0xFE_u8 && bytes[1] == 0xFF_u8) ||
           (bytes[0] == 0xFF_u8 && bytes[1] == 0xFE_u8)
          return value.value
        end
      end
      # Java PDActionURI#getURI: non-UTF-16 bytes are decoded as UTF-8
      ::String.new(bytes, "UTF-8")
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
