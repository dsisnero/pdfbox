# Base class for CIE-based colour spaces that carry their parameters in a
# dictionary (Lab, CalRGB, CalGray). Corresponds to
# PDCIEDictionaryBasedColorSpace in Apache PDFBox.
module Pdfbox::Pdmodel::Graphics::Color
  abstract class PDCIEDictionaryBasedColorSpace < PDColorSpace
    @array : Cos::Array
    @dictionary : Cos::Dictionary

    # we need to cache whitepoint values, because using whitepoint would create
    # a new default object for each pixel conversion if the original PDF didn't
    # have a whitepoint array
    protected getter wp_x : Float64 = 1.0
    protected getter wp_y : Float64 = 1.0
    protected getter wp_z : Float64 = 1.0

    def initialize(cos_name : Cos::Name)
      @array = Cos::Array.new
      @dictionary = Cos::Dictionary.new
      @array.add(cos_name)
      @array.add(@dictionary)
      fill_whitepoint_cache(whitepoint)
    end

    def initialize(array : Cos::Array)
      @array = array
      base = @array[1]
      base = base.object if base.is_a?(Cos::Object)
      @dictionary = base.as(Cos::Dictionary)
      fill_whitepoint_cache(whitepoint)
    end

    # Convert this object to a COS object.
    def cos_object : Cos::Base
      @array
    end

    # Get the dictionary holding the color space parameters.
    def dictionary : Cos::Dictionary
      @dictionary
    end

    # Returns the whitepoint tristimulus. As this is a required field this will
    # never return nil. A default of 1,1,1 is returned if the PDF has no value.
    def whitepoint : PDTristimulus
      wp = @dictionary.get_array(Cos::Name.new("WhitePoint"))
      unless wp
        wp = Cos::Array.new
        wp.add(Cos::Float::ONE)
        wp.add(Cos::Float::ONE)
        wp.add(Cos::Float::ONE)
      end
      PDTristimulus.new(wp)
    end

    # Returns the blackpoint tristimulus. This is an optional field but has
    # defaults, so this will never return nil. A default of 0,0,0 is returned
    # if the PDF has no value.
    def blackpoint : PDTristimulus
      bp = @dictionary.get_array(Cos::Name.new("BlackPoint"))
      unless bp
        bp = Cos::Array.new
        bp.add(Cos::Float::ZERO)
        bp.add(Cos::Float::ZERO)
        bp.add(Cos::Float::ZERO)
      end
      PDTristimulus.new(bp)
    end

    # Sets the whitepoint tristimulus.
    def whitepoint=(whitepoint : PDTristimulus) : Nil
      raise ArgumentError.new("Whitepoint may not be null") unless whitepoint
      @dictionary[Cos::Name.new("WhitePoint")] = whitepoint.cos_object.as(Cos::Array)
      fill_whitepoint_cache(whitepoint)
    end

    # Sets the blackpoint tristimulus.
    def blackpoint=(blackpoint : PDTristimulus) : Nil
      @dictionary[Cos::Name.new("BlackPoint")] = blackpoint.cos_object.as(Cos::Array)
    end

    # Returns true if the whitepoint is the default (1, 1, 1).
    # Corresponds to isWhitePoint in Apache PDFBox.
    protected def white_point? : Bool
      wp_x == 1.0 && wp_y == 1.0 && wp_z == 1.0
    end

    # Convert XYZ to RGB, clamping negative values. Corresponds to
    # convXYZtoRGB in Apache PDFBox.
    protected def conv_xyz_to_rgb(x : Float64, y : Float64, z : Float64) : Array(Float32) # XYZ must be non-negative
      x = 0.0 if x < 0
      y = 0.0 if y < 0
      z = 0.0 if z < 0

      # sRGB conversion from XYZ (D65)
      r = 3.2406 * x - 1.5372 * y - 0.4986 * z
      g = -0.9689 * x + 1.8758 * y + 0.0415 * z
      b = 0.0557 * x - 0.2040 * y + 1.0570 * z

      [gamma_correct(r).to_f32, gamma_correct(g).to_f32, gamma_correct(b).to_f32]
    end

    private def fill_whitepoint_cache(whitepoint : PDTristimulus)
      @wp_x = whitepoint.x
      @wp_y = whitepoint.y
      @wp_z = whitepoint.z
    end

    private def gamma_correct(value : Float64) : Float64
      value = Math.max(0.0, Math.min(1.0, value))
      if value <= 0.0031308
        12.92 * value
      else
        1.055 * (value ** (1.0 / 2.4)) - 0.055
      end
    end
  end
end
