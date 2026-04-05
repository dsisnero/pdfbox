module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageFitWidthDestination < PDPageDestination
    TYPE         = "FitH"
    TYPE_BOUNDED = "FitBH"

    def initialize
      super()
      cos_object.grow_to_size(3, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(TYPE)
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def top : Int32
      cos_object.get_int(2, -1).to_i32
    end

    def top=(y : Int32) : Int32
      cos_object.grow_to_size(3, Cos::Null.instance)
      cos_object[2] = y == -1 ? Cos::Null.instance : Cos::Integer.new(y)
      y
    end

    def fit_bounding_box? : Bool
      cos_object.get_name(1) == TYPE_BOUNDED
    end

    def fit_bounding_box=(value : Bool) : Bool
      cos_object.grow_to_size(3, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(value ? TYPE_BOUNDED : TYPE)
      value
    end
  end
end
