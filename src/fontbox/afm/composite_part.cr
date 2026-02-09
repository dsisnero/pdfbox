module Fontbox
  module AFM
    class CompositePart
      property name, x, y

      def initialize(@name : String, @x : Int32, @y : Int32)
      end
    end
  end
end