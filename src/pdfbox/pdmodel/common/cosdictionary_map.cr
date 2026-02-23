# This is a Map that will automatically sync the contents to a COSDictionary.
module Pdfbox::Pdmodel::Common
  # Wrapper class that synchronizes a Hash with a COSDictionary.
  # Keys are strings, values must respond to `#cos_object`.
  class COSDictionaryMap(V)
    @map : Cos::Dictionary
    @actuals : Hash(String, V)

    # Constructor for this map.
    # @param actuals_map The map with standard crystal objects as values.
    # @param dic_map The map with COSBase objects as values.
    def initialize(actuals_map : Hash(String, V), dic_map : Cos::Dictionary)
      @actuals = actuals_map
      @map = dic_map
    end

    # Returns the size of the map.
    def size : Int32
      @map.size
    end

    # Checks if the map is empty.
    def empty? : Bool
      size == 0
    end

    # Checks if the map contains the given key.
    def has_key?(key : String) : Bool
      @actuals.has_key?(key)
    end

    def contains_key(key : String) : Bool
      has_key?(key)
    end

    def contains_value(value : V) : Bool
      has_value?(value)
    end

    # Checks if the map contains the given value.
    def has_value?(value : V) : Bool
      @actuals.has_value?(value)
    end

    # Gets the value for the given key, or nil if not present.
    def [](key : String) : V?
      @actuals[key]?
    end

    # Gets the value for the given key, raising if not present.
    def fetch(key : String) : V
      @actuals[key]
    end

    # Associates the given key with the given value.
    # The value must respond to `cos_object` (COSObjectable).
    def []=(key : String, value : V) : V
      if value.responds_to?(:cos_object)
        cos_obj = value.cos_object
        @map[Cos::Name.new(key)] = cos_obj
      else
        raise "Value must be COSObjectable (responds to #cos_object)"
      end
      @actuals[key] = value
    end

    # Removes the entry for the given key.
    def delete(key : String) : V?
      @map.delete(Cos::Name.new(key))
      @actuals.delete(key)
    end

    def get(key : String) : V?
      self[key]?
    end

    def put(key : String, value : V) : V?
      old = self[key]?
      self[key] = value
      old
    end

    def remove(key : String) : V?
      delete(key)
    end

    # Clears all entries.
    def clear : Nil
      @map.clear
      @actuals.clear
    end

    # Returns the keys as an array.
    def keys : Array(String)
      @actuals.keys
    end

    # Returns the values as an array.
    def values : Array(V)
      @actuals.values
    end

    # Returns the keys as a Set.
    def key_set : Set(String)
      Set.new(@actuals.keys)
    end

    # Returns the entries as a Set of tuples.
    def entry_set : Set({String, V})
      Set.new(@actuals.entries)
    end

    # Returns the underlying COSDictionary.
    def to_dictionary : Cos::Dictionary
      @map
    end

    # Put all entries (unsupported).
    def put_all(m : Hash(String, V)) : Nil
      raise NotImplementedError.new("Not yet implemented")
    end

    # Equality check.
    def ==(other : self) : Bool
      @map == other.@map
    end

    # Hash code.
    def_hash @map

    # This will take a COS dictionary and convert it into COSDictionaryMap.
    # All COS objects will be converted to their primitive form (String, Int64, Float64, Bool).
    # Raises if unknown type.
    def self.convert_basic_types_to_map(map : Cos::Dictionary?) : COSDictionaryMap(Bool | Int64 | Float64 | String)?
      return unless map
      actual_map = Hash(String, Bool | Int64 | Float64 | String).new
      map.entries.each do |key, cos_obj|
        actual_object = case cos_obj
                        when Cos::String
                          cos_obj.value
                        when Cos::Integer
                          cos_obj.value
                        when Cos::Name
                          cos_obj.value
                        when Cos::Float
                          cos_obj.value
                        when Cos::Boolean
                          cos_obj.value
                        else
                          raise "Error: unknown type of object to convert: #{cos_obj}"
                        end
        actual_map[key.value] = actual_object
      end
      new(actual_map, map)
    end

    # This will take a map<String, COSObjectable> and convert it into a COSDictionary.
    def self.convert(some_map : Hash(String, T)) : Cos::Dictionary forall T
      dic = Cos::Dictionary.new
      some_map.each do |name, objectable|
        if objectable.responds_to?(:cos_object)
          cos_obj = objectable.cos_object
          dic[Cos::Name.new(name)] = cos_obj
        else
          raise "Value must be COSObjectable (responds to #cos_object)"
        end
      end
      dic
    end

    # String representation
    def to_s(io : ::IO) : Nil
      io << @actuals.to_s
    end
  end
end
