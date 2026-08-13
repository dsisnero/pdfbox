require "./pd_outline_node"

module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline
  # This represents an outline in a PDF document.
  # Port of Apache PDFBox PDDocumentOutline.
  class PDDocumentOutline < PDOutlineNode
    def initialize
      super
      cos_object.set_name(Cos::Name::TYPE, Cos::Name::OUTLINES.value)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
      cos_object.set_name(Cos::Name::TYPE, Cos::Name::OUTLINES.value)
    end

    # The root of the outline hierarchy is always considered open.
    def node_open? : Bool
      true
    end

    def open_node : Nil
      # The root of the outline hierarchy is not an OutlineItem and cannot be opened or closed
    end

    def close_node : Nil
      # The root of the outline hierarchy is not an OutlineItem and cannot be opened or closed
    end
  end
end
