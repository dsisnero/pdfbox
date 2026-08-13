require "./pd_outline_item"

module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Outline
  # Iterator over the linked list of PDOutlineItem siblings.
  # Port of Apache PDFBox PDOutlineItemIterator.
  class PDOutlineItemIterator
    include Iterator(PDOutlineItem)

    @current_item : PDOutlineItem?
    @starting_item : PDOutlineItem?
    @done = false

    def initialize(starting_item : PDOutlineItem?)
      @starting_item = starting_item
    end

    def next
      return stop if @done

      if current = @current_item
        sibling = current.next_sibling
        if sibling.nil? || sibling == @starting_item
          @done = true
          return stop
        end

        @current_item = sibling
        return sibling
      end

      starting_item = @starting_item
      return stop unless starting_item
      @current_item = starting_item
      starting_item
    end
  end
end
