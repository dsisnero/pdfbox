# Base class for fields which use "Variable Text".
# These fields construct an appearance stream dynamically at viewing time.
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDVariableText < PDTerminalField
    QUADDING_LEFT     = 0
    QUADDING_CENTERED = 1
    QUADDING_RIGHT    = 2

    # Get the default appearance. This is an inheritable attribute.
    def default_appearance : String?
      base = get_inheritable_attribute(Cos::Name.new("DA"))
      base.as?(Cos::String).try(&.value)
    end

    # Get the default appearance as a parsed PDDefaultAppearanceString.
    def default_appearance_string : PDDefaultAppearanceString
      base = get_inheritable_attribute(Cos::Name.new("DA"))
      da = base.as?(Cos::String)
      dr = acro_form.default_resources
      PDDefaultAppearanceString.new(da, dr)
    end

    # Set the default appearance. This sets the local DA entry only.
    def default_appearance=(da_value : String) : String
      @dictionary.set_string(Cos::Name.new("DA"), da_value)

      # PDFBOX-5797: Sejda files have a /DA entry in kid widgets
      if @dictionary.has_key?(Cos::Name.new("Kids"))
        widgets.each do |widget|
          widget_dict = widget.cos_object
          if widget_dict.has_key?(Cos::Name.new("DA"))
            widget_dict.set_string(Cos::Name.new("DA"), da_value)
          end
        end
      end
      da_value
    end

    # Get the default style string (DS entry).
    def default_style_string : String?
      @dictionary.get_string(Cos::Name.new("DS"))
    end

    # Set the default style string.
    def default_style_string=(default_style_string : String?) : String?
      if value = default_style_string
        @dictionary[Cos::Name.new("DS")] = Cos::String.new(value)
      else
        @dictionary.delete(Cos::Name.new("DS"))
      end
      default_style_string
    end

    # Get the quadding / justification of the text (inheritable).
    def q : Int32
      number = get_inheritable_attribute(Cos::Name.new("Q"))
      case number
      when Cos::Integer
        number.value.to_i32
      when Cos::Float
        number.value.to_i32
      else
        0
      end
    end

    # Set the quadding / justification.
    def q=(value : Int) : Int32
      int_value = value.to_i32
      @dictionary.set_int(Cos::Name.new("Q"), int_value)
      int_value
    end

    # Get the field's rich text value (RV entry).
    def rich_text_value : String
      get_string_or_stream(get_inheritable_attribute(Cos::Name.new("RV")))
    end

    # Set the field's rich text value.
    def rich_text_value=(rich_text_value : String?) : String?
      if value = rich_text_value
        @dictionary[Cos::Name.new("RV")] = Cos::String.new(value)
      else
        @dictionary.delete(Cos::Name.new("RV"))
      end
      rich_text_value
    end

    # Get a text as text stream. Some dictionary entries allow either a text
    # or a text stream.
    private def get_string_or_stream(base : Cos::Base?) : String
      case base
      when Cos::String
        base.value
      when Cos::Stream
        base.to_text_string
      else
        ""
      end
    end
  end
end
