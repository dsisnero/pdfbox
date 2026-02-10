module Fontbox
  module Util
    # Represents a rectangle in 2D space with floating-point coordinates.
    # Similar to java.awt.geom.Rectangle2D.Float
    class Rectangle2D
      property x : Float64
      property y : Float64
      property width : Float64
      property height : Float64

      def initialize(@x : Float64 = 0.0, @y : Float64 = 0.0, @width : Float64 = 0.0, @height : Float64 = 0.0)
      end

      # Creates a rectangle from bounds.
      def self.from_bounds(min_x : Float64, min_y : Float64, max_x : Float64, max_y : Float64) : Rectangle2D
        Rectangle2D.new(min_x, min_y, max_x - min_x, max_y - min_y)
      end

      # Returns the minimum x-coordinate.
      def min_x : Float64
        @x
      end

      # Returns the minimum y-coordinate.
      def min_y : Float64
        @y
      end

      # Returns the maximum x-coordinate.
      def max_x : Float64
        @x + @width
      end

      # Returns the maximum y-coordinate.
      def max_y : Float64
        @y + @height
      end

      # Sets the rectangle bounds.
      def set_rect(x : Float64, y : Float64, width : Float64, height : Float64) : Nil
        @x = x
        @y = y
        @width = width
        @height = height
      end

      # Returns whether the rectangle is empty (zero width or height).
      def empty? : Bool
        @width <= 0 || @height <= 0
      end

      # Adds a point to the rectangle, expanding if necessary.
      def add(x : Float64, y : Float64) : Nil
        min_x = Math.min(@x, x)
        max_x = Math.max(self.max_x, x)
        min_y = Math.min(@y, y)
        max_y = Math.max(self.max_y, y)
        @x = min_x
        @width = max_x - min_x
        @y = min_y
        @height = max_y - min_y
      end

      def to_s(io : IO) : Nil
        io << "Rectangle2D(" << @x << ", " << @y << ", " << @width << ", " << @height << ")"
      end
    end
  end
end
