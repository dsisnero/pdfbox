# Bidi Embedding Level
#
# Embedding Levels are numbers between 0 and 126 (inclusive), where even values denote a
# left-to-right (LTR) direction and odd values a right-to-left (RTL) direction.
#
# This struct maintains a *valid* status for level numbers, meaning that creating a new level, or
# mutating an existing level, with the value smaller than `0` (before conversion to `UInt8`) or
# larger than 125 results in an `Error`.
#
# <http://www.unicode.org/reports/tr9/#BD2>

module Bidi
  # Embedding Level
  #
  # Embedding Levels are numbers between 0 and 126 (inclusive), where even values denote a
  # left-to-right (LTR) direction and odd values a right-to-left (RTL) direction.
  #
  # This struct maintains a *valid* status for level numbers, meaning that creating a new level, or
  # mutating an existing level, with the value smaller than `0` (before conversion to `u8`) or
  # larger than 125 results in an `Error`.
  #
  # <http://www.unicode.org/reports/tr9/#BD2>
  struct Level
    property value : UInt8

    # New LTR level with smallest number value (0).
    LTR_LEVEL = Level.new(0_u8)
    # New RTL level with smallest number value (1).
    RTL_LEVEL = Level.new(1_u8)

    private MAX_DEPTH = 125_u8
    # During explicit level resolution, embedding level can go as high as `max_depth`.
    MAX_EXPLICIT_DEPTH = MAX_DEPTH
    # During implicit level resolution, embedding level can go as high as `max_depth + 1`.
    MAX_IMPLICIT_DEPTH = MAX_DEPTH + 1_u8

    # Errors that can occur on Level creation or mutation
    enum Error
      OutOfRangeNumber
    end

    # Constructor
    def initialize(@value : UInt8)
    end

    # Create new level, fail if number is larger than `max_depth + 1`.
    def self.create(number : UInt8) : Level | Error
      if number <= MAX_IMPLICIT_DEPTH
        Level.new(number)
      else
        Error::OutOfRangeNumber
      end
    end

    # Create a new explicit Level with the given number, returning an error if out of range.
    # Explicit levels are limited to MAX_EXPLICIT_DEPTH (125).
    def self.create_explicit(number : UInt8) : Level | Error
      if number <= MAX_EXPLICIT_DEPTH
        Level.new(number)
      else
        Error::OutOfRangeNumber
      end
    end

    # New LTR level with smallest number value (0).
    def self.ltr : Level
      LTR_LEVEL
    end

    # New RTL level with smallest number value (1).
    def self.rtl : Level
      RTL_LEVEL
    end

    # Maximum depth of the directional status stack during implicit resolutions.
    def self.max_implicit_depth : UInt8
      MAX_IMPLICIT_DEPTH
    end

    # Maximum depth of the directional status stack during explicit resolutions.
    def self.max_explicit_depth : UInt8
      MAX_EXPLICIT_DEPTH
    end

    # == Constructors ==

    # Create new level, fail if number is larger than `max_depth`.
    def self.new_explicit(number : UInt8) : Level | Error
      create_explicit(number)
    end

    # Create level from number, raising an exception if invalid.
    # This is similar to Rust's `From<u8>` implementation.
    def self.from(number : UInt8) : Level
      result = create(number)
      if result.is_a?(Level)
        result
      else
        raise "Invalid level number: #{number}"
      end
    end

    # == Inquiries ==

    # The level number.
    def number : UInt8
      @value
    end

    # If this level is left-to-right.
    def ltr? : Bool
      @value % 2 == 0
    end

    # If this level is right-to-left.
    def rtl? : Bool
      @value % 2 == 1
    end

    # == Mutators ==

    # Raise level by `amount`, fail if number is larger than `max_depth + 1`.
    def raise(amount : UInt8) : Nil | Error
      # Check for overflow
      if @value > MAX_IMPLICIT_DEPTH - amount
        return Error::OutOfRangeNumber
      end

      number = @value + amount
      if number <= MAX_IMPLICIT_DEPTH
        @value = number
        nil
      else
        Error::OutOfRangeNumber
      end
    end

    # Raise level by `amount`, fail if number is larger than `max_depth`.
    def raise_explicit(amount : UInt8) : Nil | Error
      # Check for overflow
      if @value > MAX_EXPLICIT_DEPTH - amount
        return Error::OutOfRangeNumber
      end

      number = @value + amount
      if number <= MAX_EXPLICIT_DEPTH
        @value = number
        nil
      else
        Error::OutOfRangeNumber
      end
    end

    # Lower level by `amount`, fail if number goes below zero.
    def lower(amount : UInt8) : Nil | Error
      # Check for underflow
      if amount > @value
        return Error::OutOfRangeNumber
      end

      @value = @value - amount
      nil
    end

    # == Helpers ==

    # The next LTR (even) level greater than this, or fail if number is larger than `max_depth`.
    def new_explicit_next_ltr : Level | Error
      Level.create_explicit((@value + 2) & ~1)
    end

    # The next RTL (odd) level greater than this, or fail if number is larger than `max_depth`.
    def new_explicit_next_rtl : Level | Error
      Level.create_explicit((@value + 1) | 1)
    end

    # The lowest RTL (odd) level greater than or equal to this, or fail if number is larger than
    # `max_depth + 1`.
    def new_lowest_ge_rtl : Level | Error
      Level.create(@value | 1)
    end

    # Generate a character type based on a level (as specified in steps X10 and N2).
    def bidi_class : BidiClass
      if rtl?
        BidiClass::R
      else
        BidiClass::L
      end
    end

    # Convert array of bytes to array of Levels
    def self.vec(v : Array(UInt8)) : Array(Level)
      v.map { |x| Level.from(x) }
    end

    # Converts a byte slice to a slice of Levels
    #
    # Does _not_ check if each level is within bounds (`<=` `MAX_IMPLICIT_DEPTH`),
    # which is not a requirement for safety but is a requirement for correctness of the algorithm.
    #
    # Note: In Crystal, we can't do the same unsafe conversion as Rust, so we'll
    # create a new array. This is less efficient but safe.
    def self.from_slice_unchecked(v : Array(UInt8)) : Array(Level)
      v.map { |x| Level.from(x) }
    end

    # If levels has any RTL (odd) level
    #
    # This information is usually used to skip re-ordering of text when no RTL level is present
    def self.has_rtl?(levels : Array(Level)) : Bool
      levels.any?(&.rtl?)
    end

    # == Comparisons ==

    def <=>(other : Level) : Int32?
      @value <=> other.@value
    end

    def ==(other : Level) : Bool
      @value == other.@value
    end

    def <=>(other : Level) : Int32
      @value <=> other.@value
    end

    def <(other : Level) : Bool
      @value < other.@value
    end

    def <=(other : Level) : Bool
      @value <= other.@value
    end

    def >(other : Level) : Bool
      @value > other.@value
    end

    def >=(other : Level) : Bool
      @value >= other.@value
    end

    # Returns the greater of two levels
    def self.max(a : Level, b : Level) : Level
      a >= b ? a : b
    end

    # Used for matching levels in conformance tests
    def ==(s : String) : Bool
      s == "x" || s == @value.to_s
    end

    # Convert to the level number
    def to_u8 : UInt8
      @value
    end

    # String representation
    def to_s(io : IO) : Nil
      io << @value
    end

    def inspect(io : IO) : Nil
      io << "Level(" << @value << ")"
    end
  end
end
