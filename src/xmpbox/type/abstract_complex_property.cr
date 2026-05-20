require "./complex_property_container"

module Xmpbox
  module Type
    abstract class AbstractComplexProperty < AbstractField
      getter container : ComplexPropertyContainer
      @namespace_to_prefix : Hash(String, String)

      def initialize(metadata : XMPMetadata, property_name : String?)
        super(metadata, property_name)
        @container = ComplexPropertyContainer.new
        @namespace_to_prefix = {} of String => String
      end

      def add_namespace(namespace : String, prefix : String) : Nil
        @namespace_to_prefix[namespace] = prefix
      end

      def namespace_prefix(namespace : String) : String?
        @namespace_to_prefix[namespace]?
      end

      def all_namespaces_with_prefix : Hash(String, String)
        @namespace_to_prefix
      end

      def add_property(obj : AbstractField) : Nil
        unless self.is_a?(ArrayProperty)
          @container.remove_properties_by_name(obj.property_name.to_s)
        end
        @container.add_property(obj)
      end

      def remove_property(property : AbstractField) : Nil
        @container.remove_property(property)
      end

      def all_properties : Array(AbstractField)
        @container.all_properties
      end

      def property(field_name : String) : AbstractField?
        list = @container.properties_by_local_name(field_name)
        return nil unless list
        list.first?
      end

      def array_property(field_name : String) : ArrayProperty?
        list = @container.properties_by_local_name(field_name)
        return nil unless list
        list.first?.as?(ArrayProperty)
      end

      protected def first_equivalent_property(local_name : String, type : T.class) : AbstractField? forall T
        @container.first_equivalent_property(local_name, type)
      end
    end
  end
end
