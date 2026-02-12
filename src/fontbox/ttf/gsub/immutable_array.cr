# Immutable array subclass that raises on mutation attempts.
#
# Ported from Java's Collections.unmodifiableList behavior.
module Fontbox::TTF::Gsub
  class ImmutableArray(T) < Array(T)
    class ImmutableError < Exception
    end

    def initialize(array : Array(T))
      super(array.size)
      array.each do |item|
        @buffer[@size] = item
        @size += 1
      end
    end

    # Mutation methods that raise ImmutableError

    def <<(value : T) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def []=(index : Int, value : T) : T
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def push(value : T) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def pop : T
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def pop(n : Int) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def pop? : T?
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def shift : T
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def shift(n : Int) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def shift? : T?
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def insert(index : Int, value : T) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def delete_at(index : Int) : T
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def delete_at(index : Int, count : Int) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def clear : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def fill(value : T, start : Int, count : Int) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def fill(value : T, range : Range) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def fill(value : T) : self
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def reverse! : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def rotate!(n : Int = 1) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def shuffle!(random : Random = Random::DEFAULT) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def sort! : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def sort!(&_block : T, T -> Int32) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def sort_by!(&_block : T -> _) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def uniq! : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def compact! : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def map!(& : T -> T) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def map_with_index!(& : T, Int32 -> T) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def select!(& : T -> Bool) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    def reject!(& : T -> Bool) : Array(T)
      raise ImmutableError.new("Cannot modify immutable array")
    end

    # Allow duplication to get mutable copy
    def dup : Array(T)
      to_a
    end

    def clone : Array(T)
      to_a
    end
  end
end
