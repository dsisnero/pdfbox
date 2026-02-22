module Fontbox
  module Util
    class BoundingBox
      property lower_left_x : Float32
      property lower_left_y : Float32
      property upper_right_x : Float32
      property upper_right_y : Float32

      # Default constructor
      def initialize
        @lower_left_x = 0.0_f32
        @lower_left_y = 0.0_f32
        @upper_right_x = 0.0_f32
        @upper_right_y = 0.0_f32
      end

      def initialize(@lower_left_x : Float32, @lower_left_y : Float32, @upper_right_x : Float32, @upper_right_y : Float32)
      end

      # Constructor from array of numbers
      def initialize(numbers : Array(Float32))
        raise ArgumentError.new("BoundingBox requires exactly 4 numbers") unless numbers.size >= 4
        @lower_left_x = numbers[0]
        @lower_left_y = numbers[1]
        @upper_right_x = numbers[2]
        @upper_right_y = numbers[3]
      end

      def width : Float32
        @upper_right_x - @lower_left_x
      end

      def height : Float32
        @upper_right_y - @lower_left_y
      end

      # Check if point is inside the bounding box
      def contains?(x : Float32, y : Float32) : Bool
        x >= @lower_left_x && x <= @upper_right_x &&
          y >= @lower_left_y && y <= @upper_right_y
      end

      def to_s : String
        "[#{@lower_left_x},#{@lower_left_y},#{@upper_right_x},#{@upper_right_y}]"
      end
    end
  end
end
