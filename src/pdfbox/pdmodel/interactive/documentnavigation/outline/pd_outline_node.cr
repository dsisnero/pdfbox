require "../../../common/pddictionary_wrapper"

module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline
  # Base class for a node in the outline of a PDF document.
  # Port of Apache PDFBox PDOutlineNode.
  abstract class PDOutlineNode < Common::PDDictionaryWrapper
    def initialize
      super
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    # Returns the parent of this node or nil if there is no parent.
    def parent : PDOutlineNode?
      parent_dict = cos_object.get_dictionary(Cos::Name::PARENT)
      return unless parent_dict

      if parent_dict.get_name_as_string(Cos::Name::TYPE) == Cos::Name::OUTLINES.value
        PDDocumentOutline.new(parent_dict)
      else
        PDOutlineItem.new(parent_dict)
      end
    end

    protected def parent=(parent : PDOutlineNode?)
      if parent
        cos_object[Cos::Name::PARENT] = parent.cos_object
      else
        cos_object[Cos::Name::PARENT] = Cos::Null.instance
      end
    end

    # Adds the given node to the bottom of the children list.
    def add_last(new_child : PDOutlineItem) : Nil
      require_single_node(new_child)
      append(new_child)
      update_parent_open_count_for_added_child(new_child)
    end

    # Adds the given node to the top of the children list.
    def add_first(new_child : PDOutlineItem) : Nil
      require_single_node(new_child)
      prepend(new_child)
      update_parent_open_count_for_added_child(new_child)
    end

    # @raise ArgumentError if the given node is part of a list (i.e. has a sibling)
    def require_single_node(node : PDOutlineItem) : Nil
      if node.next_sibling || node.previous_sibling
        raise ::ArgumentError.new("A single node with no siblings is required")
      end
    end

    # Returns true if the node has at least one child.
    def has_children? : Bool
      cos_object.get_dictionary(Cos::Name::FIRST) != nil
    end

    # Returns the first child or nil if there is no child.
    def first_child : PDOutlineItem?
      get_outline_item(Cos::Name::FIRST)
    end

    # Returns the last child or nil if there is no child.
    def last_child : PDOutlineItem?
      get_outline_item(Cos::Name::LAST)
    end

    # Returns the number of open nodes, or a negative number if this node is closed.
    # See PDF Reference 32000-1:2008 tables 152 and 153.
    def open_count : Int32
      cos_object.get_int(Cos::Name::COUNT, 0_i64).to_i32
    end

    # This will set this node to be open when it is shown in the viewer. By default a
    # new node is closed. Does nothing if the node is already open.
    def open_node : Nil
      unless node_open?
        switch_node_count
      end
    end

    # Closes this node.
    def close_node : Nil
      if node_open?
        switch_node_count
      end
    end

    # Returns true if this node count is greater than zero, false otherwise.
    def node_open? : Bool
      open_count > 0
    end

    # Returns an Enumerable view of the node's children.
    def children : Iterator(PDOutlineItem)
      PDOutlineItemIterator.new(first_child)
    end

    protected def set_open_count(open_count : Int32) : Nil
      cos_object.set_int(Cos::Name::COUNT, open_count)
    end

    protected def set_first_child(child : PDOutlineNode?) : Nil
      if child
        cos_object[Cos::Name::FIRST] = child.cos_object
      else
        cos_object[Cos::Name::FIRST] = Cos::Null.instance
      end
    end

    protected def set_last_child(child : PDOutlineNode?) : Nil
      if child
        cos_object[Cos::Name::LAST] = child.cos_object
      else
        cos_object[Cos::Name::LAST] = Cos::Null.instance
      end
    end

    protected def update_parent_open_count(delta : Int32) : Nil
      parent = self.parent
      return unless parent

      if cos_object == parent.cos_object
        # PDFBOX-5939: outline parent points to itself
        return
      end

      if parent.node_open?
        parent.set_open_count(parent.open_count + delta)
        parent.update_parent_open_count(delta)
      else
        parent.set_open_count(parent.open_count - delta)
      end
    end

    protected def get_outline_item(name : Cos::Name) : PDOutlineItem?
      outline = cos_object.get_dictionary(name)
      outline ? PDOutlineItem.new(outline) : nil
    end

    private def append(new_child : PDOutlineItem) : Nil
      new_child.parent = self
      if previous_last_child = last_child
        previous_last_child.next_sibling = new_child
        new_child.previous_sibling = previous_last_child
      else
        set_first_child(new_child)
      end
      set_last_child(new_child)
    end

    private def prepend(new_child : PDOutlineItem) : Nil
      new_child.parent = self
      if previous_first_child = first_child
        new_child.next_sibling = previous_first_child
        previous_first_child.previous_sibling = new_child
      else
        set_last_child(new_child)
      end
      set_first_child(new_child)
    end

    protected def update_parent_open_count_for_added_child(new_child : PDOutlineItem) : Nil
      delta = 1
      delta += new_child.open_count if new_child.node_open?
      new_child.update_parent_open_count(delta)
    end

    private def switch_node_count : Nil
      open_count = self.open_count
      set_open_count(-open_count)
      update_parent_open_count(-open_count)
    end
  end
end
