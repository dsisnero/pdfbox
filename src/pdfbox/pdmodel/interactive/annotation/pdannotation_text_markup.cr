module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationTextMarkup < PDAnnotationMarkup
    include AppearanceHandlerSupport

    def initialize(sub_type : String)
      super()
      self.subtype = sub_type
      self.quad_points = [] of Float64
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def quad_points : Array(Float64)?
      cos_object.get_array(Cos::Name.new("QuadPoints")).try(&.to_float_array)
    end

    def quad_points=(values : Enumerable(Number)) : Array(Float64)
      floats = values.map(&.to_f64).to_a
      array = Cos::Array.new
      array.float_array = floats
      cos_object[Cos::Name.new("QuadPoints")] = array
      floats
    end
  end
end
