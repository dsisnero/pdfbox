module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationPolyline < PDAnnotationMarkup
    include AppearanceHandlerSupport

    SUB_TYPE = "PolyLine"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def start_point_ending_style : String
      ending_style_at(0)
    end

    def start_point_ending_style=(value : String?) : String
      set_line_ending_style(0, value || PDAnnotationLine::LE_NONE)
    end

    def end_point_ending_style : String
      ending_style_at(1)
    end

    def end_point_ending_style=(value : String?) : String
      set_line_ending_style(1, value || PDAnnotationLine::LE_NONE)
    end

    def interior_color : Graphics::Color::PDColor?
      color_for(Cos::Name.new("IC"))
    end

    def interior_color=(value : Graphics::Color::PDColor) : Graphics::Color::PDColor
      cos_object[Cos::Name.new("IC")] = value.to_cos_array
      value
    end

    def vertices : Array(Float64)?
      cos_object.get_array(Cos::Name.new("Vertices")).try(&.to_float_array)
    end

    def vertices=(value : Enumerable(Number)) : Array(Float64)
      float_values = value.map(&.to_f64).to_a
      cos_object[Cos::Name.new("Vertices")] = cos_array_of_numbers(float_values)
      float_values
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDPolylineAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end

    private def ending_style_at(index : Int32) : String
      array = cos_object.get_array(Cos::Name.new("LE"))
      return PDAnnotationLine::LE_NONE unless array && array.size >= 2
      array.get_name(index, PDAnnotationLine::LE_NONE) || PDAnnotationLine::LE_NONE
    end

    private def set_line_ending_style(index : Int32, value : String) : String
      array = cos_object.get_array(Cos::Name.new("LE")) || Cos::Array.new
      array.grow_to_size(2, Cos::Name.new(PDAnnotationLine::LE_NONE))
      array.set_name(index, value)
      cos_object[Cos::Name.new("LE")] = array
      value
    end
  end
end
