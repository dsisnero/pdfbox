# Simple interface allowing the use of an annotation filter visitor.
module Pdfbox::Pdmodel::Interactive::Annotation
  # Functional interface for filtering annotations
  module AnnotationFilter
    abstract def accept(candidate : PDAnnotation) : Bool
  end
end
