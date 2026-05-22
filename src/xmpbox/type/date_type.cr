require "../date_converter"

module Xmpbox
  module Type
    class DateType < AbstractSimpleProperty
      @date_value : Time?

      def initialize(metadata : XMPMetadata, namespace_uri : String?, prefix_str : String?,
                     property_name : String?, value : ValueType)
        super(metadata, namespace_uri, prefix_str, property_name, value)
      end

      private def value_from_calendar(value : Time) : Nil
        @date_value = value
      end

      def value : Time?
        @date_value
      end

      private def good_type?(value : ValueType) : Bool
        case value
        when Time
          true
        when String
          begin
            Xmpbox::DateConverter.to_calendar(value)
            true
          rescue ex
            false
          end
        else
          false
        end
      end

      def value=(value : ValueType) : Nil
        unless good_type?(value)
          if value.nil?
            raise ArgumentError.new("Value null is not allowed for the Date type")
          end
          raise ArgumentError.new("Value given is not allowed for the Date type: #{value.class}, value: #{value}")
        end

        case value
        when String
          set_value_from_string(value)
        when Time
          value_from_calendar(value)
        end
      end

      def string_value : String?
        if dv = @date_value
          Xmpbox::DateConverter.to_iso8601(dv)
        end
      end

      private def set_value_from_string(value : String) : Nil
        cal = Xmpbox::DateConverter.to_calendar(value)
        if cal
          value_from_calendar(cal)
        end
      end
    end
  end
end
