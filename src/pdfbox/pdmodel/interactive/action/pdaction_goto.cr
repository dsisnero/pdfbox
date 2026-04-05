module Pdfbox::Pdmodel::Interactive::Action
  class PDActionGoTo < PDAction
    SUB_TYPE = "GoTo"

    def initialize
      super()
      set_subtype(SUB_TYPE)
    end

    def initialize(dict : Cos::Dictionary)
      super(dict)
    end

    def destination : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination?
      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(cos_object[Cos::Name.new("D")]?)
    end

    def destination=(destination : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination
      if page_destination = destination.as?(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
        page = page_destination.cos_object[0]?
        if page && !page.is_a?(Cos::Dictionary) && !page.is_a?(Cos::Null)
          raise ArgumentError.new("Destination of a GoTo action must be a page dictionary object")
        end
      end
      cos_object[Cos::Name.new("D")] = destination.cos_object
      destination
    end
  end
end
