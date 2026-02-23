# This class holds all of the name trees that are available at the document level.
require "./pdname_tree_node"
require "../interactive/document_navigation/destination/pdpage_destination"

module Pdfbox::Pdmodel::Common
  class PDDestinationNameTreeNode < PDNameTreeNode(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
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

    protected def convert_cos_to_pd(base : Cos::Base) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination
      destination = base
      if base.is_a?(Cos::Dictionary)
        # the destination is sometimes stored in the D dictionary
        # entry instead of being directly an array, so just dereference
        # it for now
        d_entry = base[Cos::Name::D]?
        destination = d_entry if d_entry
      end
      # Placeholder: create PDPageDestination with destination (could be Cos::Base)
      # For now, treat as dictionary or null
      dict = destination.is_a?(Cos::Dictionary) ? destination : Cos::Dictionary.new
      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination.new(dict)
    end

    protected def create_child_node(dic : Cos::Dictionary) : PDNameTreeNode(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
      PDDestinationNameTreeNode.new(dic)
    end
  end
end
