# This is an implementation of a List that will sync its contents to a COSArray
require "set"

module Pdfbox::Pdmodel::Common
  class COSArrayList(E)
    include Enumerable(E)

    @array : Cos::Array
    @actual : Array(E)
    @is_filtered : Bool = false
    @parent_dict : Cos::Dictionary?
    @dict_key : Cos::Name?

    # Default constructor
    def initialize
      @array = Cos::Array.new
      @actual = [] of E
    end

    # Create with existing List and backing COSArray
    def initialize(actual_list : Array(E), cos_array : Cos::Array)
      @actual = actual_list
      @array = cos_array

      # If sizes differ, list has been filtered
      @is_filtered = (@actual.size != @array.size)
    end

    # Constructor for lazy array creation in parent dictionary
    def initialize(dictionary : Cos::Dictionary, dictionary_key : Cos::Name)
      @array = Cos::Array.new
      @actual = [] of E
      @parent_dict = dictionary
      @dict_key = dictionary_key
    end

    # Constructor for single item that may become array
    def initialize(actual_object : E, item : Cos::Base, dictionary : Cos::Dictionary, dictionary_key : Cos::Name)
      @array = Cos::Array.new
      @array.add(item)
      @actual = [actual_object]
      @parent_dict = dictionary
      @dict_key = dictionary_key
    end

    # Convert a list of objects to a COSArray
    def self.converter_to_cos_array(cos_objectable_list : Enumerable?) : Cos::Array?
      return unless cos_objectable_list
      if cos_objectable_list.is_a?(COSArrayList)
        return cos_objectable_list.to_list
      end
      array = Cos::Array.new
      cos_objectable_list.each do |item|
        case item
        when String
          array.add(Cos::String.new(item))
        when Int32, Int64
          array.add(Cos::Integer.new(item.to_i64))
        when Float32, Float64
          array.add(Cos::Float.new(item.to_f64))
        when Nil
          array.add(Cos::Null::NULL)
        else
          if item.responds_to?(:cos_object)
            array.add(item.cos_object)
          else
            raise "Error: Don't know how to convert type to COSBase '#{item.class.name}'"
          end
        end
      end
      array
    end

    private def to_cos_object_list(list : Enumerable(E)) : Array(Cos::Base)
      result = [] of Cos::Base
      list.each do |item|
        if item.is_a?(String)
          result << Cos::String.new(item)
        elsif item.responds_to?(:cos_object)
          result << item.cos_object
        else
          raise "Cannot convert #{item.class} to COSBase"
        end
      end
      result
    end

    private def item_to_cos(item) : Cos::Base
      if item.is_a?(String)
        Cos::String.new(item)
      elsif item.responds_to?(:cos_object)
        item.cos_object
      else
        raise "Cannot convert #{item.class} to COSBase"
      end
    end

    # Size of the list
    def size : Int32
      @actual.size
    end

    # Check if empty
    def empty? : Bool
      @actual.empty?
    end

    # Check if contains object
    def contains?(o) : Bool
      @actual.includes?(o)
    end

    # Get element at index
    def get(index : Int32) : E
      @actual[index]
    end

    # Add element
    def add(o : E) : Bool
      if parent_dict = @parent_dict
        if dict_key = @dict_key
          parent_dict[dict_key] = @array
        end
        @parent_dict = nil
      end

      if o.is_a?(String)
        @array.add(Cos::String.new(o))
      elsif o.responds_to?(:cos_object)
        @array.add(o.cos_object)
      end

      @actual << o
      true
    end

    # Add all elements from collection
    def add_all(c : Enumerable(E)) : Bool
      if @is_filtered
        raise "Adding to a filtered List is not permitted"
      end
      c_array = c.to_a
      if (parent_dict = @parent_dict) && !c_array.empty?
        if dict_key = @dict_key
          parent_dict[dict_key] = @array
        end
        @parent_dict = nil
      end
      c_array.each do |o|
        if o.is_a?(String)
          @array.add(Cos::String.new(o))
        elsif o.responds_to?(:cos_object)
          @array.add(o.cos_object)
        end
      end
      @actual.concat(c_array)
      true
    end

    # Add all elements from collection at specific index
    def add_all_at_index(index : Int32, c : Enumerable(E)) : Bool
      if @is_filtered
        raise "Inserting to a filtered List is not permitted"
      end
      c_array = c.to_a
      if (parent_dict = @parent_dict) && !c_array.empty?
        if dict_key = @dict_key
          parent_dict[dict_key] = @array
        end
        @parent_dict = nil
      end
      cos_items = to_cos_object_list(c_array)
      @array.items.insert(index, *cos_items)
      @actual.insert(index, *c_array)
      true
    end

    # Remove element
    def remove(o) : Bool
      if @is_filtered
        raise "removing entries from a filtered List is not permitted"
      end

      index = @actual.index(o)
      if index
        @actual.delete_at(index)
        @array.items.delete_at(index)
        true
      else
        false
      end
    end

    # Remove element at index
    def remove(index : Int32) : E
      if @is_filtered
        raise "removing entries from a filtered List is not permitted"
      end
      @array.items.delete_at(index)
      @actual.delete_at(index)
    end

    # Remove all elements from collection
    def remove_all(c : Enumerable) : Bool
      changed = false
      c.each do |item|
        item_cos = item.responds_to?(:cos_object) ? item.cos_object : nil
        next unless item_cos
        i = @array.size - 1
        while i >= 0
          if item_cos == @array.items[i]
            @array.items.delete_at(i)
            @actual.delete_at(i)
            changed = true
          end
          i -= 1
        end
      end
      changed
    end

    # Retain only elements in collection
    def retain_all(c : Enumerable) : Bool
      # Build set of cos objects from collection
      retain_cos = Set(Cos::Base).new
      c.each do |item|
        if item.responds_to?(:cos_object)
          retain_cos.add(item.cos_object)
        end
      end
      changed = false
      i = @array.size - 1
      while i >= 0
        unless retain_cos.includes?(@array.items[i])
          @array.items.delete_at(i)
          @actual.delete_at(i)
          changed = true
        end
        i -= 1
      end
      changed
    end

    # Clear all elements
    def clear : Nil
      if parent_dict = @parent_dict
        if dict_key = @dict_key
          parent_dict[dict_key] = nil
        end
      end
      @actual.clear
      @array.clear
    end

    # Set element at index
    def set(index : Int32, element : E) : E
      if @is_filtered
        raise "Replacing an element in a filtered List is not permitted"
      end
      if element.is_a?(String)
        cos_item = Cos::String.new(element)
        if (parent_dict = @parent_dict) && index == 0
          parent_dict[dict_key] = cos_item if dict_key = @dict_key
        end
        @array.items[index] = cos_item
      elsif element.responds_to?(:cos_object)
        cos_item = element.cos_object
        if (parent_dict = @parent_dict) && index == 0
          parent_dict[dict_key] = cos_item if dict_key = @dict_key
        end
        @array.items[index] = cos_item
      else
        raise "Unsupported element type"
      end
      @actual[index] = element
    end

    # Add element at index
    def add(index : Int32, element : E) : Nil
      if @is_filtered
        raise "Adding an element in a filtered List is not permitted"
      end
      if parent_dict = @parent_dict
        if dict_key = @dict_key
          parent_dict[dict_key] = @array
        end
        @parent_dict = nil
      end
      @actual.insert(index, element)
      if element.is_a?(String)
        @array.items.insert(index, Cos::String.new(element))
      elsif element.responds_to?(:cos_object)
        @array.items.insert(index, element.cos_object)
      end
    end

    # Index of object
    def index_of(o) : Int32?
      @actual.index(o)
    end

    # Last index of object
    def last_index_of(o) : Int32?
      @actual.rindex(o)
    end

    # Sub-list view (returns a plain Array for now)
    def sub_list(from_index : Int32, to_index : Int32) : Array(E)
      @actual[from_index...to_index]
    end

    # Check if contains all elements
    def contains_all(c : Enumerable) : Bool
      c.all? { |item| @actual.includes?(item) }
    end

    # Equality
    def ==(other : self) : Bool
      @actual == other.@actual
    end

    # Hash code
    def_hash @actual

    # String representation
    def to_s(io : ::IO) : Nil
      io << "COSArrayList{"
      @array.to_s(io)
      io << "}"
    end

    # Convert to COSArray
    def to_list : Cos::Array
      @array
    end

    # Enumerable implementation
    def each(& : E ->)
      @actual.each do |item|
        yield item
      end
    end

    # Forward other Array-like methods
    def to_a : Array(E)
      @actual.dup
    end
  end
end
