module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  # A standard attribute object (Java PDStandardAttributeObject). Provides
  # typed getters/setters over the wrapped COS dictionary.
  abstract class PDStandardAttributeObject < LogicalStructure::PDAttributeObject
    # Java PDStandardAttributeObject.UNSPECIFIED.
    UNSPECIFIED = -1.0_f32

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

    # Returns a String or an Array(String) for a name-or-array-of-name attribute.
    protected def get_name_or_array_of_name(name : String, default_value : String) : String | Array(String)
      value = cos_object.get_dictionary_object(Cos::Name.new(name))
      case value
      when Cos::Array
        names = value.size.times.map do |i|
          item = value[i]
          item = item.object if item.is_a?(Cos::Object)
          item.is_a?(Cos::Name) ? item.value : ""
        end.to_a
        names
      when Cos::Name
        value.value
      else
        default_value
      end
    end

    protected def set_array_of_name(name : String, values : Array(String)) : Nil
      array = Cos::Array.new
      values.each { |value| array.add(Cos::Name.new(value)) }
      cos_object[Cos::Name.new(name)] = array
    end

    # Returns a Float, an Array(Float32), or nil for a number-or-array attribute.
    # When the attribute is absent and the default is UNSPECIFIED, nil is returned.
    protected def get_number_or_array_of_number(name : String, default_value : Float32) : Float32 | Array(Float32) | Nil
      value = cos_object.get_dictionary_object(Cos::Name.new(name))
      case value
      when Cos::Array
        numbers = value.size.times.map do |i|
          item = value[i]
          item = item.object if item.is_a?(Cos::Object)
          case item
          when Cos::Integer
            item.value.to_f32
          when Cos::Float
            item.value.to_f32
          else
            0.0_f32
          end
        end.to_a
        numbers
      when Cos::Integer
        value.value.to_f32
      when Cos::Float
        value.value.to_f32
      else
        default_value == UNSPECIFIED ? nil : default_value
      end
    end

    protected def set_array_of_number(name : String, values : Array(Float32)) : Nil
      array = Cos::Array.new
      values.each { |value| array.add(Cos::Float.new(value.to_f64)) }
      cos_object[Cos::Name.new(name)] = array
    end

    # Returns the colour (a PDGamma) for a three-value array attribute, or nil.
    protected def get_color(name : String) : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      array = cos_object.get_array(Cos::Name.new(name))
      array ? Pdfbox::Pdmodel::Graphics::Color::PDGamma.new(array) : nil
    end

    protected def set_color(name : String, value : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      key = Cos::Name.new(name)
      if value
        cos_object[key] = value.cos_object
      else
        cos_object.delete(key)
      end
    end

    # Returns a single colour (PDGamma, array size 3) or four colours
    # (PDFourColours, array size 4), or nil.
    protected def get_color_or_four_colors(name : String) : Pdfbox::Pdmodel::Graphics::Color::PDGamma | PDFourColours | Nil
      array = cos_object.get_array(Cos::Name.new(name))
      return unless array
      case array.size
      when 3
        Pdfbox::Pdmodel::Graphics::Color::PDGamma.new(array)
      when 4
        PDFourColours.new(array)
      end
    end

    protected def set_four_colors(name : String, value : PDFourColours?) : Nil
      key = Cos::Name.new(name)
      if value
        cos_object[key] = value.cos_object
      else
        cos_object.delete(key)
      end
    end
  end
end
