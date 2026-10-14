module Pdfbox::Rendering
  # Optional content groups are visible depending on the render purpose.
  # Port of Apache PDFBox RenderDestination.
  enum RenderDestination
    EXPORT
    VIEW
    PRINT
  end
end
