# Wraps the COS value of an entry in the structural parent tree.
# Corresponds to PDParentTreeValue in Apache PDFBox.
module Pdfbox::Pdmodel::Common
  class PDParentTreeValue
    include COSObjectable

    @parent_tree_value : Cos::Base

    def initialize(@parent_tree_value : Cos::Base)
    end

    def cos_object : Cos::Base
      @parent_tree_value
    end
  end
end
