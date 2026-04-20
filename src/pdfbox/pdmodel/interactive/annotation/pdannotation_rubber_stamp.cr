module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotationRubberStamp < PDAnnotationMarkup
    NAME_APPROVED               = "Approved"
    NAME_EXPERIMENTAL           = "Experimental"
    NAME_NOT_APPROVED           = "NotApproved"
    NAME_AS_IS                  = "AsIs"
    NAME_EXPIRED                = "Expired"
    NAME_NOT_FOR_PUBLIC_RELEASE = "NotForPublicRelease"
    NAME_FOR_PUBLIC_RELEASE     = "ForPublicRelease"
    NAME_DRAFT                  = "Draft"
    NAME_FOR_COMMENT            = "ForComment"
    NAME_TOP_SECRET             = "TopSecret"
    NAME_DEPARTMENTAL           = "Departmental"
    NAME_CONFIDENTIAL           = "Confidential"
    NAME_FINAL                  = "Final"
    NAME_SOLD                   = "Sold"
    SUB_TYPE                    = "Stamp"

    def initialize(dictionary : Cos::Dictionary = Cos::Dictionary.new)
      super(dictionary)
      self.subtype = SUB_TYPE
    end

    def name : String
      cos_object.get_name_as_string(Cos::Name::NAME) || NAME_DRAFT
    end

    def name=(value : String) : String
      cos_object.set_name(Cos::Name::NAME, value)
      value
    end
  end
end
