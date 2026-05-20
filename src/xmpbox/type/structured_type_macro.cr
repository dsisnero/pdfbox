require "./abstract_structured_type"

# Macro to generate structured XMP types with getter/setter properties.
# Each property is defined as {constant_name, local_name, crystal_type, xmp_type}
# The structured_type_info class method returns {namespace, prefered_prefix}
macro define_structured_type(class_name, namespace, prefered_prefix, *properties)
  module Xmpbox
    module Type
      class {{class_name}} < AbstractStructuredType
        {% for prop in properties %}
          {{prop[0].id}} = {{prop[1]}}
        {% end %}

        def self.structured_type_info : NamedTuple(namespace: String, prefered_prefix: String)?
          {namespace: {{namespace}}, prefered_prefix: {{prefered_prefix}}}
        end

        def initialize(metadata : XMPMetadata)
          super(metadata)
          add_namespace(get_namespace, prefered_prefix)
        end

        {% for prop in properties %}
          # Getter for {{prop[1].id}}
          def {{prop[0].id.underscore.id}} : {{prop[2].id}}?
            abs_prop = first_equivalent_property({{prop[1].id}}, {{prop[3].id}})
            return nil unless abs_prop
            value = abs_prop.as({{prop[3].id}}).value
            {% if prop[2] == "String" && prop[3] != "TextType" %}
              value.as?(String)
            {% else %}
              value
            {% end %}
          end

          # Setter for {{prop[1].id}}
          def {{prop[0].id.underscore.id}}=(val : {{prop[2].id}}) : Nil
            add_simple_property({{prop[1].id}}, val)
          end
        {% end %}
      end
    end
  end
end
