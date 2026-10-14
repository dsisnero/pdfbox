# A non-terminal field in an interactive form (has children)
module Pdfbox::Pdmodel::Interactive::Form
  class PDNonTerminalField < PDField
    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    def field_type : String
      # The local /FT entry (no inheritance; Java PDNonTerminalField#getFieldType).
      @dictionary.get_name_as_string(Cos::Name.new("FT")) || ""
    end

    def value_as_string : String
      ""
    end

    def value=(value : String)
      # Java setValue(String): sets the local /V string.
      @dictionary.set_string(Cos::Name.new("V"), value)
    end

    # The local /V value, or nil (Java getValue).
    def value : Cos::Base?
      @dictionary.get_dictionary_object(Cos::Name.new("V"))
    end

    # Sets the local /V value; nil removes it (Java setValue(COSBase)).
    def value=(value : Cos::Base?) : Nil
      key = Cos::Name.new("V")
      if value
        @dictionary.set_item(key, value)
      else
        @dictionary.delete(key)
      end
    end

    # The local /DV default value, or nil (Java getDefaultValue).
    def default_value : Cos::Base?
      @dictionary.get_dictionary_object(Cos::Name.new("DV"))
    end

    # Sets the local /DV default value; nil removes it (Java setDefaultValue).
    def default_value=(value : Cos::Base?) : Nil
      key = Cos::Name.new("DV")
      if value
        @dictionary.set_item(key, value)
      else
        @dictionary.delete(key)
      end
    end

    # Sets the child fields (/Kids; Java setChildren).
    def children=(children : Array(PDField)) : Nil
      array = Cos::Array.new
      children.each { |child| array.add(child.cos_object) }
      @dictionary.set_item("Kids", array)
    end

    def widgets : Array(Annotation::PDAnnotationWidget)
      [] of Annotation::PDAnnotationWidget
    end

    # Get child fields
    def children : Array(PDField)
      kids = @dictionary[Cos::Name.new("Kids")]
      kids = kids.object if kids.is_a?(Cos::Object)
      return [] of PDField unless kids.is_a?(Cos::Array)

      result = [] of PDField
      kids.items.each do |kid|
        kid_dict = kid.is_a?(Cos::Dictionary) ? kid : (kid.is_a?(Cos::Object) ? kid.object.as?(Cos::Dictionary) : nil)
        next unless kid_dict
        field = PDFieldFactory.create_field(@acro_form, kid_dict, self)
        result << field if field
      end
      result
    end
  end
end
