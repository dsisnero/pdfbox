# Text Rendering Mode.
# Port of Apache PDFBox RenderingMode.
module Pdfbox::Pdmodel::Graphics::State
  enum RenderingMode
    Fill           = 0
    Stroke         = 1
    FillStroke     = 2
    Neither        = 3
    FillClip       = 4
    StrokeClip     = 5
    FillStrokeClip = 6
    NeitherClip    = 7

    # Parse from integer value.
    def self.from_int(value : Int32) : RenderingMode
      from_value(value)
    end

    # Returns the integer value of this mode, as used in a PDF file.
    def int_value : Int32
      value.to_i32
    end

    # Returns true if this mode fills text.
    def fills_text? : Bool
      fill? || fill_stroke? || fill_clip? || fill_stroke_clip?
    end

    # Returns true if this mode strokes text.
    def strokes_text? : Bool
      stroke? || fill_stroke? || stroke_clip? || fill_stroke_clip?
    end

    # Returns true if this mode clips text.
    def clips_text? : Bool
      fill_clip? || stroke_clip? || fill_stroke_clip? || neither_clip?
    end
  end
end
