# Immutable class for constant sizes
module Pdfbox::Pdmodel::Common
  class PDImmutableRectangle < PDRectangle
    # Constructor for immutable rectangle
    def initialize(width : Float32, height : Float32)
      super(0.0_f32, 0.0_f32, width, height)
    end

    # Override setters to throw UnsupportedOperationException
    def lower_left_x=(value : Float32)
      raise "Immutable class"
    end

    def lower_left_y=(value : Float32)
      raise "Immutable class"
    end

    def upper_right_x=(value : Float32)
      raise "Immutable class"
    end

    def upper_right_y=(value : Float32)
      raise "Immutable class"
    end
  end
end
