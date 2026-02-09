module Fontbox
  module AFM
    class TrackKern
      property degree, min_point_size, min_kern, max_point_size, max_kern

      def initialize(@degree : Int32, @min_point_size : Float32, @min_kern : Float32,
                     @max_point_size : Float32, @max_kern : Float32)
      end
    end
  end
end