module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  # A standard attribute object (Java PDStandardAttributeObject). Provides
  # typed getters/setters over the wrapped COS dictionary.
  abstract class PDStandardAttributeObject < LogicalStructure::PDAttributeObject
    protected def initialize
      super
    end

    protected def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def specified?(name : String) : Bool
      cos_object.get_dictionary_object(Cos::Name.new(name)) != nil
    end

    protected def get_string(name : String) : String?
      cos_object.get_string(Cos::Name.new(name))
    end

    protected def set_string(name : String, value : String) : Nil
      cos_object.set_string(Cos::Name.new(name), value)
    end

    protected def get_name(name : String) : String?
      cos_object.get_name_as_string(Cos::Name.new(name))
    end

    protected def get_name(name : String, default_value : String) : String
      cos_object.get_name_as_string(Cos::Name.new(name)) || default_value
    end

    protected def set_name(name : String, value : String) : Nil
      cos_object.set_name(Cos::Name.new(name), value)
    end

    protected def get_integer(name : String, default_value : Int32) : Int32
      cos_object.get_int(Cos::Name.new(name), default_value.to_i64).to_i32
    end

    protected def set_integer(name : String, value : Int32) : Nil
      cos_object.set_int(Cos::Name.new(name), value)
    end

    protected def get_number(name : String, default_value : Float64) : Float32
      cos_object.get_float(Cos::Name.new(name), default_value).to_f32
    end

    protected def get_number(name : String) : Float32
      cos_object.get_float(Cos::Name.new(name)).to_f32
    end

    protected def set_number(name : String, value : Number) : Nil
      cos_object.set_float(Cos::Name.new(name), value.to_f64)
    end

    # Returns a Float or a String for a number-or-name attribute.
    protected def get_number_or_name(name : String, default_value : String) : Float32 | String
      value = cos_object.get_dictionary_object(Cos::Name.new(name))
      case value
      when Cos::Integer
        value.value.to_f32
      when Cos::Float
        value.value.to_f32
      when Cos::Name
        value.value
      else
        default_value
      end
    end
  end
end
