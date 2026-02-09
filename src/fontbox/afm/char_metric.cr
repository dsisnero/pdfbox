module Fontbox
  module AFM
    class CharMetric
      property character_code, name, wx, w0x, w1x, wy, w0y, w1y,
        w, w0, w1, vv, bounding_box, ligatures

      def initialize
        @character_code = 0
        @name = ""
        @wx = 0.0_f32
        @w0x = 0.0_f32
        @w1x = 0.0_f32
        @wy = 0.0_f32
        @w0y = 0.0_f32
        @w1y = 0.0_f32
        @w = [] of Float32
        @w0 = [] of Float32
        @w1 = [] of Float32
        @vv = [] of Float32
        @bounding_box = Fontbox::Util::BoundingBox.new(0.0_f32, 0.0_f32, 0.0_f32, 0.0_f32)
        @ligatures = [] of Ligature
      end

      def add_ligature(ligature : Ligature)
        @ligatures << ligature
      end
    end
  end
end
