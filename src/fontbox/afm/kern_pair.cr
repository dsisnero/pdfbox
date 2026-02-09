module Fontbox
  module AFM
    class KernPair
      property first_kern_character, second_kern_character, x, y

      def initialize(@first_kern_character : String, @second_kern_character : String, @x : Float32, @y : Float32)
      end
    end
  end
end