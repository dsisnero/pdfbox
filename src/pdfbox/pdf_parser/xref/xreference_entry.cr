# XReference entry interface for PDF cross-reference streams
# Similar to Apache PDFBox XReferenceEntry
require "./xreference_type"
require "../../cos/object_key"

module Pdfbox::Pdfparser::Xref
  # Abstract base class for cross-reference stream entries
  abstract class XReferenceEntry
    include Comparable(XReferenceEntry)

    # Returns the XReferenceType of this cross-reference stream entry
    abstract def type : XReferenceType

    # Returns the COSObjectKey of the object described by this entry
    abstract def referenced_key : Cos::ObjectKey

    # Returns the value for the first column (type numeric representation)
    abstract def first_column_value : Int64

    # Returns the value for the second column (meaning depends on type)
    abstract def second_column_value : Int64

    # Returns the value for the third column (meaning depends on type)
    abstract def third_column_value : Int64

    # Compare entries by referenced key (object number, generation, stream index)
    def <=>(other : XReferenceEntry) : Int32
      referenced_key <=> other.referenced_key
    end

    # Convert to string representation for debugging
    def to_s(io : IO) : Nil
      io << "#<" << self.class.name << " type=" << type
      io << " key=" << referenced_key
      io << " columns=[" << first_column_value << "," << second_column_value << "," << third_column_value << "]>"
    end

    # Check equality based on referenced key and column values
    def ==(other : self) : Bool
      return false unless self.class == other.class
      type == other.type &&
        referenced_key == other.referenced_key &&
        first_column_value == other.first_column_value &&
        second_column_value == other.second_column_value &&
        third_column_value == other.third_column_value
    end

    def_hash referenced_key, first_column_value, second_column_value, third_column_value
  end
end
