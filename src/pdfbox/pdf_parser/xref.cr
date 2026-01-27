module Pdfbox::Pdfparser
  # Cross-reference table entry
  class XRefEntry
    @offset : Int64
    @generation : Int64
    @type : Symbol

    def initialize(@offset : Int64, @generation : Int64, @type : Symbol)
    end

    def offset : Int64
      @offset
    end

    def generation : Int64
      @generation
    end

    def type : Symbol
      @type
    end

    def free? : Bool
      @type == :free
    end

    def in_use? : Bool
      @type == :in_use
    end

    def compressed? : Bool
      @type == :compressed
    end
  end

  # Cross-reference table
  class XRef
    @entries = {} of Int64 => XRefEntry

    def initialize(@entries : Hash(Int64, XRefEntry) = {} of Int64 => XRefEntry)
    end

    def entries : Hash(Int64, XRefEntry)
      @entries
    end

    def [](object_number : Int64) : XRefEntry?
      @entries[object_number]?
    end

    def []=(object_number : Int64, entry : XRefEntry) : XRefEntry
      @entries[object_number] = entry
    end

    def size : Int32
      @entries.size
    end
  end
end
