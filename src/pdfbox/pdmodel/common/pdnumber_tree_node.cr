# This class represents a PDF Number tree. See the PDF Reference 1.7 section
# 7.9.7 for more details.
#
# @param T The type of the values in this number tree.
class Pdfbox::Pdmodel::Common::PDNumberTreeNode(T)
  Log = ::Log.for(self)

  @node : Cos::Dictionary
  @converter : Proc(Cos::Base, T)
  @parent : PDNumberTreeNode(T)?

  # Constructor with converter proc.
  #
  # @param converter Proc to convert COS objects to type T
  def initialize(@converter : Proc(Cos::Base, T), @node : Cos::Dictionary = Cos::Dictionary.new)
    @parent = nil
  end

  # Constructor from existing dictionary with block.
  def self.new(dict : Cos::Dictionary, &block : Cos::Base -> T) : self
    new(block, dict)
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
  def parent : PDNumberTreeNode(T)?
    @parent
  end

  # Sets the parent to the given node.
  #
  # @param parent_node the node to be set as parent
  def parent=(parent_node : PDNumberTreeNode(T)?)
    @parent = parent_node
    calculate_limits
  end

  # Determines if this is a root node or not.
  #
  # @return true if this is a root node
  def root_node? : Bool
    @parent.nil?
  end

  # Return the children of this node.  This list will contain PDNumberTreeNode objects.
  #
  # @return The list of children or nil if there are no children.
  def kids : Common::COSArrayList(PDNumberTreeNode(T))?
    retval = nil
    kids_array = @node[Cos::Name::KIDS].as?(Cos::Array)
    if kids_array
      pd_objects = [] of PDNumberTreeNode(T)
      kids_array.items.each_with_index do |base, i|
        child_node : PDNumberTreeNode(T)
        if base.is_a?(Cos::Dictionary)
          child_node = create_child_node(base)
        else
          Log.warn { "Bad child node at position #{i}" }
          child_node = create_child_node(Cos::Dictionary.new)
        end
        pd_objects << child_node
      end
      retval = Common::COSArrayList(PDNumberTreeNode(T)).new(pd_objects, kids_array)
    end
    retval
  end

  # Set the children of this number tree.
  #
  # @param kids The children of this number tree. These have to be in sorted order. Because of
  # that, it is usually easier to call #numbers= with a map and pass a single
  # element list here.
  def kids=(kids : Enumerable(PDNumberTreeNode(T))?)
    if kids && !kids.empty?
      kids_list = kids.to_a
      first_kid = kids_list.first
      last_kid = kids_list.last
      lower_limit = first_kid.lower_limit
      set_lower_limit(lower_limit) if lower_limit
      upper_limit = last_kid.upper_limit
      set_upper_limit(upper_limit) if upper_limit
      kids_array = Cos::Array.new
      kids_list.each { |kid| kids_array.add(kid.cos_object) }
      @node[Cos::Name::KIDS] = kids_array
    elsif @node[Cos::Name::NUMS].nil?
      # Remove limits if there are no kids and no numbers set.
      @node.delete(Cos::Name::LIMITS)
      @node.delete(Cos::Name::KIDS)
    end
  end

  # Returns the value corresponding to an index in the number tree.
  #
  # @param index The index in the number tree.
  # @return The value corresponding to the index.
  def value(index : Int) : T?
    numbers_map = numbers
    if numbers_map
      return numbers_map[index]?
    end
    kids_list = kids
    if kids_list
      kids_list.size.times do |i|
        child_node = kids_list.get(i)
        lower_limit = child_node.lower_limit
        upper_limit = child_node.upper_limit
        if lower_limit && upper_limit && lower_limit <= index && upper_limit >= index
          return child_node.value(index)
        end
      end
    else
      Log.warn { "NumberTreeNode does not have \"nums\" nor \"kids\" objects." }
    end
    nil
  end

  # This will return a map of numbers on this level. The key will be a java.lang.Integer, the
  # value will depend on where this class is being used.
  #
  # @return A map of COS objects.
  def numbers : Hash(Int32, T)?
    numbers_array = @node[Cos::Name::NUMS].as?(Cos::Array)
    if numbers_array
      size = numbers_array.size
      indices = {} of Int32 => T
      if size % 2 != 0
        Log.warn { "Numbers array has odd size: #{size}" }
      end
      i = 0
      while i + 1 < size
        base = numbers_array[i]
        unless base.is_a?(Cos::Integer)
          Log.error { "page labels ignored, index #{i} should be a number, but is #{base}" }
          return
        end
        key = base.as(Cos::Integer).value.to_i32
        cos_value = numbers_array[i + 1]
        indices[key] = convert_cos_to_pd(cos_value)
        i += 2
      end
      indices
    end
  end

  # Method to convert the COS value in the number tree to the PD Model object.
  # The default implementation uses the converter proc passed in constructor.
  # Subclasses can override this method.
  #
  # @param base The COS object to convert.
  # @return The converted PD Model object.
  protected def convert_cos_to_pd(base : Cos::Base) : T
    @converter.call(base)
  end

  # Create a child node object.
  # The default implementation creates a new PDNumberTreeNode with the same converter.
  # Subclasses can override this method.
  #
  # @param dic The dictionary for the child node object to refer to.
  # @return The new child node object.
  protected def create_child_node(dic : Cos::Dictionary) : PDNumberTreeNode(T)
    self.class.new(@converter, dic)
  end

  # Set the numbers for this node. This method will set the appropriate upper and lower limits
  # based on the keys in the map and take care of the ordering.
  #
  # @param numbers The map of numbers to objects, or `nil` for nothing.
  def numbers=(numbers_hash : Hash(Int32, T)?)
    if numbers_hash.nil?
      @node.delete(Cos::Name::NUMS)
      @node.delete(Cos::Name::LIMITS)
    else
      keys = numbers_hash.keys.sort!
      array = Cos::Array.new
      keys.each do |key|
        array.add(Cos::Integer.new(key.to_i64))
        value = numbers_hash[key]
        array.add(value.nil? ? Cos::Null::INSTANCE : value.cos_object)
      end
      lower = keys.empty? ? nil : keys.first
      upper = keys.empty? ? nil : keys.last
      set_upper_limit(upper)
      set_lower_limit(lower)
      @node[Cos::Name::NUMS] = array
    end
  end

  # Get the highest value for a key in the number map.
  #
  # @return The highest value for a key in the map or nil if missing.
  def upper_limit : Int32?
    retval = nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr && arr.size > 1
      elem = arr[1]
      retval = elem.as?(Cos::Integer).try(&.value.to_i32)
    end
    retval
  end

  # Set the highest value for the key in the map.
  private def set_upper_limit(upper : Int32?) : Nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr.nil?
      arr = Cos::Array.new
      arr.add(Cos::Null::INSTANCE)
      arr.add(Cos::Null::INSTANCE)
      @node[Cos::Name::LIMITS] = arr
    end
    if upper
      arr[1] = Cos::Integer.new(upper.to_i64)
    else
      arr[1] = Cos::Null::INSTANCE
    end
  end

  # Get the lowest value for a key in the number map.
  #
  # @return The lowest value for a key in the map or nil if missing.
  def lower_limit : Int32?
    retval = nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr && arr.size > 0
      elem = arr[0]
      retval = elem.as?(Cos::Integer).try(&.value.to_i32)
    end
    retval
  end

  # Set the lowest value for the key in the map.
  private def set_lower_limit(lower : Int32?) : Nil
    arr = @node[Cos::Name::LIMITS].as?(Cos::Array)
    if arr.nil?
      arr = Cos::Array.new
      arr.add(Cos::Null::INSTANCE)
      arr.add(Cos::Null::INSTANCE)
      @node[Cos::Name::LIMITS] = arr
    end
    if lower
      arr[0] = Cos::Integer.new(lower.to_i64)
    else
      arr[0] = Cos::Null::INSTANCE
    end
  end

  private def calculate_limits : Nil
    # Not used in PDNumberTreeNode (Java doesn't have this method)
    # Limits are set automatically by set_kids and set_numbers
  end
end
