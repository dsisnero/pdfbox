# A rectangle in a PDF document that wraps a COSArray
module Pdfbox::Pdmodel::Common
  class PDRectangle
    POINTS_PER_INCH = 72.0_f32
    POINTS_PER_MM   = 1.0_f32 / (10.0_f32 * 2.54_f32) * POINTS_PER_INCH

    @rect_array : Cos::Array

    # Initialize with default 0,0,0,0
    def initialize
      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
    end

    # Initialize with coordinates
    def initialize(llx : Float32, lly : Float32, urx : Float32, ury : Float32)
      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(llx))
      @rect_array.add(Cos::Float.new(lly))
      @rect_array.add(Cos::Float.new(urx))
      @rect_array.add(Cos::Float.new(ury))
    end

    # Initialize from COSArray
    def initialize(@rect_array : Cos::Array)
    end

    # Get the underlying COSArray
    def cos_object : Cos::Array
      @rect_array
    end

    # Get lower left x
    def lower_left_x : Float32
      value = @rect_array[0]
      case value
      when Cos::Integer then value.value.to_f32
      when Cos::Float   then value.value.to_f32
      else
        0.0_f32
      end
    end

    # Set lower left x
    def lower_left_x=(value : Float32)
      @rect_array[0] = Cos::Float.new(value)
    end

    # Get lower left y
    def lower_left_y : Float32
      value = @rect_array[1]
      case value
      when Cos::Integer then value.value.to_f32
      when Cos::Float   then value.value.to_f32
      else
        0.0_f32
      end
    end

    # Set lower left y
    def lower_left_y=(value : Float32)
      @rect_array[1] = Cos::Float.new(value)
    end

    # Get upper right x
    def upper_right_x : Float32
      value = @rect_array[2]
      case value
      when Cos::Integer then value.value.to_f32
      when Cos::Float   then value.value.to_f32
      else
        0.0_f32
      end
    end

    # Set upper right x
    def upper_right_x=(value : Float32)
      @rect_array[2] = Cos::Float.new(value)
    end

    # Get upper right y
    def upper_right_y : Float32
      value = @rect_array[3]
      case value
      when Cos::Integer then value.value.to_f32
      when Cos::Float   then value.value.to_f32
      else
        0.0_f32
      end
    end

    # Set upper right y
    def upper_right_y=(value : Float32)
      @rect_array[3] = Cos::Float.new(value)
    end

    # Get width
    def width : Float32
      upper_right_x - lower_left_x
    end

    # Get height
    def height : Float32
      upper_right_y - lower_left_y
    end

    # Standard page sizes
    def self.letter : PDRectangle
      PDImmutableRectangle.new(8.5_f32 * POINTS_PER_INCH, 11.0_f32 * POINTS_PER_INCH)
    end

    def self.legal : PDRectangle
      PDImmutableRectangle.new(8.5_f32 * POINTS_PER_INCH, 14.0_f32 * POINTS_PER_INCH)
    end

    def self.a0 : PDRectangle
      PDImmutableRectangle.new(841.0_f32 * POINTS_PER_MM, 1189.0_f32 * POINTS_PER_MM)
    end

    def self.a1 : PDRectangle
      PDImmutableRectangle.new(594.0_f32 * POINTS_PER_MM, 841.0_f32 * POINTS_PER_MM)
    end

    def self.a2 : PDRectangle
      PDImmutableRectangle.new(420.0_f32 * POINTS_PER_MM, 594.0_f32 * POINTS_PER_MM)
    end

    def self.a3 : PDRectangle
      PDImmutableRectangle.new(297.0_f32 * POINTS_PER_MM, 420.0_f32 * POINTS_PER_MM)
    end

    def self.a4 : PDRectangle
      PDImmutableRectangle.new(210.0_f32 * POINTS_PER_MM, 297.0_f32 * POINTS_PER_MM)
    end

    def self.a5 : PDRectangle
      PDImmutableRectangle.new(148.0_f32 * POINTS_PER_MM, 210.0_f32 * POINTS_PER_MM)
    end

    def self.a6 : PDRectangle
      PDImmutableRectangle.new(105.0_f32 * POINTS_PER_MM, 148.0_f32 * POINTS_PER_MM)
    end
  end
end
