# A tristimulus, or collection of three floating point parameters used for
# color operations. Corresponds to PDTristimulus in Apache PDFBox.
module Pdfbox::Pdmodel::Graphics::Color
  class PDTristimulus
    @values : Cos::Array

    # Defaults all values to 0, 0, 0.
    def initialize
      @values = Cos::Array.new
      @values.add(Cos::Float::ZERO)
      @values.add(Cos::Float::ZERO)
      @values.add(Cos::Float::ZERO)
    end

    # Constructor from a COS array containing the XYZ values.
    def initialize(values : Cos::Array)
      @values = values
    end

    # Constructor from an array of X, Y, Z values.
    def initialize(components : Array(Float64))
      @values = Cos::Array.new
      components.each { |v| @values.add(Cos::Float.new(v)) }
    end

    # Convert this object to a COS object.
    def cos_object : Cos::Base
      @values
    end

    # Returns the x value of the tristimulus.
    def x : Float64
      number_at(0)
    end

    # Sets the x value of the tristimulus.
    def x=(value : Float64) : Nil
      @values[0] = Cos::Float.new(value)
    end

    # Returns the y value of the tristimulus.
    def y : Float64
      number_at(1)
    end

    # Sets the y value of the tristimulus.
    def y=(value : Float64) : Nil
      @values[1] = Cos::Float.new(value)
    end

    # Returns the z value of the tristimulus.
    def z : Float64
      number_at(2)
    end

    # Sets the z value of the tristimulus.
    def z=(value : Float64) : Nil
      @values[2] = Cos::Float.new(value)
    end

    private def number_at(index : Int32) : Float64
      base = @values[index]
      base = base.object if base.is_a?(Cos::Object)
      case base
      when Cos::Float
        base.value
      when Cos::Integer
        base.value.to_f64
      else
        0.0
      end
    end
  end
end
