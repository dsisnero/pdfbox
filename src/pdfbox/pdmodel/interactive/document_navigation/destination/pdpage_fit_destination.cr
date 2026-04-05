module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageFitDestination < PDPageDestination
    TYPE         = "Fit"
    TYPE_BOUNDED = "FitB"

    def initialize
      super()
      cos_object.grow_to_size(2, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(TYPE)
    end

    def initialize(array : Cos::Array)
      super(array)
    end

    def fit_bounding_box? : Bool
      cos_object.get_name(1) == TYPE_BOUNDED
    end

    def fit_bounding_box=(value : Bool) : Bool
      cos_object.grow_to_size(2, Cos::Null.instance)
      cos_object[1] = Cos::Name.new(value ? TYPE_BOUNDED : TYPE)
      value
    end
  end
end
