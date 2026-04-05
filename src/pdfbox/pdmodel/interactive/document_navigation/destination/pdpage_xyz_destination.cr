module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageXYZDestination < PDPageDestination
    TYPE = "XYZ"

    def initialize
      super()
      cos_object.grow_to_size(5, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(TYPE)
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def left : Int32
      cos_object[2]?.as?(Cos::Integer).try(&.value.to_i32) || -1
    end

    def left=(x : Int32) : Int32
      cos_object.grow_to_size(5, Cos::Null.instance)
      cos_object[2] = x == -1 ? Cos::Null.instance : Cos::Integer.new(x)
      x
    end

    def top : Int32
      cos_object[3]?.as?(Cos::Integer).try(&.value.to_i32) || -1
    end

    def top=(y : Int32) : Int32
      cos_object.grow_to_size(5, Cos::Null.instance)
      cos_object[3] = y == -1 ? Cos::Null.instance : Cos::Integer.new(y)
      y
    end

    def zoom : Float64
      case value = cos_object[4]?
      when Cos::Float
        value.value
      when Cos::Integer
        value.value.to_f64
      else
        -1.0
      end
    end

    def zoom=(value : Float64) : Float64
      cos_object.grow_to_size(5, Cos::Null.instance)
      cos_object[4] = value == -1.0 ? Cos::Null.instance : Cos::Float.new(value)
      value
    end
  end
end
