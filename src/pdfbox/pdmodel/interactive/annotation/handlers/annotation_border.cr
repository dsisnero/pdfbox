module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class AnnotationBorder
    property dash_array : Array(Float64)?
    property? underline : Bool
    property width : Float32

    def initialize
      @dash_array = nil
      @underline = false
      @width = 0.0_f32
    end

    def self.annotation_border(
      annot : Annotation::PDAnnotation,
      border_style : Annotation::PDBorderStyleDictionary?,
    ) : AnnotationBorder
      border = new
      if border_style
        border.width = border_style.width.to_f32
        style = border_style.style
        if style == Annotation::PDBorderStyleDictionary::STYLE_DASHED
          border.dash_array = border_style.dash_style.dash_array
        end
        if style == Annotation::PDBorderStyleDictionary::STYLE_UNDERLINE
          border.underline = true
        end
      else
        annotation_border_array = annot.border
        base = annotation_border_array[2]?
        border.width = number_to_f32(base) if base

        dash_base = annotation_border_array[3]?
        if dash_base.is_a?(Cos::Array)
          border.dash_array = dash_base.to_float_array
        end
      end

      dash_array = border.dash_array
      if dash_array && dash_array.all? { |value| value == 0.0_f64 }
        border.dash_array = nil
      end

      border
    end

    private def self.number_to_f32(base : Cos::Base) : Float32
      case base
      when Cos::Integer then base.value.to_f32
      when Cos::Float   then base.value.to_f32
      else
        0.0_f32
      end
    end
  end
end
