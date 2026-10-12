# A gamma curve, or a collection of three floating point parameters (r, g, b)
# used for gamma correction. Corresponds to PDGamma in Apache PDFBox.
#
# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDGamma.java
module Pdfbox::Pdmodel::Graphics::Color
  class PDGamma
    @values : Cos::Array

    # Defaults all values to 0, 0, 0.
    def initialize
      @values = Cos::Array.new
      @values.add(Cos::Float::ZERO)
      @values.add(Cos::Float::ZERO)
      @values.add(Cos::Float::ZERO)
    end

    # Constructor from a COS array containing the r, g, b values.
    def initialize(@values : Cos::Array)
    end

    # Convert this object to a COS object.
    def cos_object : Cos::Base
      @values
    end

    # Java getCOSArray.
    def cos_array : Cos::Array
      @values
    end

    # Returns the r value of the tristimulus.
    def r : Float32
      number_at(0)
    end

    # Sets the r value of the tristimulus.
    def r=(value : Float32) : Nil
      @values[0] = Cos::Float.new(value.to_f64)
    end

    # Returns the g value of the tristimulus.
    def g : Float32
      number_at(1)
    end

    # Sets the g value of the tristimulus.
    def g=(value : Float32) : Nil
      @values[1] = Cos::Float.new(value.to_f64)
    end

    # Returns the b value of the tristimulus.
    def b : Float32
      number_at(2)
    end

    # Sets the b value of the tristimulus.
    def b=(value : Float32) : Nil
      @values[2] = Cos::Float.new(value.to_f64)
    end

    private def number_at(index : Int32) : Float32
      base = @values[index]
      base = base.object if base.is_a?(Cos::Object)
      case base
      when Cos::Float
        base.value.to_f32
      when Cos::Integer
        base.value.to_f32
      else
        0.0_f32
      end
    end
  end
end
