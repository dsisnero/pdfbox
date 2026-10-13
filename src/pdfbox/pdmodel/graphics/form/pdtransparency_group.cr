require "./pdform_xobject"

module Pdfbox::Pdmodel::Graphics::Form
  # A transparency group. Corresponds to PDTransparencyGroup in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/form/PDTransparencyGroup.java
  class PDTransparencyGroup < PDFormXObject
    def initialize(stream : Pdfbox::Cos::Stream, cache : Pdfbox::Pdmodel::ResourceCache? = nil)
      super(stream, cache)
    end

    def initialize(document : Pdfbox::Pdmodel::Document)
      super(document)
    end
  end
end
