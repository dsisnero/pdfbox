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

    def ==(other : self) : Bool
      @offset == other.offset && @generation == other.generation && @type == other.type
    end

    def_hash @offset, @generation, @type
  end

  # Cross-reference table
  # Maps ObjectKey to offset (Int64) following Apache PDFBox pattern:
  # - offset > 0: in-use entry (file offset)
  # - offset = 0: free entry
  # - offset < 0: compressed entry (absolute value is object stream number)
  class XRef
    @entries = {} of Cos::ObjectKey => Int64

    def initialize(@entries : Hash(Cos::ObjectKey, Int64) = {} of Cos::ObjectKey => Int64)
    end

    def entries : Hash(Cos::ObjectKey, Int64)
      @entries
    end

    # Get offset for object key (returns nil if not found)
    def [](key : Cos::ObjectKey) : Int64?
      @entries[key]?
    end

    # Safe indexing (same as [])
    def []?(key : Cos::ObjectKey) : Int64?
      @entries[key]?
    end

    # Set offset for object key
    def []=(key : Cos::ObjectKey, offset : Int64) : Int64
      @entries[key] = offset
    end

    # Get entry by object number (for backward compatibility)
    # Note: This may return wrong entry if there are duplicate object numbers with different stream_index
    def get_by_object_number(object_number : Int64) : Int64?
      @entries.each do |key, offset|
        return offset if key.number == object_number && key.stream_index == -1
      end
      nil
    end

    # Get XRefEntry by object number (backward compatibility)
    # Returns first matching non-compressed entry
    def get_entry_by_number(object_number : Int64) : XRefEntry?
      @entries.each do |key, offset|
        if key.number == object_number && key.stream_index == -1
          if offset > 0
            return XRefEntry.new(offset, key.generation, :in_use)
          elsif offset < 0
            return XRefEntry.new(-offset, key.generation, :compressed)
          else
            return XRefEntry.new(offset, key.generation, :free)
          end
        end
      end
      nil
    end

    # Index by object number (backward compatibility)
    def [](object_number : Int64) : XRefEntry?
      get_entry_by_number(object_number)
    end

    # Safe indexing by object number (backward compatibility)
    def []?(object_number : Int64) : XRefEntry?
      get_entry_by_number(object_number)
    end

    # Set entry by object number (backward compatibility)
    # Creates key with given generation from entry, stream_index -1
    def []=(object_number : Int64, entry : XRefEntry) : XRefEntry
      key = Cos::ObjectKey.new(object_number, entry.generation)
      @entries[key] = entry.offset * (entry.type == :compressed ? -1 : 1)
      entry
    end

    # Iterate over entries as (object_number, XRefEntry) for backward compatibility
    def each_entry(& : Int64, XRefEntry ->) : Nil
      @entries.each do |key, offset|
        obj_num = key.number
        entry = if offset > 0
                  XRefEntry.new(offset, key.generation, :in_use)
                elsif offset < 0
                  XRefEntry.new(-offset, key.generation, :compressed)
                else
                  XRefEntry.new(offset, key.generation, :free)
                end
        yield obj_num, entry
      end
    end

    # Get all entries as Hash(Int64, XRefEntry) for backward compatibility
    def entries_by_number : Hash(Int64, XRefEntry)
      result = Hash(Int64, XRefEntry).new
      each_entry do |obj_num, entry|
        result[obj_num] = entry
      end
      result
    end

    def size : Int32
      @entries.size
    end

    # Convert to hash (for compatibility with existing code)
    def to_hash : Hash(Cos::ObjectKey, Int64)
      @entries.dup
    end

    # Update from hash (for compatibility with existing code)
    def update_from_hash(hash : Hash(Cos::ObjectKey, Int64)) : Nil
      @entries.merge!(hash)
    end

    # Convert to XRefEntry list for writing (used by PDFWriter)
    def to_xref_entries : Array(XRefEntry)
      result = [] of XRefEntry
      @entries.each do |key, offset|
        if offset > 0
          result << XRefEntry.new(offset, key.generation, :in_use)
        elsif offset < 0
          result << XRefEntry.new(-offset, key.generation, :compressed)
        else
          result << XRefEntry.new(offset, key.generation, :free)
        end
      end
      result
    end
  end
end
