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
        dest_array = page_destination.cos_object
        unless dest_array.empty?
          page = dest_array[0]?
          page = page.object if page.is_a?(Cos::Object)
          unless page.is_a?(Cos::Dictionary)
            raise ArgumentError.new("Destination of a GoTo action must be a page dictionary object")
          end
        end
      end
      cos_object[Cos::Name.new("D")] = destination.cos_object
      destination
    end
  end
end
