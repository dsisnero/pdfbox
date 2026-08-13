require "./pd_outline_node"

module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline
  # This represents an outline item in a PDF document. The items at each level of the
  # hierarchy form an iterable linked list, chained together through their Prev and Next
  # entries.
  # Port of Apache PDFBox PDOutlineItem.
  class PDOutlineItem < PDOutlineNode
    ITALIC_FLAG = 1
    BOLD_FLAG   = 2

    def initialize
      super
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    # Insert a single sibling after this node.
    def insert_sibling_after(new_sibling : PDOutlineItem) : Nil
      require_single_node(new_sibling)
      parent = self.parent
      new_sibling.parent = parent
      next_item = next_sibling
      self.next_sibling = new_sibling
      new_sibling.previous_sibling = self
      if next_item
        new_sibling.next_sibling = next_item
        next_item.previous_sibling = new_sibling
      elsif parent
        parent.set_last_child(new_sibling)
      end
      update_parent_open_count_for_added_child(new_sibling)
    end

    # Insert a single sibling before this node.
    def insert_sibling_before(new_sibling : PDOutlineItem) : Nil
      require_single_node(new_sibling)
      parent = self.parent
      new_sibling.parent = parent
      previous_item = previous_sibling
      self.previous_sibling = new_sibling
      new_sibling.next_sibling = self
      if previous_item
        previous_item.next_sibling = new_sibling
        new_sibling.previous_sibling = previous_item
      elsif parent
        parent.set_first_child(new_sibling)
      end
      update_parent_open_count_for_added_child(new_sibling)
    end

    # Returns the previous sibling or nil if there is no sibling.
    def previous_sibling : PDOutlineItem?
      get_outline_item(Cos::Name::PREV)
    end

    # Returns the next sibling or nil if there is no next sibling.
    def next_sibling : PDOutlineItem?
      get_outline_item(Cos::Name::NEXT)
    end

    # Gets the title of this node.
    def title : String?
      cos_object.get_string(Cos::Name::TITLE)
    end

    # Sets the title for this node.
    def title=(title : String) : Nil
      cos_object.set_string(Cos::Name::TITLE, title)
    end

    protected def previous_sibling=(sibling : PDOutlineNode?) : Nil
      if sibling
        cos_object[Cos::Name::PREV] = sibling.cos_object
      else
        cos_object[Cos::Name::PREV] = Cos::Null.instance
      end
    end

    protected def next_sibling=(sibling : PDOutlineNode?) : Nil
      if sibling
        cos_object[Cos::Name::NEXT] = sibling.cos_object
      else
        cos_object[Cos::Name::NEXT] = Cos::Null.instance
      end
    end

    # Returns true if the text should be italic.
    def italic? : Bool
      cos_object.get_flag(Cos::Name::F, ITALIC_FLAG)
    end

    # Sets the italic property of the text.
    def italic=(italic : Bool) : Nil
      cos_object.set_flag(Cos::Name::F, ITALIC_FLAG, italic)
    end

    # Returns true if the text should be bold.
    def bold? : Bool
      cos_object.get_flag(Cos::Name::F, BOLD_FLAG)
    end

    # Sets the bold property of the text.
    def bold=(bold : Bool) : Nil
      cos_object.set_flag(Cos::Name::F, BOLD_FLAG, bold)
    end
  end
end
