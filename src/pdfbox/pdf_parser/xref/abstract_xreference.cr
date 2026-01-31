# Abstract base class for cross-reference stream entries
# Similar to Apache PDFBox AbstractXReference
require "../../cos"
require "./xreference_entry"
require "./xreference_type"

module Pdfbox::Pdfparser::Xref
  abstract class AbstractXReference < XReferenceEntry
    @type : XReferenceType

    # Creates a cross-reference stream entry of the given XReferenceType
    def initialize(@type : XReferenceType)
    end

    # Returns the XReferenceType of this cross-reference stream entry
    def type : XReferenceType
      @type
    end

    # Returns the value for the first column (numeric representation of type)
    def first_column_value : Int64
      @type.numeric_value.to_i64
    end

    # Compare entries by referenced key (object number, generation, stream index)
    def <=>(other : XReferenceEntry) : Int32
      self_key = referenced_key
      other_key = other.referenced_key

      # Handle nil keys (shouldn't happen for valid entries)
      if self_key.nil? && other_key.nil?
        0
      elsif self_key.nil?
        -1
      elsif other_key.nil?
        1
      else
        self_key <=> other_key
      end
    end
  end
end
