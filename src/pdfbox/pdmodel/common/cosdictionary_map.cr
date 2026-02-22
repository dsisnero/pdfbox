# This module provides dictionary mapping utilities
# that sync contents between Crystal Hashes and COSDictionaries
module Pdfbox::Pdmodel::Common
  module COSDictionaryMap
    # Convert a COSDictionary to a Hash with basic Ruby types
    # (String, Integer, Float, Bool)
    def self.convert_basic_types_to_map(dict : Cos::Dictionary?) : Hash(String, Object)?
      return if dict.nil?

      result = {} of String => Object
      dict.entries.each do |key, value|
        actual_object = case value
                        when Cos::String
                          value.value
                        when Cos::Integer
                          value.value
                        when Cos::Float
                          value.value
                        when Cos::Name
                          value.value
                        when Cos::Boolean
                          value.value
                        else
                          raise "Error: unknown type of object to convert: #{value.class}"
                        end
        result[key.value] = actual_object
      end
      result
    end

    # Convert a Hash to a COSDictionary
    def self.convert(some_map : Hash(String, _))
      dic = Cos::Dictionary.new
      some_map.each do |name, objectable|
        if objectable.responds_to?(:cos_object)
          dic[Cos::Name.new(name)] = objectable.cos_object
        else
          raise "Error: object does not respond to cos_object: #{objectable.class}"
        end
      end
      dic
    end
  end
end
