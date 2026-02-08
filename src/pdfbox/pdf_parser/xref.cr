# XRef module for PDF cross-reference stream parsing
# Similar to Apache PDFBox xref package
require "../cos"
require "./xref/xreference_type"
require "./xref/xreference_entry"
require "./xref/abstract_xreference"
require "./xref/free_xreference"
require "./xref/normal_xreference"
require "./xref/object_stream_xreference"

module Pdfbox::Pdfparser::Xref
  # Module containing all XRef-related classes
  # This module is included in Pdfbox::Pdfparser namespace
end

# XRef and XRefEntry classes for PDF cross-reference tables
# These are used by the parser and tests
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

    def in_use? : Bool
      @type == :in_use
    end

    def free? : Bool
      @type == :free
    end

    def compressed? : Bool
      @type == :compressed
    end
  end

  # Cross-reference table
  class XRef
    Log = ::Log.for(self)
    @key_to_offset : Hash(Cos::ObjectKey, Int64)
    @object_num_to_entry : Hash(Int64, XRefEntry)

    def initialize
      @key_to_offset = Hash(Cos::ObjectKey, Int64).new
      @object_num_to_entry = Hash(Int64, XRefEntry).new
    end

    def size : Int32
      Log.debug { "XRef.size = #{@key_to_offset.size}, keys: #{@key_to_offset.keys.map(&.number)}" }
      @key_to_offset.size
    end

    # Get entry by object number
    def [](obj_num : Int64) : XRefEntry?
      # First check explicit XRefEntry mapping (set by brute-force)
      if entry = @object_num_to_entry[obj_num]?
        return entry
      end
      # Otherwise, look up offset in key_to_offset and construct XRefEntry
      @key_to_offset.each do |key, offset|
        if key.number == obj_num
          type = if offset == 0 && key.generation == 65535
                   :free
                 elsif offset > 0
                   :in_use
                 else
                   # negative offset indicates compressed entry (should not happen here)
                   :compressed
                 end
          return XRefEntry.new(offset, key.generation, type)
        end
      end
      nil
    end

    # Set entry by object number
    def []=(obj_num : Int64, entry : XRefEntry) : XRefEntry
      @object_num_to_entry[obj_num] = entry
      # Update key_to_offset mapping
      key = Cos::ObjectKey.new(obj_num, entry.generation)
      @key_to_offset[key] = entry.offset
      entry
    end

    # Get offset by object key (used by parser)
    def [](key : Cos::ObjectKey) : Int64?
      @key_to_offset[key]?
    end

    # Safe get offset by object key (returns nil if not found)
    def []?(key : Cos::ObjectKey) : Int64?
      self[key]
    end

    # Find key by object number and stream index
    def find_key(obj_num : Int64, stream_index : Int32) : Cos::ObjectKey?
      @key_to_offset.each_key do |key|
        return key if key.number == obj_num && key.stream_index == stream_index
      end
      nil
    end

    # Set offset by object key (used by parser)
    def []=(key : Cos::ObjectKey, offset : Int64) : Int64
      Log.debug { "XRef[#{key}] = #{offset}" }
      @key_to_offset[key] = offset
      # If there's an existing XRefEntry for this object number, update its offset?
      # Not needed for parser's use case.
      offset
    end

    # Returns all entries as ObjectKey->Int64 mapping
    def entries : Hash(Cos::ObjectKey, Int64)
      @key_to_offset.dup
    end

    # Convert to hash mapping ObjectKey to offset
    def to_hash : Hash(Cos::ObjectKey, Int64)
      @key_to_offset.dup
    end

    # Update internal hash from external hash (used by brute-force parser)
    def update_from_hash(hash : Hash(Cos::ObjectKey, Int64)) : Nil
      hash.each do |key, offset|
        @key_to_offset[key] = offset
        # Optionally update object_num_to_entry? Not needed for brute-force
      end
    end

    # Iterate over all entries (object number -> XRefEntry)
    def each_entry(& : Int64, XRefEntry ->) : Nil
      @key_to_offset.each do |key, offset|
        type = if offset == 0 && key.generation == 65535
                 :free
               elsif offset > 0
                 :in_use
               else
                 :compressed
               end
        entry = XRefEntry.new(offset, key.generation, type)
        yield key.number, entry
      end
    end

    # Get entry by object number (alias for #[])
    def get_entry_by_number(obj_num : Int64) : XRefEntry?
      self[obj_num]
    end
  end
end
