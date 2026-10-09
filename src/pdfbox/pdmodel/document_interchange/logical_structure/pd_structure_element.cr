module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  class PDStructureElement
    TYPE = "StructElem"

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize(structure_type : String, parent : self?)
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name("Type", TYPE)
      self.structure_type = structure_type
      self.parent = parent
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def type : String?
      read_name("Type")
    end

    # The page this structure element belongs to (/Pg), if any. Java
    # PDStructureElement#getPage.
    def page : Pdfbox::Pdmodel::Page?
      page_dict = @dictionary.get_dictionary(Pdfbox::Cos::Name::PG)
      page_dict ? Pdfbox::Pdmodel::Page.new(page_dict) : nil
    end

    def structure_type : String?
      read_name("S")
    end

    def structure_type=(structure_type : String) : String
      @dictionary.set_name("S", structure_type)
      structure_type
    end

    def parent : self?
      value = @dictionary[Pdfbox::Cos::Name.new("P")]
      return unless value.is_a?(Pdfbox::Cos::Dictionary)
      self.class.new(value)
    end

    def parent=(parent : self?) : self?
      if parent
        @dictionary.set_item("P", parent.cos_object)
      else
        @dictionary.delete(Pdfbox::Cos::Name.new("P"))
      end
      parent
    end

    def element_identifier : String?
      read_string("ID")
    end

    def element_identifier=(id : String) : String
      @dictionary.set_string("ID", id)
      id
    end

    def revision_number : Int32
      read_int("R", 0)
    end

    def revision_number=(revision_number : Int32 | Int64 | Int) : Int32
      value = revision_number.to_i32
      if value < 0
        raise ArgumentError.new("The revision number shall be > -1")
      end
      @dictionary.set_int("R", value)
      value
    end

    def increment_revision_number : Int32
      self.revision_number = revision_number + 1
    end

    def title : String?
      read_string("T")
    end

    def title=(title : String) : String
      @dictionary.set_string("T", title)
      title
    end

    def language : String?
      read_string("Lang")
    end

    def language=(language : String) : String
      @dictionary.set_string("Lang", language)
      language
    end

    def alternate_description : String?
      read_string("Alt")
    end

    def alternate_description=(description : String) : String
      @dictionary.set_string("Alt", description)
      description
    end

    def actual_text : String?
      read_string("ActualText")
    end

    def actual_text=(actual_text : String) : String
      @dictionary.set_string("ActualText", actual_text)
      actual_text
    end

    def expanded_form : String?
      read_string("E")
    end

    def expanded_form=(expanded_form : String) : String
      @dictionary.set_string("E", expanded_form)
      expanded_form
    end

    def append_kid(kid : Int32 | Int64 | Int) : Nil
      mcid = kid.to_i32
      if mcid < 0
        raise ArgumentError.new("MCID should not be negative")
      end
      append_kid_base(Pdfbox::Cos::Integer.get(mcid.to_i64))
    end

    def append_kid(marked_content : DocumentInterchange::MarkedContent::PDMarkedContent) : Nil
      mcid = marked_content.mcid
      if mcid < 0
        raise ArgumentError.new("MCID is negative or doesn't exist")
      end
      append_kid_base(Pdfbox::Cos::Integer.get(mcid.to_i64))
    end

    def append_kid(marked_content_reference : PDMarkedContentReference) : Nil
      append_kid_base(marked_content_reference.cos_object)
    end

    def kids : Array(Int32 | PDMarkedContentReference | self)
      kid_objects = [] of Int32 | PDMarkedContentReference | self
      k = @dictionary[Pdfbox::Cos::Name.new("K")]
      return kid_objects unless k

      if k.is_a?(Pdfbox::Cos::Array)
        k.items.each do |item|
          kid = create_kid(item)
          kid_objects << kid if kid
        end
      else
        kid = create_kid(k)
        kid_objects << kid if kid
      end
      kid_objects
    end

    # Returns the attributes together with their revision numbers (A).
    # Java PDStructureElement#getAttributes.
    def attributes : Revisions(PDAttributeObject)
      revisions = Revisions(PDAttributeObject).new
      a = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("A"))
      if a.is_a?(Pdfbox::Cos::Array)
        array = a
        attribute_object = nil.as(PDAttributeObject?)
        array.items.each do |item|
          item = item.object if item.is_a?(Pdfbox::Cos::Object)
          if item.is_a?(Pdfbox::Cos::Dictionary)
            attribute_object = PDAttributeObject.create(item)
            attribute_object.structure_element = self
            revisions.add_object(attribute_object, 0)
          elsif item.is_a?(Pdfbox::Cos::Integer)
            if attribute_object
              revisions.set_revision_number(attribute_object, item.value.to_i32)
            end
          end
        end
      end
      if a.is_a?(Pdfbox::Cos::Dictionary)
        attribute_object = PDAttributeObject.create(a)
        attribute_object.structure_element = self
        revisions.add_object(attribute_object, 0)
      end
      revisions
    end

    # Sets the attributes together with their revision numbers (A).
    # Java PDStructureElement#setAttributes.
    def attributes=(revisions : Revisions(PDAttributeObject)) : Nil
      key = Pdfbox::Cos::Name.new("A")
      if revisions.size == 1 && revisions.get_revision_number(0) == 0
        attribute_object = revisions.get_object(0)
        attribute_object.structure_element = self
        @dictionary.set_item(key, attribute_object.cos_object)
        return
      end
      array = Pdfbox::Cos::Array.new
      revisions.size.times do |i|
        attribute_object = revisions.get_object(i)
        attribute_object.structure_element = self
        revision_number = revisions.get_revision_number(i)
        if revision_number < 0
          raise ArgumentError.new("The revision number shall be > -1")
        end
        array.add(attribute_object.cos_object)
        array.add(Pdfbox::Cos::Integer.get(revision_number.to_i64))
      end
      @dictionary.set_item(key, array)
    end

    # Returns the class names together with their revision numbers (C).
    # Java PDStructureElement#getClassNames.
    def class_names : Revisions(String)
      class_names = Revisions(String).new
      c = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("C"))
      if c.is_a?(Pdfbox::Cos::Name)
        class_names.add_object(c.value, 0)
      end
      if c.is_a?(Pdfbox::Cos::Array)
        array = c
        class_name = nil.as(String?)
        array.items.each do |item|
          item = item.object if item.is_a?(Pdfbox::Cos::Object)
          if item.is_a?(Pdfbox::Cos::Name)
            class_name = item.value
            class_names.add_object(class_name, 0)
          elsif item.is_a?(Pdfbox::Cos::Integer)
            if class_name
              class_names.set_revision_number(class_name, item.value.to_i32)
            end
          end
        end
      end
      class_names
    end

    # Notifies the structure element that an attribute object changed.
    # Java PDStructureElement#attributeChanged.
    def attribute_changed(attribute_object : PDAttributeObject) : Nil
      key = Pdfbox::Cos::Name.new("A")
      a = @dictionary.get_dictionary_object(key)
      if a.is_a?(Pdfbox::Cos::Array)
        array = a
        array.items.each_with_index do |entry, i|
          entry = entry.object if entry.is_a?(Pdfbox::Cos::Object)
          if entry == attribute_object.cos_object
            next_base = array.items[i + 1]?
            if next_base.is_a?(Pdfbox::Cos::Integer)
              array.items[i + 1] = Pdfbox::Cos::Integer.get(revision_number.to_i64)
            end
          end
        end
      else
        array = Pdfbox::Cos::Array.new
        array.add(a) if a
        array.add(Pdfbox::Cos::Integer.get(revision_number.to_i64))
        @dictionary.set_item(key, array)
      end
    end

    private def append_kid_base(object : Pdfbox::Cos::Base) : Nil
      k = @dictionary[Pdfbox::Cos::Name.new("K")]
      if k.nil?
        @dictionary.set_item("K", object)
      elsif k.is_a?(Pdfbox::Cos::Array)
        k.add(object)
      else
        @dictionary.set_item("K", Pdfbox::Cos::Array.new([k, object]))
      end
    end

    private def create_kid(kid : Pdfbox::Cos::Base) : Int32 | PDMarkedContentReference | self | Nil
      if kid.is_a?(Pdfbox::Cos::Integer)
        return kid.value.to_i32
      end
      return unless kid.is_a?(Pdfbox::Cos::Dictionary)

      type = kid[Pdfbox::Cos::Name.new("Type")]
      type_string = type.as?(Pdfbox::Cos::Name).try(&.value)
      return self.class.new(kid) if type_string.nil? || type_string == TYPE
      return PDMarkedContentReference.new(kid) if type_string == PDMarkedContentReference::TYPE
      nil
    end

    private def read_name(key : String) : String?
      value = @dictionary[Pdfbox::Cos::Name.new(key)]
      value.as?(Pdfbox::Cos::Name).try(&.value)
    end

    private def read_string(key : String) : String?
      value = @dictionary[Pdfbox::Cos::Name.new(key)]
      value.as?(Pdfbox::Cos::String).try(&.value)
    end

    private def read_int(key : String, default : Int32) : Int32
      value = @dictionary[Pdfbox::Cos::Name.new(key)]
      value.as?(Pdfbox::Cos::Integer).try(&.value.to_i32) || default
    end
  end
end
