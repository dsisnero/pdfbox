module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationFileAttachment < PDAnnotationMarkup
    include AppearanceHandlerSupport

    ATTACHMENT_NAME_PUSH_PIN  = "PushPin"
    ATTACHMENT_NAME_GRAPH     = "Graph"
    ATTACHMENT_NAME_PAPERCLIP = "Paperclip"
    ATTACHMENT_NAME_TAG       = "Tag"
    SUB_TYPE                  = "FileAttachment"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def file : Common::Filespecification::PDFileSpecification?
      Common::Filespecification::PDFileSpecification.create_fs(cos_object[Cos::Name.new("FS")]?)
    end

    def file=(value : Common::Filespecification::PDFileSpecification) : Common::Filespecification::PDFileSpecification
      cos_object[Cos::Name.new("FS")] = value.cos_object
      value
    end

    def attachment_name : String
      cos_object.get_name_as_string(Cos::Name::NAME) || ATTACHMENT_NAME_PUSH_PIN
    end

    def attachment_name=(value : String) : String
      cos_object.set_name(Cos::Name::NAME, value)
      value
    end

    def construct_appearances(document : Pdfbox::Pdmodel::Document? = nil) : Nil
      if handler = custom_appearance_handler
        handler.generate_appearance_streams
      else
        Handlers::PDFileAttachmentAppearanceHandler.new(self, document).generate_appearance_streams
      end
    end
  end
end
