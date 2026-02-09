module Fontbox
  module AFM
    class Composite
      property name, parts

      def initialize(@name : String)
        @parts = [] of CompositePart
      end

      def add_part(part : CompositePart)
        @parts << part
      end
    end
  end
end