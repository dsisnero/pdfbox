# Port of Apache PDFBox FieldUtils.
#
# A set of utility methods to help with common AcroForm form and field related
# functions.
module Pdfbox::Pdmodel::Interactive::Form
  module FieldUtils
    # An implementation of a basic key value pair, used to help sorting the
    # content of field option entries with an array of two-element arrays as
    # used by choice fields.
    struct KeyValue
      getter key : String
      getter value : String

      def initialize(@key : String, @value : String)
      end

      def to_s(io : ::IO) : Nil
        io << "(" << @key << ", " << @value << ")"
      end
    end

    # Return two related lists as a single list with key value pairs.
    def self.to_key_value_list(keys : Array(String), values : Array(String)) : Array(KeyValue)
      list = [] of KeyValue
      keys.size.times do |i|
        list << KeyValue.new(keys[i], values[i])
      end
      list
    end

    # Sort a list of KeyValue elements by the value parameter.
    def self.sort_by_value(pairs : Array(KeyValue)) : Nil
      pairs.sort_by!(&.value)
    end

    # Sort a list of KeyValue elements by the key parameter.
    def self.sort_by_key(pairs : Array(KeyValue)) : Nil
      pairs.sort_by!(&.key)
    end

    # Return either one of a list which can have two-element arrays entries.
    #
    # Some entries in a dictionary can either be an array of elements or an
    # array of two-element arrays. This method will either return the elements
    # in the array or in case of two-element arrays, the element designated by
    # the pair index. An ArgumentError is raised if the items contain
    # two-element arrays and the index is not 0 or 1.
    def self.get_pairable_items(items : Cos::Base?, pair_index : Int32) : Array(String)
      if pair_index < 0 || pair_index > 1
        raise ArgumentError.new("Only 0 and 1 are allowed as an index into two-element arrays")
      end

      case items
      when Cos::String
        [items.value]
      when Cos::Array
        result = [] of String
        items.items.each do |entry|
          case entry
          when Cos::String
            result << entry.value
          when Cos::Array
            if entry.items.size >= pair_index + 1
              if value = entry.items[pair_index].as?(Cos::String)
                result << value.value
              end
            end
          end
        end
        result
      else
        [] of String
      end
    end
  end
end
