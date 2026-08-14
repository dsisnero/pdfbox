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

    # Java parity: hasNext() — true if the starting item exists and the current item
    # has not yet reached the end of the sibling list.
    def has_next? : Bool
      starting_item = @starting_item
      return false unless starting_item

      current = @current_item
      return true if current.nil?

      sibling = current.next_sibling
      sibling != nil && sibling != starting_item
    end

    # Java parity: remove() is not supported.
    def remove : Nil
      raise Pdfbox::Cos::UnsupportedOperationError.new("Iterator.remove() is not supported")
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
