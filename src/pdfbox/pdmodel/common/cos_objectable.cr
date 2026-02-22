# Interface for objects that can be converted to COS objects
# Corresponds to org.apache.pdfbox.pdmodel.common.COSObjectable in Apache PDFBox
module Pdfbox::Pdmodel::Common
  module COSObjectable
    # Convert this standard java object to a COS object.
    #
    # @return The cos object that matches this Java object.
    abstract def cos_object : Cos::Base
  end
end
