require "../../interactive/annotation/pdannotation"
require "../../interactive/annotation/pdannotation_unknown"
require "../../graphics/form/pdform_xobject"

module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # An object reference (Java PDObjectReference). Described as "Entries in an
  # object reference dictionary" in the PDF specification.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDObjectReference.java
  class PDObjectReference
    TYPE = "OBJR"

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name("Type", TYPE)
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    # Java getReferencedObject: the /Obj entry as a higher-level object. Java may
    # return a PDAnnotation or a PDXObject. Crystal's PDImageXObject needs a
    # document, so image XObjects (which have no document here) are not resolved;
    # form XObjects and annotations are.
    def referenced_object : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation | Pdfbox::Pdmodel::Graphics::Form::PDFormXObject | Nil
      obj = @dictionary.get_dictionary(Pdfbox::Cos::Name.new("Obj"))
      return unless obj

      if obj.is_a?(Pdfbox::Cos::Stream) &&
         obj.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE) == "Form"
        return Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(obj)
      end

      begin
        annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(obj)
        # /Type is optional, so an unknown-subtype dictionary that is not an
        # annotation is not returned (Java PDObjectReference.getReferencedObject).
        if !annot.is_a?(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationUnknown) ||
           obj.get_name_as_string(Pdfbox::Cos::Name.new("Type")) == "Annot"
          return annot
        end
      rescue
        # Not an annotation (e.g. a raw stream target).
      end
      nil
    end

    # Sets the referenced annotation (Java setReferencedObject(PDAnnotation)).
    def referenced_object=(annot : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation) : Nil
      @dictionary[Pdfbox::Cos::Name.new("Obj")] = annot.cos_object
    end

    # Sets the referenced XObject (Java setReferencedObject(PDXObject)).
    def referenced_object=(xobject : Pdfbox::Pdmodel::Graphics::Form::PDFormXObject) : Nil
      @dictionary[Pdfbox::Cos::Name.new("Obj")] = xobject.cos_object
    end

    # Get the page on which the object shall be rendered (/Pg), or nil.
    def page : Pdfbox::Pdmodel::Page?
      page_dict = @dictionary.get_dictionary(Pdfbox::Cos::Name::PG)
      page_dict ? Pdfbox::Pdmodel::Page.new(page_dict) : nil
    end

    # Sets the page on which the object shall be rendered (/Pg).
    def page=(page : Pdfbox::Pdmodel::Page?) : Nil
      key = Pdfbox::Cos::Name.new("Pg")
      if page
        page_dictionary = page.cos_object || raise ArgumentError.new("page must have a COS dictionary")
        @dictionary[key] = page_dictionary
      else
        @dictionary.delete(key)
      end
    end
  end
end
