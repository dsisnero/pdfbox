# This class represents a node in a name tree.
#
# @param T The type of the values in this name tree.
abstract class Pdfbox::Pdmodel::Common::PDNameTreeNode(T)
  Log = ::Log.for(self)

  @node : Cos::Dictionary
  @parent : PDNameTreeNode(T)?

  # Constructor.
  def initialize
    @node = Cos::Dictionary.new
    @parent = nil
  end

  # Constructor.
  #
  # @param dict The dictionary that holds the name information.
  def initialize(dict : Cos::Dictionary)
    @node = dict
    @parent = nil
  end

  # Convert this object to a COS object.
  #
  # @return The cos object that represents this object.
  def cos_object : Cos::Dictionary
    @node
  end

  # Returns the parent node.
  #
  # @return parent node
  def parent : PDNameTreeNode(T)?
    @parent
  end

  # Sets the parent to the given node.
  #
  # @param parent_node the node to be set as parent
  def parent=(parent_node : PDNameTreeNode(T)?)
    @parent = parent_node
    calculate_limits
  end

  # Determines if this is a root node or not.
  #
  # @return true if this is a root node
  def root_node? : Bool
    @parent.nil?
  end

  # Return the children of this node.  This list will contain PDNameTreeNode objects.
  #
  # @return The list of children or nil if there are no children.
  def kids : Common::COSArrayList(PDNameTreeNode(T))?
    retval = nil
    kids_array = @node[Cos::Name::KIDS].as?(Cos::Array)
    if kids_array
      pd_objects = [] of PDNameTreeNode(T)
      kids_array.items.each_with_index do |base, i|
        child_node : PDNameTreeNode(T)
        if base.is_a?(Cos::Dictionary)
          child_node = create_child_node(base)
        else
          Log.warn { "Bad child node at position #{i}" }
          child_node = create_child_node(Cos::Dictionary.new)
        end
        pd_objects << child_node
      end
      retval = Common::COSArrayList(PDNameTreeNode(T)).new(pd_objects, kids_array)
    end
    retval
  end

  # Set the children of this named tree.
  #
  # @param kids The children of this named tree. These have to be in sorted order. Because of
  # that, it is usually easier to call #names= with a map and pass a single
  # element list here.
  def kids=(kids : Enumerable(PDNameTreeNode(T))?)
    if kids && !kids.empty?
      kids_list = kids.to_a
      kids_list.each do |kid|
        kid.parent = self
      end
      kids_array = Cos::Array.new
      kids_list.each { |kid| kids_array.add(kid.cos_object) }
      @node[Cos::Name::KIDS] = kids_array
      # root nodes with kids don't have Names
      if root_node?
        @node.delete(Cos::Name::NAMES)
      end
    else
      # remove kids
      @node.delete(Cos::Name::KIDS)
      # remove Limits
      @node.delete(Cos::Name::LIMITS)
    end
    calculate_limits
  end

  private def calculate_limits : Nil
    if root_node?
      @node.delete(Cos::Name::LIMITS)
    else
      kids_list = kids
      if kids_list && !kids_list.empty?
        first_kid = kids_list.get(0)
        last_kid = kids_list.get(kids_list.size - 1)
        lower_limit = first_kid.lower_limit
        self.lower_limit = lower_limit if lower_limit
        upper_limit = last_kid.upper_limit
        self.upper_limit = upper_limit if upper_limit
      else
        names_map = names
        if names_map && !names_map.empty?
          keys = names_map.keys.sort!
          lower_limit = keys[0]
          self.lower_limit = lower_limit
          upper_limit = keys[-1]
          self.upper_limit = upper_limit
        else
          @node.delete(Cos::Name::LIMITS)
        end
      end
    end
  end

  # The name to retrieve.
  #
  # @param name The name in the tree.
  # @return The value of the name in the tree.
  def value(name : String) : T?
    names_map = names
    if names_map
      return names_map[name]?
    end
    kids_list = kids
    if kids_list
      kids_list.size.times do |i|
        child_node = kids_list.get(i)
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

  # This will return a map of names on this level. The key will be a string,
  # and the value will depend on where this class is being used.
  #
  # @return ordered map of COS objects or `nil` if the dictionary
  # contains no 'Names' entry on this level.
  def names : Hash(String, T)?
    names_array = @node[Cos::Name::NAMES].as?(Cos::Array)
    if names_array
      size = names_array.size
      names_hash = {} of String => T
      if size % 2 != 0
        Log.warn { "Names array has odd size: #{size}" }
      end
      i = 0
      while i + 1 < size
        base = names_array[i]
        unless base.is_a?(Cos::String)
          raise "Expected string, found #{base} in name tree at index #{i}"
        end
        key = base.as(Cos::String).value
        cos_value = names_array[i + 1]
        names_hash[key] = convert_cos_to_pd(cos_value)
        i += 2
      end
      names_hash
    end
  end

  # Method to convert the COS value in the name tree to the PD Model object. The
  # default implementation will simply return the given COSBase object.
  # Subclasses should do something specific.
  #
  # @param base The COS object to convert.
  # @return The converted PD Model object.
  abstract def convert_cos_to_pd(base : Cos::Base) : T

  # Create a child node object.
  #
  # @param dic The dictionary for the child node object to refer to.
  # @return The new child node object.
  abstract def create_child_node(dic : Cos::Dictionary) : PDNameTreeNode(T)

  # Set the names for this node. This method will set the appropriate upper and lower limits
  # based on the keys in the map and take care of the ordering.
  #
  # @param names map of names to objects, or `nil` for nothing.
  def names=(names_hash : Hash(String, T)?)
    if names_hash.nil?
      @node.delete(Cos::Name::NAMES)
      @node.delete(Cos::Name::LIMITS)
    else
      array = Cos::Array.new
      keys = names_hash.keys.sort!
      keys.each do |key|
        array.add(Cos::String.new(key))
        value = names_hash[key]
        array.add(value.cos_object)
      end
      @node[Cos::Name::NAMES] = array
      calculate_limits
    end
  end

  # Get the highest value for a key in the name map.
  #
  # @return The highest value for a key in the map.
  def upper_limit : String?
    retval = nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr
      retval = arr[1]?.as?(Cos::String).try(&.value)
    end
    retval
  end

  # Set the highest value for the key in the map.
  private def upper_limit=(upper : String) : Nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr.nil?
      arr = Cos::Array.new
      arr.add(Cos::Null::INSTANCE)
      arr.add(Cos::Null::INSTANCE)
      @node[Cos::Name::LIMITS] = arr
    end
    arr[1] = Cos::String.new(upper)
  end

  # Get the lowest value for a key in the name map.
  #
  # @return The lowest value for a key in the map.
  def lower_limit : String?
    retval = nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr
      retval = arr[0]?.as?(Cos::String).try(&.value)
    end
    retval
  end

  # Set the lowest value for the key in the map.
  private def lower_limit=(lower : String) : Nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr.nil?
      arr = Cos::Array.new
      arr.add(Cos::Null::INSTANCE)
      arr.add(Cos::Null::INSTANCE)
      @node[Cos::Name::LIMITS] = arr
    end
    arr[0] = Cos::String.new(lower)
  end
end
