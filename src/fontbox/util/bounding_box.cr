module Fontbox
  module Util
    class BoundingBox
      property lower_left_x, lower_left_y, upper_right_x, upper_right_y

      def initialize(@lower_left_x : Float32, @lower_left_y : Float32, @upper_right_x : Float32, @upper_right_y : Float32)
      end

      def width : Float32
        @upper_right_x - @lower_left_x
      end

      def height : Float32
        @upper_right_y - @lower_left_y
      end
    end
  end
end
