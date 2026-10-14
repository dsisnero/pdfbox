# A Lab colour space is a CIE-based ABC colour space with two transformation
# stages. Corresponds to PDLab in Apache PDFBox.
module Pdfbox::Pdmodel::Graphics::Color
  class PDLab < PDCIEDictionaryBasedColorSpace
    @initial_color : PDColor?

    # Creates a new Lab color space with default parameters.
    def initialize
      super(Cos::Name.new("Lab"))
    end

    # Creates a new Lab color space from a PDF array.
    def initialize(array : Cos::Array)
      super(array)
    end

    def name : String
      "Lab"
    end

    def number_of_components : Int32
      3
    end

    # Java PDLab#getDefaultDecode: L 0..100 plus the a/b ranges.
    def default_decode(bits_per_component : Int32) : Array(Float32)
      a = a_range
      b = b_range
      [0.0_f32, 100.0_f32, a.min.to_f32, a.max.to_f32, b.min.to_f32, b.max.to_f32]
    end

    # Returns the valid range for the "a" component, defaulting to -100..100.
    def a_range : Pdfbox::Pdmodel::Common::PDRange
      Pdfbox::Pdmodel::Common::PDRange.new(range_array, 0)
    end

    # Returns the valid range for the "b" component, defaulting to -100..100.
    def b_range : Pdfbox::Pdmodel::Common::PDRange
      Pdfbox::Pdmodel::Common::PDRange.new(range_array, 1)
    end

    # Sets the range for the "a" component.
    def a_range=(range : Pdfbox::Pdmodel::Common::PDRange) : Nil
      set_component_range_array(range, 0)
    end

    # Sets the range for the "b" component.
    def b_range=(range : Pdfbox::Pdmodel::Common::PDRange) : Nil
      set_component_range_array(range, 2)
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # CIE LAB to RGB, see http://en.wikipedia.org/wiki/Lab_color_space
      # L*
      lstar = (components[0] + 16.0_f32) * (1.0_f32 / 116.0_f32)

      # XYZ
      x = wp_x * inverse(lstar + components[1] * (1.0_f32 / 500.0_f32))
      y = wp_y * inverse(lstar)
      z = wp_z * inverse(lstar - components[2] * (1.0_f32 / 200.0_f32))

      conv_xyz_to_rgb(x, y, z)
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new([
        0.0_f32,
        Math.max(0.0_f32, a_range.min.to_f32),
        Math.max(0.0_f32, b_range.min.to_f32),
      ], self)
    end

    private def range_array : Cos::Array
      dictionary.get_array(Cos::Name.new("Range")) || default_range_array
    end

    # Creates a range array with default values (-100..100 -100..100).
    private def default_range_array : Cos::Array
      array = Cos::Array.new
      array.add(Cos::Float.new(-100.0))
      array.add(Cos::Float.new(100.0))
      array.add(Cos::Float.new(-100.0))
      array.add(Cos::Float.new(100.0))
      array
    end

    private def set_component_range_array(range : Pdfbox::Pdmodel::Common::PDRange?, index : Int32) : Nil
      range_array = dictionary.get_array(Cos::Name.new("Range")) || default_range_array
      if range
        range_array[index] = Cos::Float.new(range.min)
        range_array[index + 1] = Cos::Float.new(range.max)
      else
        # reset to defaults
        range_array[index] = Cos::Float.new(-100.0)
        range_array[index + 1] = Cos::Float.new(100.0)
      end
      dictionary[Cos::Name.new("Range")] = range_array
      @initial_color = nil
    end

    # reverse transformation (f^-1)
    private def inverse(x : Float32) : Float32
      if x > 6.0_f32 / 29.0_f32
        x * x * x
      else
        (108.0_f32 / 841.0_f32) * (x - (4.0_f32 / 29.0_f32))
      end
    end
  end
end
