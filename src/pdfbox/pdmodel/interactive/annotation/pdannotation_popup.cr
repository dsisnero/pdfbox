module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationPopup < PDAnnotation
    SUB_TYPE = "Popup"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def open? : Bool
      boolean_value(Cos::Name.new("Open"), false)
    end

    def open=(value : Bool) : Bool
      cos_object.set_boolean("Open", value)
      value
    end

    def parent : PDAnnotationMarkup?
      dictionary =
        cos_object.get_dictionary(Cos::Name.new("Parent")) ||
          cos_object.get_dictionary(Cos::Name.new("P"))
      return unless dictionary

      parent_annotation = PDAnnotation.create_annotation(dictionary)
      parent_annotation.as?(PDAnnotationMarkup)
    rescue ::IO::Error
      nil
    end

    def parent=(value : PDAnnotationMarkup) : PDAnnotationMarkup
      cos_object[Cos::Name.new("Parent")] = value.cos_object
      value
    end
  end
end
