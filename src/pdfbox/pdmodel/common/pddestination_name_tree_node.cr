# This class holds the destination name tree available at the document level.
#
# Java `PDDestinationNameTreeNode extends PDNameTreeNode<PDPageDestination>`.
# It is implemented here as a standalone class rather than on the generic
# `PDNameTreeNode(T)` base: parameterising that base with `PDPageDestination`
# (a type with concrete subclasses) triggers a Crystal codegen internal error
# in the base `names` body ("BUG: no target defs"). The observable behavior
# mirrors the Java name-tree node.
require "../interactive/document_navigation/destination/pddestination"
require "../interactive/document_navigation/destination/pdpage_destination"

module Pdfbox::Pdmodel::Common
  class PDDestinationNameTreeNode
    Log = ::Log.for(self)

    @node : Cos::Dictionary
    @parent : PDDestinationNameTreeNode?

    # Constructor.
    def initialize
      @node = Cos::Dictionary.new
      @parent = nil
    end

    # Constructor.
    #
    # @param dic The COS dictionary.
    def initialize(dic : Cos::Dictionary)
      @node = dic
      @parent = nil
    end

    # Convert this object to a COS object.
    def cos_object : Cos::Dictionary
      @node
    end

    # Returns the parent node.
    def parent : PDDestinationNameTreeNode?
      @parent
    end

    # Sets the parent to the given node.
    def parent=(parent_node : PDDestinationNameTreeNode?) : PDDestinationNameTreeNode?
      @parent = parent_node
      parent_node
    end

    # Determines if this is a root node.
    def root_node? : Bool
      @parent.nil?
    end

    # Return the children of this node.
    def kids : Array(PDDestinationNameTreeNode)?
      kids_array = @node[Cos::Name::KIDS]?
      kids_array = kids_array.object if kids_array.is_a?(Cos::Object)
      kids_array = kids_array.as?(Cos::Array)
      return unless kids_array

      result = [] of PDDestinationNameTreeNode
      kids_array.items.each do |item|
        item = item.object if item.is_a?(Cos::Object)
        if item.is_a?(Cos::Dictionary)
          result << PDDestinationNameTreeNode.new(item)
        else
          result << PDDestinationNameTreeNode.new(Cos::Dictionary.new)
        end
      end
      result
    end

    # The name to retrieve.
    #
    # @param name The name in the tree.
    # @return The value of the name in the tree.
    def value(name : String) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination?
      names_map = names
      if names_map
        return names_map[name]?
      end

      kids_list = kids
      if kids_list
        kids_list.each do |child_node|
          upper_limit = child_node.upper_limit
          lower_limit = child_node.lower_limit
          if upper_limit.nil? || lower_limit.nil? ||
             upper_limit < lower_limit ||
             (lower_limit <= name && upper_limit >= name)
            return child_node.value(name)
          end
        end
      else
        Log.warn { "NameTreeNode does not have \"names\" nor \"kids\" objects." }
      end
      nil
    end

    # Return a map of names on this level.
    #
    # @return ordered map of destinations or `nil` if the dictionary contains
    #   no 'Names' entry on this level.
    def names : Hash(String, Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)?
      names_value = @node[Cos::Name::NAMES]?
      names_value = names_value.object if names_value.is_a?(Cos::Object)
      names_array = names_value.as?(Cos::Array)
      return unless names_array

      result = {} of String => Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination
      i = 0
      size = names_array.size
      while i + 1 < size
        key_item = names_array[i]
        key_item = key_item.object if key_item.is_a?(Cos::Object)
        unless key_item.is_a?(Cos::String)
          raise "Expected string, found #{key_item} in name tree at index #{i}"
        end
        value = names_array[i + 1]
        value = value.object if value.is_a?(Cos::Object)
        result[key_item.value] = convert_cos_to_pd(value) if value
        i += 2
      end
      result
    end

    # Get the highest value for a key in the name map.
    def upper_limit : String?
      arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
      arr ? arr[1]?.as?(Cos::String).try(&.value) : nil
    end

    # Get the lowest value for a key in the name map.
    def lower_limit : String?
      arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
      arr ? arr[0]?.as?(Cos::String).try(&.value) : nil
    end

    # Java PDDestinationNameTreeNode#convertCOSToPD.
    #
    # Returns an empty page destination for an entry that is not a page
    # destination (PDFBOX-5975); the Java implementation returns null, but the
    # Crystal value type is non-nil.
    protected def convert_cos_to_pd(base : Cos::Base) : Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination
      destination = base
      if base.is_a?(Cos::Dictionary)
        # the destination is sometimes stored in the D dictionary entry
        # instead of being directly an array, so dereference it for now
        d_entry = base.get_dictionary_object(Cos::Name.new("D"))
        destination = d_entry if d_entry
      end
      dest = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(destination)
      if dest.is_a?(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
        return dest
      end
      # PDFBOX-5975: invalid tree entry
      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination.new
    end
  end
end
