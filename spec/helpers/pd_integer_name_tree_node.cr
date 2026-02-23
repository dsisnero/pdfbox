require "../../src/pdfbox/pdmodel/common/pdname_tree_node"

module Pdfbox::Pdmodel::Common
  # Test helper class for PDNameTreeNode with integer values.
  class PDIntegerNameTreeNode < PDNameTreeNode(Cos::Integer)
    # Constructor.
    def initialize
      super
    end

    # Constructor with dictionary.
    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    protected def convert_cos_to_pd(base : Cos::Base) : Cos::Integer
      unless base.is_a?(Cos::Integer)
        raise "integer expected here, but got #{base}"
      end
      base
    end

    protected def create_child_node(dic : Cos::Dictionary) : PDIntegerNameTreeNode
      PDIntegerNameTreeNode.new(dic)
    end
  end
end
