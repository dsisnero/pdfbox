module Fontbox
  module AFM
    class Ligature
      property successor, ligature

      def initialize(@successor : String, @ligature : String)
      end
    end
  end
end
