module Pdfbox::Pdmodel::Interactive::Measurement
  class PDRectlinearMeasureDictionary < PDMeasureDictionary
    SUBTYPE = "RL"

    def initialize
      super()
      self.subtype = SUBTYPE
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def scale_ratio : String?
      cos_object.get_string(Cos::Name.new("R"))
    end

    def scale_ratio=(value : String) : String
      cos_object.set_string("R", value)
      value
    end

    def change_xs : Array(PDNumberFormatDictionary)?
      number_format_array("X")
    end

    def change_xs=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("X", values)
    end

    def change_ys : Array(PDNumberFormatDictionary)?
      number_format_array("Y")
    end

    def change_ys=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("Y", values)
    end

    def distances : Array(PDNumberFormatDictionary)?
      number_format_array("D")
    end

    def distances=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("D", values)
    end

    def areas : Array(PDNumberFormatDictionary)?
      number_format_array("A")
    end

    def areas=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("A", values)
    end

    def angles : Array(PDNumberFormatDictionary)?
      number_format_array("T")
    end

    def angles=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("T", values)
    end

    def line_sloaps : Array(PDNumberFormatDictionary)?
      number_format_array("S")
    end

    def line_sloaps=(values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      set_number_format_array("S", values)
    end

    def coord_system_origin : Array(Float64)?
      cos_object.get_array(Cos::Name.new("O")).try(&.to_float_array)
    end

    def coord_system_origin=(values : Enumerable(Number)) : Array(Float64)
      float_values = values.map(&.to_f64).to_a
      array = Cos::Array.new
      array.float_array = float_values
      cos_object[Cos::Name.new("O")] = array
      float_values
    end

    def cyx : Float64
      cos_object.get_float(Cos::Name.new("CYX"))
    end

    def cyx=(value : Number) : Float64
      float_value = value.to_f64
      cos_object.set_float("CYX", float_value)
      float_value
    end

    private def number_format_array(key : String) : Array(PDNumberFormatDictionary)?
      cos_object.get_array(Cos::Name.new(key)).try do |array|
        array.items.compact_map do |item|
          item.as?(Cos::Dictionary).try { |dictionary| PDNumberFormatDictionary.new(dictionary) }
        end
      end
    end

    private def set_number_format_array(key : String, values : Enumerable(PDNumberFormatDictionary)) : Array(PDNumberFormatDictionary)
      dictionaries = values.to_a
      array = Cos::Array.new
      dictionaries.each do |dictionary|
        array.add(dictionary.cos_object)
      end
      cos_object[Cos::Name.new(key)] = array
      dictionaries
    end
  end
end
