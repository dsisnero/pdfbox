# This class holds all of the name trees that are available at the document level.
require "./pdname_tree_node"
require "./filespecification/pdcomplex_file_specification"

module Pdfbox::Pdmodel::Common
  class PDEmbeddedFilesNameTreeNode < PDNameTreeNode(PDComplexFileSpecification)
    # Constructor.
    def initialize
      super
    end

    # Constructor.
    #
    # @param dic The COS dictionary.
    def initialize(dic : Cos::Dictionary)
      super(dic)
    end

    protected def convert_cos_to_pd(base : Cos::Base) : PDComplexFileSpecification
      if base.is_a?(Cos::Null)
        # treat as nil
        return PDComplexFileSpecification.new(nil)
      elsif !base.is_a?(Cos::Dictionary)
        raise ::IO::Error.new("dictionary expected here, but got #{base}")
      end
      PDComplexFileSpecification.new(base)
    end

    protected def create_child_node(dic : Cos::Dictionary) : PDNameTreeNode(PDComplexFileSpecification)
      PDEmbeddedFilesNameTreeNode.new(dic)
    end
  end
end
