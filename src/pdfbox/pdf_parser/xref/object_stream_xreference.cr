# Object stream entry reference in a PDF's cross-reference stream
# Similar to Apache PDFBox ObjectStreamXReference
require "../../cos"
require "./abstract_xreference"

module Pdfbox::Pdfparser::Xref
  class ObjectStreamXReference < AbstractXReference
    @object_stream_index : Int32
    @key : Cos::ObjectKey
    @object : Cos::Base?
    @parent_key : Cos::ObjectKey

    # Creates an object stream entry reference
    def initialize(@object_stream_index : Int32, @key : Cos::ObjectKey,
                   @parent_key : Cos::ObjectKey, @object : Cos::Base? = nil)
      super(XReferenceType::ObjectStreamEntry)
    end

    # Returns the index of the object in its containing object stream
    def object_stream_index : Int32
      @object_stream_index
    end

    # Returns the COSObjectKey of the object described by this entry
    def referenced_key : Cos::ObjectKey
      @key
    end

    # Returns the object (may be nil if not parsed yet)
    def object : Cos::Base?
      @object
    end

    # Returns the COSObjectKey of the parent object stream
    def parent_key : Cos::ObjectKey
      @parent_key
    end

    # Returns the value for the second column (parent object stream number)
    def second_column_value : Int64
      @parent_key.number
    end

    # Returns the value for the third column (object stream index)
    def third_column_value : Int64
      @object_stream_index.to_i64
    end

    # Convert to string representation for debugging
    def to_s(io : IO) : Nil
      io << "#<ObjectStreamXReference key=" << @key
      io << " type=" << type
      io << " object_stream_index=" << @object_stream_index
      io << " parent=" << @parent_key
      io << ">"
    end
  end
end
