# COS (Cos Object System) module for PDFBox Crystal
#
# This module contains the fundamental object types used in PDF documents,
# corresponding to the COS (Cos Object System) in Apache PDFBox.
module Pdfbox::Cos
  # Base class for all COS objects
  abstract class Base
    # TODO: Implement COSBase functionality
  end

  # Marker for null values in PDF
  class Null < Base
    # Singleton instance
    INSTANCE = new

    private def initialize
    end

    def self.instance : Null
      INSTANCE
    end
  end

  # Boolean value in PDF document
  class Boolean < Base
    # PDF true value
    TRUE = new(true)

    # PDF false value
    FALSE = new(false)

    @value : ::Bool

    private def initialize(@value : Bool)
    end

    # Gets the boolean value
    def value : Bool
      @value
    end

    # Gets the boolean value as object
    def value_as_object : Bool
      @value
    end

    # Gets the boolean value for the given parameter
    def self.get(value : Bool) : Boolean
      value ? TRUE : FALSE
    end
  end

  # Integer value in PDF document
  class Integer < Base
    @value : Int64

    def initialize(@value : Int64)
    end

    def value : Int64
      @value
    end

    def value_as_object : Int64
      @value
    end
  end

  # Floating point value in PDF document
  class Float < Base
    @value : Float64

    def initialize(@value : Float64)
    end

    def value : Float64
      @value
    end

    def value_as_object : Float64
      @value
    end
  end

  # String value in PDF document
  class String < Base
    @value : ::String

    def initialize(@value : ::String)
    end

    def value : ::String
      @value
    end

    def value_as_object : ::String
      @value
    end
  end

  # Name object in PDF document (PDF keyword)
  class Name < Base
    @value : ::String

    def initialize(@value : ::String)
    end

    def value : ::String
      @value
    end

    def value_as_object : ::String
      @value
    end
  end

  # Array of COS objects
  class Array < Base
    @items = [] of Base

    def initialize(@items : ::Array(Base) = [] of Base)
    end

    def items : ::Array(Base)
      @items
    end

    def add(item : Base) : self
      @items << item
      self
    end

    def [](index : Int) : Base
      @items[index]
    end

    def []=(index : Int, value : Base) : Base
      @items[index] = value
    end

    def size : Int32
      @items.size
    end
  end

  # Dictionary (key-value pairs) of COS objects
  class Dictionary < Base
    @entries = {} of Name => Base

    def initialize(@entries : ::Hash(Name, Base) = {} of Name => Base)
    end

    def entries : ::Hash(Name, Base)
      @entries
    end

    def []=(key : Name, value : Base) : Base
      @entries[key] = value
    end

    def [](key : Name) : Base?
      @entries[key]?
    end

    def has_key?(key : Name) : Bool
      @entries.has_key?(key)
    end

    def size : Int32
      @entries.size
    end
  end

  # Stream object (dictionary with binary data)
  class Stream < Dictionary
    @data : Bytes = Bytes.empty

    def initialize(entries : ::Hash(Name, Base) = {} of Name => Base, @data : Bytes = Bytes.empty)
      super(entries)
    end

    def data : Bytes
      @data
    end

    def data=(@data : Bytes) : Bytes
      @data
    end
  end

  # Object reference (indirect object)
  class Object < Base
    @object_number : Int64
    @generation_number : Int64
    @object : Base?

    def initialize(@object_number : Int64, @generation_number : Int64 = 0, @object : Base? = nil)
    end

    def object_number : Int64
      @object_number
    end

    def generation_number : Int64
      @generation_number
    end

    def object : Base?
      @object
    end

    def object=(@object : Base?) : Base?
      @object
    end
  end
end
