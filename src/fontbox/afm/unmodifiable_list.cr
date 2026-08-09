module Fontbox
  module AFM
    # Read-only wrapper over an Array, matching Java's
    # Collections.unmodifiableList: reads delegate, mutations raise.
    class UnmodifiableList(T)
      include Enumerable(T)
      include Indexable(T)

      @inner : Array(T)

      def initialize(@inner : Array(T))
      end

      def size
        @inner.size
      end

      def unsafe_fetch(index : Int)
        @inner.unsafe_fetch(index)
      end

      def each(& : T ->)
        @inner.each { |item| yield item }
      end

      def <<(value : T)
        raise ::Exception.new("cannot add to an unmodifiable list")
      end

      def push(value : T)
        raise ::Exception.new("cannot add to an unmodifiable list")
      end

      def concat(other : Array(T))
        raise ::Exception.new("cannot add to an unmodifiable list")
      end

      def delete(value : T)
        raise ::Exception.new("cannot remove from an unmodifiable list")
      end

      def clear
        raise ::Exception.new("cannot modify an unmodifiable list")
      end

      def to_a : Array(T)
        @inner.dup
      end
    end
  end
end
