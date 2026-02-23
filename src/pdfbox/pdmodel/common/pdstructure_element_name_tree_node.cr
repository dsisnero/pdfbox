# This class holds all of the name trees that are available at the document level.
require "./pdname_tree_node"
require "../document_interchange/logical_structure/pd_structure_element"

module Pdfbox::Pdmodel::Common
  class PDStructureElementNameTreeNode < PDNameTreeNode(Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement)
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

    protected def convert_cos_to_pd(base : Cos::Base) : Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement
      if base.is_a?(Cos::Null)
        # treat as nil
        return Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new("", nil)
      elsif !base.is_a?(Cos::Dictionary)
        raise ::IO::Error.new("dictionary expected here, but got #{base}")
      end
      Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(base)
    end

    protected def create_child_node(dic : Cos::Dictionary) : PDNameTreeNode(Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement)
      PDStructureElementNameTreeNode.new(dic)
    end
  end
end
