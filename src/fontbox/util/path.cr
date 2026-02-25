module Fontbox
  module Util
    # Represents a 2D geometric path composed of segments.
    # Similar to java.awt.geom.GeneralPath but simplified.
    class Path
      @commands = [] of Command
      @current_point : Point2D? = nil
      @bounds : Rectangle2D = Rectangle2D.new(0, 0, 0, 0)
      @bounds_dirty = true

      private abstract struct Command
      end

      private struct MoveTo < Command
        property x : Float64
        property y : Float64

        def initialize(@x, @y)
        end
      end

      private struct LineTo < Command
        property x : Float64
        property y : Float64

        def initialize(@x, @y)
        end
      end

      private struct CurveTo < Command
        property x1 : Float64
        property y1 : Float64
        property x2 : Float64
        property y2 : Float64
        property x3 : Float64
        property y3 : Float64

        def initialize(@x1, @y1, @x2, @y2, @x3, @y3)
        end
      end

      private struct ClosePath < Command
      end

      # Creates a new empty path.
      def initialize
      end

      # Moves to the specified point.
      def move_to(x : Float64, y : Float64) : Nil
        @commands << MoveTo.new(x, y)
        @current_point = Point2D.new(x, y)
        @bounds_dirty = true
      end

      # Draws a line to the specified point.
      def line_to(x : Float64, y : Float64) : Nil
        @commands << LineTo.new(x, y)
        @current_point = Point2D.new(x, y)
        @bounds_dirty = true
      end

      # Draws a cubic Bézier curve to the specified point.
      def curve_to(x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64, x3 : Float64, y3 : Float64) : Nil
        @commands << CurveTo.new(x1, y1, x2, y2, x3, y3)
        @current_point = Point2D.new(x3, y3)
        @bounds_dirty = true
      end

      # Draws a quadratic Bézier curve to the specified point.
      def quad_to(x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64) : Nil
        cp = current_point
        raise "No current point" if cp.nil?
        # Convert quadratic to cubic
        # P0 = cp, P1 = (x1, y1), P2 = (x2, y2)
        # CP1 = P0 + (2/3)*(P1 - P0)
        # CP2 = P2 + (2/3)*(P1 - P2)
        cx1 = cp.x + (2.0/3.0) * (x1 - cp.x)
        cy1 = cp.y + (2.0/3.0) * (y1 - cp.y)
        cx2 = x2 + (2.0/3.0) * (x1 - x2)
        cy2 = y2 + (2.0/3.0) * (y1 - y2)
        curve_to(cx1, cy1, cx2, cy2, x2, y2)
      end

      # Closes the current subpath.
      def close_path : Nil
        @commands << ClosePath.new
        # current point remains the same as before close
        @bounds_dirty = true
      end

      # Scales the path in place by sx, sy.
      def scale!(sx : Float64, sy : Float64) : Nil
        scaled = [] of Command
        @commands.each do |cmd|
          scaled << case cmd
          when MoveTo
            MoveTo.new(cmd.x * sx, cmd.y * sy)
          when LineTo
            LineTo.new(cmd.x * sx, cmd.y * sy)
          when CurveTo
            CurveTo.new(cmd.x1 * sx, cmd.y1 * sy, cmd.x2 * sx, cmd.y2 * sy, cmd.x3 * sx, cmd.y3 * sy)
          when ClosePath
            cmd
          end
        end
        @commands = scaled
        if cp = @current_point
          @current_point = Point2D.new(cp.x * sx, cp.y * sy)
        end
        @bounds_dirty = true
      end

      # Returns the current point, or nil if no point has been set.
      def current_point : Point2D?
        @current_point
      end

      # Appends the contents of another path to this path.
      def append(other : Path) : Nil
        other.@commands.each do |cmd|
          @commands << cmd
        end
        @current_point = other.@current_point
        @bounds_dirty = true
      end

      # Returns the bounding rectangle of the path.
      def bounds : Rectangle2D
        compute_bounds if @bounds_dirty
        @bounds
      end

      # Resets the path to empty.
      def reset : Nil
        @commands.clear
        @current_point = nil
        @bounds = Rectangle2D.new(0, 0, 0, 0)
        @bounds_dirty = true
      end

      # Returns whether the path is empty.
      def empty? : Bool
        @commands.empty?
      end

      private def compute_bounds : Nil
        min_x = Float64::MAX
        min_y = Float64::MAX
        max_x = -Float64::MAX
        max_y = -Float64::MAX

        @commands.each do |cmd|
          case cmd
          when MoveTo
            min_x = cmd.x if cmd.x < min_x
            min_y = cmd.y if cmd.y < min_y
            max_x = cmd.x if cmd.x > max_x
            max_y = cmd.y if cmd.y > max_y
          when LineTo
            min_x = cmd.x if cmd.x < min_x
            min_y = cmd.y if cmd.y < min_y
            max_x = cmd.x if cmd.x > max_x
            max_y = cmd.y if cmd.y > max_y
          when CurveTo
            # For simplicity, just consider control points
            # Proper bounds would require solving cubic equation extrema
            [cmd.x1, cmd.x2, cmd.x3].each do |x|
              min_x = x if x < min_x
              max_x = x if x > max_x
            end
            [cmd.y1, cmd.y2, cmd.y3].each do |y|
              min_y = y if y < min_y
              max_y = y if y > max_y
            end
          end
        end

        if min_x == Float64::MAX
          @bounds = Rectangle2D.new(0, 0, 0, 0)
        else
          @bounds = Rectangle2D.new(min_x, min_y, max_x - min_x, max_y - min_y)
        end
        @bounds_dirty = false
      end
    end
  end
end
