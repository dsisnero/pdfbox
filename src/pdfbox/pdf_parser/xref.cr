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

    # Convert XRef to Hash mapping Cos::ObjectKey to offset (Int64)
    # For compressed entries, offset is negative (object stream number)
    def to_hash : Hash(Cos::ObjectKey, Int64)
      hash = Hash(Cos::ObjectKey, Int64).new
      @entries.each do |obj_num, entry|
        key = Cos::ObjectKey.new(obj_num, entry.generation)
        value = entry.compressed? ? -entry.offset : entry.offset
        hash[key] = value
      end
      hash
    end

    # Update XRef from Hash mapping Cos::ObjectKey to offset (Int64)
    def update_from_hash(hash : Hash(Cos::ObjectKey, Int64)) : Nil
      hash.each do |key, offset|
        if offset < 0
          # compressed entry: offset is negative object stream number
          @entries[key.number] = XRefEntry.new(-offset, key.generation, :compressed)
        else
          # regular in-use entry (assume in-use)
          @entries[key.number] = XRefEntry.new(offset, key.generation, :in_use)
        end
      end
    end
  end
end
