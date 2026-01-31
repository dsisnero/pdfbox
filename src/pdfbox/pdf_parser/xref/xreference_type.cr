# XReference type enumeration for PDF cross-reference streams
# Similar to Apache PDFBox XReferenceType
module Pdfbox::Pdfparser::Xref
  # Type of cross-reference entry in XRef streams
  enum XReferenceType
    # Free entry (type 0)
    Free = 0

    # Normal (in-use) entry (type 1)
    Normal = 1

    # Compressed object stream entry (type 2)
    ObjectStreamEntry = 2

    # Get numeric value (same as underlying enum value)
    def numeric_value : Int32
      value
    end

    # Convert numeric value to XReferenceType (returns nil if invalid)
    def self.from_numeric_value(value : Int32) : XReferenceType?
      from_value?(value)
    end
  end
end
