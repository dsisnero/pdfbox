# A rectangle in a PDF document that wraps a COSArray
module Pdfbox::Pdmodel::Common
  class PDRectangle
    POINTS_PER_INCH = 72.0_f32
    POINTS_PER_MM   = 1.0_f32 / (10.0_f32 * 2.54_f32) * POINTS_PER_INCH

    # Standard page size constants (immutable)
    LETTER  = PDImmutableRectangle.new(8.5_f32 * POINTS_PER_INCH, 11.0_f32 * POINTS_PER_INCH)
    TABLOID = PDImmutableRectangle.new(11.0_f32 * POINTS_PER_INCH, 17.0_f32 * POINTS_PER_INCH)
    LEGAL   = PDImmutableRectangle.new(8.5_f32 * POINTS_PER_INCH, 14.0_f32 * POINTS_PER_INCH)
    A0      = PDImmutableRectangle.new(841.0_f32 * POINTS_PER_MM, 1189.0_f32 * POINTS_PER_MM)
    A1      = PDImmutableRectangle.new(594.0_f32 * POINTS_PER_MM, 841.0_f32 * POINTS_PER_MM)
    A2      = PDImmutableRectangle.new(420.0_f32 * POINTS_PER_MM, 594.0_f32 * POINTS_PER_MM)
    A3      = PDImmutableRectangle.new(297.0_f32 * POINTS_PER_MM, 420.0_f32 * POINTS_PER_MM)
    A4      = PDImmutableRectangle.new(210.0_f32 * POINTS_PER_MM, 297.0_f32 * POINTS_PER_MM)
    A5      = PDImmutableRectangle.new(148.0_f32 * POINTS_PER_MM, 210.0_f32 * POINTS_PER_MM)
    A6      = PDImmutableRectangle.new(105.0_f32 * POINTS_PER_MM, 148.0_f32 * POINTS_PER_MM)

    @rect_array : Cos::Array

    # Initialize with default 0,0,0,0
    def initialize
      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
      @rect_array.add(Cos::Float.new(0.0))
    end

    # Initialize with width and height (lower-left at 0,0)
    def initialize(width : Float32, height : Float32)
      initialize(0.0_f32, 0.0_f32, width, height)
    end

    # Initialize with lower-left corner and dimensions
    def initialize(x : Float32, y : Float32, width : Float32, height : Float32)
      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(x))
      @rect_array.add(Cos::Float.new(y))
      @rect_array.add(Cos::Float.new(x + width))
      @rect_array.add(Cos::Float.new(y + height))
    end

    # Initialize from BoundingBox
    def initialize(box : Fontbox::Util::BoundingBox)
      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(box.lower_left_x))
      @rect_array.add(Cos::Float.new(box.lower_left_y))
      @rect_array.add(Cos::Float.new(box.upper_right_x))
      @rect_array.add(Cos::Float.new(box.upper_right_y))
    end

    # Initialize from COSArray with normalization (ensures lower-left and upper-right order)
    def initialize(array : Cos::Array)
      # Copy values and replace huge values (malformed PDF protection)
      values = [] of Float32
      array.items.each do |item|
        case item
        when Cos::Integer
          values << item.value.to_f32
        when Cos::Float
          values << item.value.to_f32
        else
          values << 0.0_f32
        end
      end
      # Ensure at least 4 elements
      while values.size < 4
        values << 0.0_f32
      end
      # Replace huge values (Java uses Integer.MAX_VALUE)
      max_float = Int32::MAX.to_f32
      values.each_with_index do |val, i|
        if val.abs > max_float
          values[i] = val > 0 ? max_float : -max_float
        end
      end
      # Normalize to ensure lower-left and upper-right order
      llx = Math.min(values[0], values[2])
      lly = Math.min(values[1], values[3])
      urx = Math.max(values[0], values[2])
      ury = Math.max(values[1], values[3])

      @rect_array = Cos::Array.new
      @rect_array.add(Cos::Float.new(llx))
      @rect_array.add(Cos::Float.new(lly))
      @rect_array.add(Cos::Float.new(urx))
      @rect_array.add(Cos::Float.new(ury))
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

    # Standard page size methods (return immutable constants)
    def self.letter : PDRectangle
      LETTER
    end

    def self.legal : PDRectangle
      LEGAL
    end

    def self.tabloid : PDRectangle
      TABLOID
    end

    def self.a0 : PDRectangle
      A0
    end

    def self.a1 : PDRectangle
      A1
    end

    def self.a2 : PDRectangle
      A2
    end

    def self.a3 : PDRectangle
      A3
    end

    def self.a4 : PDRectangle
      A4
    end

    def self.a5 : PDRectangle
      A5
    end

    def self.a6 : PDRectangle
      A6
    end

    # Returns the four corner points of this rectangle as a path.
    # Points are returned in order: lower-left, lower-right, upper-right, upper-left.
    # Used for clipping path initialization.
    def to_path : Array(Tuple(Float32, Float32))
      x1 = lower_left_x
      y1 = lower_left_y
      x2 = upper_right_x
      y2 = upper_right_y
      [{x1, y1}, {x2, y1}, {x2, y2}, {x1, y2}]
    end
  end
end
