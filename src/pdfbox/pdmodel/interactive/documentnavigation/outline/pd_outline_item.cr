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

    # Returns the destination of this item (Java PDOutlineItem#getDestination).
    def destination : Destination::PDDestination?
      value = cos_object[Cos::Name.new("Dest")]?
      value = value.object if value.is_a?(Cos::Object)
      Destination::PDDestination.create(value)
    end

    # Sets the destination of this item.
    def destination=(dest : Destination::PDDestination?) : Nil
      cos_object[Cos::Name.new("Dest")] = dest ? dest.cos_object : Cos::Null.instance
    end

    # Returns the action of this node (Java PDOutlineItem#getAction).
    def action : Action::PDAction?
      value = cos_object[Cos::Name.new("A")]?
      value = value.object if value.is_a?(Cos::Object)
      Action::PDActionFactory.create_action(value.as?(Cos::Dictionary))
    end

    # Sets the action of this node.
    def action=(action : Action::PDAction?) : Nil
      cos_object[Cos::Name.new("A")] = action ? action.cos_object : Cos::Null.instance
    end

    # Returns the structure element of this node (Java PDOutlineItem#getStructureElement).
    def structure_element : Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement?
      dict = cos_object.get_dictionary(Cos::Name.new("SE"))
      dict ? Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(dict) : nil
    end

    # Sets the structure element of this node.
    def structure_element=(element : Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement?) : Nil
      cos_object[Cos::Name.new("SE")] = element ? element.cos_object : Cos::Null.instance
    end

    # Returns the RGB text color of this node. Default is black; never nil.
    # Java PDOutlineItem#getTextColor.
    def text_color : Pdfbox::Pdmodel::Graphics::Color::PDColor
      values = cos_object.get_array(Cos::Name.new("C"))
      unless values
        values = Cos::Array.new
        values.grow_to_size(3, Cos::Float.new(0.0))
        cos_object[Cos::Name.new("C")] = values
      end
      Pdfbox::Pdmodel::Graphics::Color::PDColor.new(values, Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    end

    # Sets the RGB text color of this node.
    def text_color=(color : Pdfbox::Pdmodel::Graphics::Color::PDColor) : Nil
      cos_object[Cos::Name.new("C")] = color.to_cos_array
    end

    # Finds the page this outline item points to, following a GoTo action or a
    # named destination when there is no direct destination.
    # Java PDOutlineItem#findDestinationPage.
    def find_destination_page(document : Pdfbox::Pdmodel::Document) : Pdfbox::Pdmodel::Page?
      dest = destination
      if dest.nil?
        outline_action = action
        dest = outline_action.destination if outline_action.is_a?(Action::PDActionGoTo)
      end
      return nil if dest.nil?

      page_destination = case dest
                         when Destination::PDNamedDestination
                           document.document_catalog.try(&.find_named_destination_page(dest))
                         when Destination::PDPageDestination
                           dest
                         else
                           raise ::IO::Error.new("Error: Unknown destination type #{dest.class}")
                         end
      return nil unless page_destination

      page = page_destination.page
      return Pdfbox::Pdmodel::Page.new(page) if page

      page_number = page_destination.page_number
      return nil if page_number == -1

      begin
        document.get_page(page_number)
      rescue IndexError
        nil
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
