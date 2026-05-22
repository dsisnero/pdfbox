module Xmpbox
  module Type
    class ComplexPropertyContainer
      getter properties : Array(AbstractField)

      def initialize
        @properties = [] of AbstractField
      end

      protected def first_equivalent_property(local_name : String, type : T.class) : AbstractField? forall T
        list = properties_by_local_name(local_name)
        return nil unless list
        list.each do |field|
          return field if field.is_a?(T)
        end
        nil
      end

      def add_property(obj : AbstractField) : Nil
        remove_property(obj)
        @properties << obj
      end

      def all_properties : Array(AbstractField)
        @properties
      end

      def properties_by_local_name(local_name : String) : Array(AbstractField)?
        matches = @properties.select { |field| field.property_name == local_name }
        matches.empty? ? nil : matches
      end

      def same_property?(prop1 : AbstractField, prop2 : AbstractField) : Bool
        if prop1.class == prop2.class
          pn1 = prop1.property_name
          pn2 = prop2.property_name
          if pn1.nil?
            pn2.nil?
          else
            pn1 == pn2 && prop1 == prop2
          end
        else
          false
        end
      end

      def contains_property?(property : AbstractField) : Bool
        @properties.any? { |tmp| same_property?(tmp, property) }
      end

      def remove_property(property : AbstractField) : Nil
        @properties.delete(property)
      end

      def remove_properties_by_name(local_name : String) : Nil
        return if @properties.empty?
        prop_list = properties_by_local_name(local_name)
        return unless prop_list
        prop_list.each { |prop| @properties.delete(prop) }
      end
    end
  end
end
