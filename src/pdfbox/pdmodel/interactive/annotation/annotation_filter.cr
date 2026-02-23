# Simple interface allowing the use of an annotation filter visitor.
module Pdfbox::Pdmodel::Interactive::Annotation
  # Functional interface for filtering annotations
  module AnnotationFilter
    abstract def accept(annotation : PDAnnotation) : Bool
  end
end
