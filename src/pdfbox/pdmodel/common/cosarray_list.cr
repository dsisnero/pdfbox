# This is an implementation of a List that will sync its contents to a COSArray
module Pdfbox::Pdmodel::Common
  class COSArrayList(E)
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
        parent_dict[@dict_key.not_nil!] = @array
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

    # Convert to COSArray
    def to_list : Cos::Array
      @array
    end
  end
end
