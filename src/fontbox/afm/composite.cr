module Fontbox
  module AFM
    class Composite
      property name

      @parts : Array(CompositePart)

      def initialize(@name : String)
        @parts = [] of CompositePart
      end

      # Port of Java getParts: the returned list is unmodifiable.
      def parts : UnmodifiableList(CompositePart)
        UnmodifiableList.new(@parts)
      end

      def add_part(part : CompositePart)
        @parts << part
      end
    end
  end
end
