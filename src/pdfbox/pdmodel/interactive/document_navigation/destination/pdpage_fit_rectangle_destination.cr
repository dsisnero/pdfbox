module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageFitRectangleDestination < PDPageDestination
    TYPE = "FitR"

    def initialize
      super()
      cos_object.grow_to_size(6, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(TYPE)
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def left : Int32
      cos_object.get_int(2, -1).to_i32
    end

    def left=(x : Int32) : Int32
      cos_object.grow_to_size(6, Cos::Null.instance)
      cos_object[2] = x == -1 ? Cos::Null.instance : Cos::Integer.new(x)
      x
    end

    def bottom : Int32
      cos_object.get_int(3, -1).to_i32
    end

    def bottom=(y : Int32) : Int32
      cos_object.grow_to_size(6, Cos::Null.instance)
      cos_object[3] = y == -1 ? Cos::Null.instance : Cos::Integer.new(y)
      y
    end

    def right : Int32
      cos_object.get_int(4, -1).to_i32
    end

    def right=(x : Int32) : Int32
      cos_object.grow_to_size(6, Cos::Null.instance)
      cos_object[4] = x == -1 ? Cos::Null.instance : Cos::Integer.new(x)
      x
    end

    def top : Int32
      cos_object.get_int(5, -1).to_i32
    end

    def top=(y : Int32) : Int32
      cos_object.grow_to_size(6, Cos::Null.instance)
      cos_object[5] = y == -1 ? Cos::Null.instance : Cos::Integer.new(y)
      y
    end
  end
end
