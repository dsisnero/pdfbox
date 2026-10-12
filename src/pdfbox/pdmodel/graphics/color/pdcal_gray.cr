require "./pd_cie_dictionary_based_color_space"

module Pdfbox::Pdmodel::Graphics::Color
  # A CalGray colour space. Corresponds to PDCalGray in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDCalGray.java
  class PDCalGray < PDCIEDictionaryBasedColorSpace
    def initialize
      super(Cos::Name.new("CalGray"))
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def name : String
      "CalGray"
    end

    def number_of_components : Int32
      1
    end

    # Java toRGB: with a default whitepoint, XYZ-correct the single component
    # with the gamma; otherwise skip CIE calibration (return the value as-is).
    def to_rgb(components : Array(Float32)) : Array(Float32)
      unless white_point?
        return [components[0], components[0], components[0]]
      end

      a = components[0].to_f64
      pow_a_g = a ** gamma.to_f64
      conv_xyz_to_rgb(pow_a_g, pow_a_g, pow_a_g)
    end

    # The gamma value (/Gamma), default 1.
    def gamma : Float32
      dictionary.get_float(Cos::Name.new("Gamma"), 1.0).to_f32
    end

    # Sets the gamma value (/Gamma).
    def gamma=(value : Float32) : Nil
      dictionary.set_float(Cos::Name.new("Gamma"), value.to_f64)
    end
  end
end
