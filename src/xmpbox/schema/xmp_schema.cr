require "../type/abstract_structured_type"
require "../type/array_property"
require "../type/cardinality"
require "../type/text_type"
require "../type/date_type"
require "../type/boolean_type"
require "../type/integer_type"
require "../type/real_type"
require "../type/bad_field_value_exception"
require "../xmp_constants"

module Xmpbox
  module Schema
    class XmpSchemaException < Exception
      def initialize(message : String, cause : Exception? = nil)
        super(message, cause: cause)
      end
    end

    class XMPSchema < Type::AbstractStructuredType
      def initialize(metadata : XMPMetadata, namespace_uri : String? = nil, prefix : String? = nil, name : String? = nil)
        super(metadata, namespace_uri, prefix, name)
        if ns = self.namespace
          add_namespace(ns, self.prefix || "")
        end
      end

      def abstract_property(qualified_name : String) : Type::AbstractField?
        container.all_properties.each do |child|
          return child if child.property_name == qualified_name
        end
        nil
      end

      def about_attribute : Type::Attribute?
        attribute(XmpConstants::ABOUT_NAME)
      end

      def about_value : String?
        prop = attribute(XmpConstants::ABOUT_NAME)
        prop ? prop.value : ""
      end

      def about=(attr : Type::Attribute) : Nil
        if attr.ns_uri == XmpConstants::RDF_NAMESPACE && attr.name == XmpConstants::ABOUT_NAME
          self.attribute = attr
        else
          raise Type::BadFieldValueException.new("Attribute 'about' must be named 'rdf:about' or 'about'")
        end
      end

      # Port of Java setAboutAsSimple
      def set_about_as_simple(about : String?) : Nil
        if about.nil?
          remove_attribute(XmpConstants::ABOUT_NAME)
        else
          self.attribute = Type::Attribute.new(XmpConstants::RDF_NAMESPACE, XmpConstants::ABOUT_NAME, about)
        end
      end

      # Text property accessors
      def text_property=(prop : Type::TextType) : Nil
        set_specified_simple_type_property(prop)
      end

      def set_text_property_value(qualified_name : String, property_value : String?) : Nil
        set_specified_simple_type_property(Type::Types::Text, qualified_name, property_value)
      end

      def unqualified_text_property(name : String) : Type::TextType?
        prop = abstract_property(name)
        if prop
          if prop.is_a?(Type::TextType)
            return prop
          end
          raise Type::BadFieldValueException.new("Property asked is not a Text Property")
        end
        nil
      end

      def unqualified_text_property_value(name : String) : String?
        tt = unqualified_text_property(name)
        tt.try(&.string_value)
      end

      # Date property accessors
      def date_property=(prop : Type::DateType) : Nil
        set_specified_simple_type_property(prop)
      end

      def date_property(qualified_name : String) : Type::DateType?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::DateType)
            return prop
          end
          raise Type::BadFieldValueException.new("Property asked is not a Date Property")
        end
        nil
      end

      def date_property_value(qualified_name : String) : Time?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::DateType)
            return prop.value
          end
          raise Type::BadFieldValueException.new("Property asked is not a Date Property")
        end
        nil
      end

      def set_date_property_value(qualified_name : String, date : Time?) : Nil
        set_specified_simple_type_property(Type::Types::Date, qualified_name, date)
      end

      # Boolean property accessors
      def boolean_property=(prop : Type::BooleanType) : Nil
        set_specified_simple_type_property(prop)
      end

      def boolean_property(qualified_name : String) : Type::BooleanType?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::BooleanType)
            return prop
          end
          raise Type::BadFieldValueException.new("Property asked is not a Boolean Property")
        end
        nil
      end

      def boolean_property_value(qualified_name : String) : Bool?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::BooleanType)
            return prop.value
          end
          raise Type::BadFieldValueException.new("Property asked is not a Boolean Property")
        end
        nil
      end

      def set_boolean_property_value(qualified_name : String, bool : Bool?) : Nil
        set_specified_simple_type_property(Type::Types::Boolean, qualified_name, bool)
      end

      # Integer property accessors
      def integer_property=(prop : Type::IntegerType) : Nil
        set_specified_simple_type_property(prop)
      end

      def integer_property(qualified_name : String) : Type::IntegerType?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::IntegerType)
            return prop
          end
          raise Type::BadFieldValueException.new("Property asked is not an Integer Property")
        end
        nil
      end

      def integer_property_value(qualified_name : String) : Int32?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::IntegerType)
            return prop.value
          end
          raise Type::BadFieldValueException.new("Property asked is not an Integer Property")
        end
        nil
      end

      def set_integer_property_value(qualified_name : String, int_value : Int32?) : Nil
        set_specified_simple_type_property(Type::Types::Integer, qualified_name, int_value)
      end

      # Real property accessors
      def real_property_value(qualified_name : String) : Float64?
        prop = abstract_property(qualified_name)
        if prop
          if prop.is_a?(Type::RealType)
            return prop.value
          end
          raise Type::BadFieldValueException.new("Property asked is not a Real Property")
        end
        nil
      end

      def set_real_property_value(qualified_name : String, real_value : Float64?) : Nil
        set_specified_simple_type_property(Type::Types::Real, qualified_name, real_value)
      end

      # Bag operations
      def add_bag_value(bag_name : String, bag_value : Type::TextType) : Nil
        internal_add_bag_value_with_type(bag_name, bag_value)
      end

      def add_qualified_bag_value(simple_name : String, bag_value : String) : Nil
        internal_add_bag_value(simple_name, bag_value)
      end

      def unqualified_bag_value_list(bag_name : String) : Array(String)?
        abstract_prop = abstract_property(bag_name)
        if abstract_prop.is_a?(Type::ArrayProperty)
          return abstract_prop.elements_as_string
        end
        nil
      end

      def remove_unqualified_bag_value(bag_name : String, bag_value : String) : Nil
        remove_unqualified_array_value(bag_name, bag_value)
      end

      # Sequence operations
      def add_unqualified_sequence_value(simple_seq_name : String, seq_value : String) : Nil
        seq = abstract_property(simple_seq_name)
        li = create_text_type(XmpConstants::LIST_NAME, seq_value)
        if seq.is_a?(Type::ArrayProperty)
          seq.container.add_property(li)
        else
          new_seq = create_array_property(simple_seq_name, Type::Cardinality::Seq)
          new_seq.container.add_property(li)
          add_property(new_seq)
        end
      end

      def unqualified_sequence_value_list(seq_name : String) : Array(String)?
        abstract_prop = abstract_property(seq_name)
        if abstract_prop.is_a?(Type::ArrayProperty)
          return abstract_prop.elements_as_string
        end
        nil
      end

      def remove_unqualified_sequence_value(qualified_seq_name : String, seq_value : String) : Nil
        remove_unqualified_array_value(qualified_seq_name, seq_value)
      end

      # Language alternatives
      def set_unqualified_language_property_value(name : String, language : String?, value : String?) : Nil
        lang = language.try(&.empty?) ? XmpConstants::X_DEFAULT : (language || XmpConstants::X_DEFAULT)
        property = abstract_property(name)

        if property.is_a?(Type::ArrayProperty)
          array_prop = property
          array_prop.container.all_properties.each do |child|
            if child.attribute(XmpConstants::LANG_NAME).try(&.value) == lang
              array_prop.container.remove_property(child)
              unless value.nil?
                lang_value = create_text_type(XmpConstants::LIST_NAME, value.as(String))
                lang_value.attribute = Type::Attribute.new("http://www.w3.org/XML/1998/namespace", XmpConstants::LANG_NAME, lang)
                array_prop.container.add_property(lang_value)
              end
              reorganize_alt_order(array_prop.container)
              return
            end
          end
          if value
            lang_value = create_text_type(XmpConstants::LIST_NAME, value)
            lang_value.attribute = Type::Attribute.new("http://www.w3.org/XML/1998/namespace", XmpConstants::LANG_NAME, lang)
            array_prop.container.add_property(lang_value)
            reorganize_alt_order(array_prop.container)
          end
        else
          return if value.nil?
          array_prop = create_array_property(name, Type::Cardinality::Alt)
          lang_value = create_text_type(XmpConstants::LIST_NAME, value.as(String))
          lang_value.attribute = Type::Attribute.new("http://www.w3.org/XML/1998/namespace", XmpConstants::LANG_NAME, lang)
          array_prop.container.add_property(lang_value)
          add_property(array_prop)
        end
      end

      def unqualified_language_property_value(name : String, expected_language : String?) : String?
        language = expected_language || XmpConstants::X_DEFAULT
        property = abstract_property(name)
        if property
          if property.is_a?(Type::ArrayProperty)
            property.container.all_properties.each do |child|
              text = child.attribute(XmpConstants::LANG_NAME)
              if text && text.value == language
                return child.as(Type::TextType).string_value
              end
            end
            return nil
          end
          raise Type::BadFieldValueException.new("The property '#{name}' is not of Lang Alt type")
        end
        nil
      end

      def unqualified_language_property_languages_value(name : String) : Array(String)?
        property = abstract_property(name)
        return nil unless property
        if property.is_a?(Type::ArrayProperty)
          langs = [] of String
          property.container.all_properties.each do |child|
            if lang_attr = child.attribute(XmpConstants::LANG_NAME)
              langs << lang_attr.value
            end
          end
          langs
        end
      end

      def merge(other : XMPSchema) : Nil
        unless other.class == self.class
          raise IO::Error.new("Can only merge schemas of the same type.")
        end
        other.all_attributes.each do |att|
          self.attribute = att if att.ns_uri == namespace
        end
        other.container.all_properties.each do |child|
          if child.prefix == prefix
            if child.is_a?(Type::ArrayProperty)
              all_properties.each do |tmp|
                if tmp.is_a?(Type::ArrayProperty) && tmp.property_name == child.property_name
                  child.container.all_properties.each do |new_val|
                    found = false
                    tmp.as(Type::ArrayProperty).container.all_properties.each do |old_val|
                      if old_val.is_a?(Type::TextType) && new_val.is_a?(Type::TextType) &&
                         old_val.string_value == new_val.string_value
                        found = true
                        break
                      end
                    end
                    tmp.as(Type::ArrayProperty).container.add_property(new_val) unless found
                  end
                end
              end
            else
              add_property(child)
            end
          end
        end
      end

      private def set_specified_simple_type_property(type : Type::Types, qualified_name : String, property_value : ValueType?) : Nil
        if property_value.nil?
          container.all_properties.each do |child|
            if child.property_name == qualified_name
              container.remove_property(child)
              return
            end
          end
        else
          tm = metadata.type_mapping
          specified = tm.instanciate_simple_property(nil, prefix, qualified_name, property_value, type)
          container.all_properties.each do |child|
            if child.property_name == qualified_name
              remove_property(child)
              add_property(specified)
              return
            end
          end
          add_property(specified)
        end
      end

      private def set_specified_simple_type_property(prop : Type::AbstractSimpleProperty) : Nil
        container.all_properties.each do |child|
          if child.property_name == prop.property_name
            remove_property(child)
            add_property(prop)
            return
          end
        end
        add_property(prop)
      end

      private def internal_add_bag_value(qualified_bag_name : String, bag_value : String) : Nil
        bag = abstract_property(qualified_bag_name)
        li = create_text_type(XmpConstants::LIST_NAME, bag_value)
        if bag.is_a?(Type::ArrayProperty)
          bag.container.add_property(li)
        else
          new_bag = create_array_property(qualified_bag_name, Type::Cardinality::Bag)
          new_bag.container.add_property(li)
          add_property(new_bag)
        end
      end

      private def internal_add_bag_value_with_type(qualified_bag_name : String, text_type : Type::TextType) : Nil
        bag = abstract_property(qualified_bag_name)
        if bag.is_a?(Type::ArrayProperty)
          bag.container.add_property(text_type)
        else
          new_bag = create_array_property(qualified_bag_name, Type::Cardinality::Bag)
          new_bag.container.add_property(text_type)
          add_property(new_bag)
        end
      end

      private def remove_unqualified_array_value(array_name : String, field_value : String) : Nil
        abstract_prop = abstract_property(array_name)
        return unless abstract_prop.is_a?(Type::ArrayProperty)
        array = abstract_prop.as(Type::ArrayProperty)
        to_delete = [] of Type::AbstractField
        array.container.all_properties.each do |field|
          if field.is_a?(Type::AbstractSimpleProperty) && field.string_value == field_value
            to_delete << field
          end
        end
        to_delete.each { |field| array.container.remove_property(field) }
      end

      private def reorganize_alt_order(alt : Type::ComplexPropertyContainer) : Nil
        props = alt.all_properties
        return if props.empty?
        first = props.first
        if first.attribute(XmpConstants::LANG_NAME).try(&.value) == XmpConstants::X_DEFAULT
          return
        end
        xdefault = props.find { |prop| prop.attribute(XmpConstants::LANG_NAME).try(&.value) == XmpConstants::X_DEFAULT }
        return unless xdefault
        alt.remove_property(xdefault)
        reordered = [xdefault] + alt.all_properties
        reordered.each { |prop| alt.remove_property(prop) }
        reordered.each { |prop| alt.add_property(prop) }
      end
    end
  end
end
