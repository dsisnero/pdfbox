require "./pd_cie_dictionary_based_color_space"
require "./pd_gamma"

module Pdfbox::Pdmodel::Graphics::Color
  # A CalRGB colour space. Corresponds to PDCalRGB in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDCalRGB.java
  class PDCalRGB < PDCIEDictionaryBasedColorSpace
    def initialize
      super(Cos::Name.new("CalRGB"))
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def name : String
      "CalRGB"
    end

    def number_of_components : Int32
      3
    end

    def default_decode(bits_per_component : Int32) : Array(Float32)
      [0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 1.0_f32]
    end

    # Java toRGB: with a default whitepoint, gamma-correct each component, apply
    # the linear-interpretation matrix, then XYZ-correct; otherwise skip CIE
    # calibration (return the components as-is, PDFBOX-2553).
    def to_rgb(components : Array(Float32)) : Array(Float32)
      unless white_point?
        return [components[0], components[1], components[2]]
      end

      g = gamma
      pow_a_r = components[0].to_f64 ** g.r.to_f64
      pow_b_g = components[1].to_f64 ** g.g.to_f64
      pow_c_b = components[2].to_f64 ** g.b.to_f64

      m = matrix
      x = m[0] * pow_a_r + m[3] * pow_b_g + m[6] * pow_c_b
      y = m[1] * pow_a_r + m[4] * pow_b_g + m[7] * pow_c_b
      z = m[2] * pow_a_r + m[5] * pow_b_g + m[8] * pow_c_b
      conv_xyz_to_rgb(x, y, z)
    end

    # The gamma value (/Gamma), default [1, 1, 1].
    def gamma : PDGamma
      array = dictionary.get_array(Cos::Name.new("Gamma"))
      unless array
        array = Cos::Array.new
        array.add(Cos::Float::ONE)
        array.add(Cos::Float::ONE)
        array.add(Cos::Float::ONE)
        dictionary[Cos::Name.new("Gamma")] = array
      end
      PDGamma.new(array)
    end

    # Sets the gamma value (/Gamma); nil clears the entry.
    def gamma=(value : PDGamma?) : Nil
      key = Cos::Name.new("Gamma")
      if value
        dictionary[key] = value.cos_array
      else
        dictionary.delete(key)
      end
    end

    # The linear-interpretation matrix (9 numbers, row-major), default identity.
    def matrix : Array(Float32)
      array = dictionary.get_array(Cos::Name.new("Matrix"))
      return [1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32, 0.0_f32, 0.0_f32, 0.0_f32, 1.0_f32] unless array
      array.to_float_array.map(&.to_f32)
    end

    # Sets the linear-interpretation matrix; nil clears the entry.
    def matrix=(value : Array(Float32)?) : Nil
      key = Cos::Name.new("Matrix")
      if value
        array = Cos::Array.new
        value.each { |component| array.add(Cos::Float.new(component.to_f64)) }
        dictionary[key] = array
      else
        dictionary.delete(key)
      end
    end
  end
end
