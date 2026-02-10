module Fontbox
  module Util
    # Represents a point in 2D space with floating-point coordinates.
    # Similar to java.awt.geom.Point2D.Float
    struct Point2D
      property x : Float64
      property y : Float64

      def initialize(@x : Float64 = 0.0, @y : Float64 = 0.0)
      end

      # Sets the location of this point to the specified coordinates.
      def set_location(x : Float64, y : Float64) : Nil
        @x = x
        @y = y
      end

      # Returns the x-coordinate as Float64.
      def get_x : Float64
        @x
      end

      # Returns the y-coordinate as Float64.
      def get_y : Float64
        @y
      end

      # Creates a new point with the same coordinates.
      def clone : Point2D
        Point2D.new(@x, @y)
      end

      def to_s(io : IO) : Nil
        io << "Point2D(" << @x << ", " << @y << ")"
      end
    end
  end
end
