# Base class for PDF annotations
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotation
    FLAG_INVISIBLE       = 1 << 0
    FLAG_HIDDEN          = 1 << 1
    FLAG_PRINTED         = 1 << 2
    FLAG_NO_ZOOM         = 1 << 3
    FLAG_NO_ROTATE       = 1 << 4
    FLAG_NO_VIEW         = 1 << 5
    FLAG_READ_ONLY       = 1 << 6
    FLAG_LOCKED          = 1 << 7
    FLAG_TOGGLE_NO_VIEW  = 1 << 8
    FLAG_LOCKED_CONTENTS = 1 << 9

    @dictionary : Cos::Dictionary

    def initialize(@dictionary : Cos::Dictionary = Cos::Dictionary.new)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Get the annotation subtype from dictionary
    def subtype : String
      subtype_value = @dictionary[Cos::Name.new("Subtype")]
      case subtype_value
      when Cos::Name
        subtype_value.value
      else
        ""
      end
    end

    # Get the annotation rectangle
    def rectangle : Common::PDRectangle?
      rect_obj = @dictionary[Cos::Name.new("Rect")]
      if rect_obj.is_a?(Cos::Array)
        Common::PDRectangle.new(rect_obj)
      end
    end

    # Set the annotation rectangle
    def rectangle=(rect : Common::PDRectangle)
      @dictionary[Cos::Name.new("Rect")] = rect.cos_object
    end

    # Get the annotation flags
    def flags : Int32
      value = @dictionary[Cos::Name.new("F")]
      case value
      when Cos::Integer
        value.value.to_i32
      else
        0
      end
    end

    # Set the annotation flags
    def flags=(value : Int32)
      @dictionary[Cos::Name.new("F")] = Cos::Integer.new(value.to_i64)
    end

    # Check if invisible flag is set
    def invisible? : Bool
      (flags & FLAG_INVISIBLE) != 0
    end

    # Check if hidden flag is set
    def hidden? : Bool
      (flags & FLAG_HIDDEN) != 0
    end

    # Check if printed flag is set
    def printed? : Bool
      (flags & FLAG_PRINTED) != 0
    end

    # Check if read-only flag is set
    def read_only? : Bool
      (flags & FLAG_READ_ONLY) != 0
    end
  end
end
