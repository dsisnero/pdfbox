# Free reference in a PDF's cross-reference stream
# Similar to Apache PDFBox FreeXReference
require "../../cos"
require "./abstract_xreference"

module Pdfbox::Pdfparser::Xref
  class FreeXReference < AbstractXReference
    @key : Cos::ObjectKey
    @next_free_object : Int64

    # NULL_ENTRY constant (object 0, generation 65535)
    NULL_ENTRY = new(Cos::ObjectKey.new(0_i64, 65535_i64), 0_i64)

    # Creates a free reference for the given key with next free object number
    def initialize(@key : Cos::ObjectKey, @next_free_object : Int64)
      super(XReferenceType::Free)
    end

    # Returns the COSObjectKey of the object described by this entry
    def referenced_key : Cos::ObjectKey
      @key
    end

    # Returns the object number of the next free object
    def next_free_object : Int64
      @next_free_object
    end

    # Returns the value for the second column (next free object number)
    def second_column_value : Int64
      @next_free_object
    end

    # Returns the value for the third column (generation number of referenced key)
    def third_column_value : Int64
      @key.generation
    end

    # Convert to string representation for debugging
    def to_s(io : IO) : Nil
      io << "#<FreeXReference key=" << @key
      io << " next_free_object=" << @next_free_object
      io << " type=" << type << ">"
    end
  end
end
