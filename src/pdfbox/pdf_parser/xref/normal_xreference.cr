# Normal reference in a PDF's cross-reference stream
# Similar to Apache PDFBox NormalXReference
require "../../cos"
require "./abstract_xreference"

module Pdfbox::Pdfparser::Xref
  class NormalXReference < AbstractXReference
    @byte_offset : Int64
    @key : Cos::ObjectKey
    @object : Cos::Base?
    @object_stream : Bool

    # Creates a normal reference for the given key with byte offset
    def initialize(@byte_offset : Int64, @key : Cos::ObjectKey, @object : Cos::Base? = nil)
      super(XReferenceType::Normal)

      # Determine if referenced object is an object stream
      @object_stream = if obj = @object
                         if obj.is_a?(Cos::Object)
                           base = obj.object
                           if base.is_a?(Cos::Stream)
                             type_entry = base[Cos::Name.new("Type")]
                             type_entry.is_a?(Cos::Name) && type_entry.value == "ObjStm"
                           else
                             false
                           end
                         elsif obj.is_a?(Cos::Stream)
                           type_entry = obj[Cos::Name.new("Type")]
                           type_entry.is_a?(Cos::Name) && type_entry.value == "ObjStm"
                         else
                           false
                         end
                       else
                         false
                       end
    end

    # Returns the byte offset of the object in the PDF file
    def byte_offset : Int64
      @byte_offset
    end

    # Returns the COSObjectKey of the object described by this entry
    def referenced_key : Cos::ObjectKey
      @key
    end

    # Returns the object (may be nil if not parsed yet)
    def object : Cos::Base?
      @object
    end

    # Returns true if the referenced object is an object stream
    def object_stream? : Bool
      @object_stream
    end

    # Returns the value for the second column (byte offset)
    def second_column_value : Int64
      @byte_offset
    end

    # Returns the value for the third column (generation number)
    def third_column_value : Int64
      @key.generation
    end

    # Convert to string representation for debugging
    def to_s(io : IO) : Nil
      prefix = object_stream? ? "ObjectStreamParent" : "NormalReference"
      io << "#<" << prefix << " key=" << @key
      io << " type=" << type
      io << " byte_offset=" << @byte_offset
      io << ">"
    end
  end
end
