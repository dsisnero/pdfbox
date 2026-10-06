module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # A root of a structure tree (Java PDStructureTreeRoot).
  class PDStructureTreeRoot
    TYPE = "StructTreeRoot"

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name("Type", TYPE)
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    # Returns the K entry (a structure element dictionary, an array of them,
    # or a number). Java PDStructureTreeRoot#getK.
    def k : Pdfbox::Cos::Base?
      value = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("K"))
      value
    end

    def k=(value : Pdfbox::Cos::Base?) : Nil
      if value
        @dictionary.set_item(Pdfbox::Cos::Name.new("K"), value)
      else
        @dictionary.delete(Pdfbox::Cos::Name.new("K"))
      end
    end

    # Returns the ClassMap. The elements are either PDAttributeObject or
    # arrays of it. Java PDStructureTreeRoot#getClassMap.
    def class_map : Hash(String, PDAttributeObject | Array(PDAttributeObject))
      class_map = {} of String => PDAttributeObject | Array(PDAttributeObject)
      class_map_dictionary = @dictionary.get_dictionary(Pdfbox::Cos::Name.new("ClassMap"))
      return class_map unless class_map_dictionary

      class_map_dictionary.entries.each do |name, base|
        base = base.object if base.is_a?(Pdfbox::Cos::Object)
        if base.is_a?(Pdfbox::Cos::Dictionary)
          class_map[name.value] = PDAttributeObject.create(base)
        elsif base.is_a?(Pdfbox::Cos::Array)
          array = base
          list = [] of PDAttributeObject
          array.items.each do |item|
            item = item.object if item.is_a?(Pdfbox::Cos::Object)
            if item.is_a?(Pdfbox::Cos::Dictionary)
              list << PDAttributeObject.create(item)
            end
          end
          class_map[name.value] = list
        end
      end
      class_map
    end

    # Returns the ID tree (Java PDStructureTreeRoot#getIDTree).
    def id_tree : PDStructureElementNameTreeNode?
      id_tree_dict = @dictionary.get_dictionary(Pdfbox::Cos::Name.new("IDTree"))
      id_tree_dict ? PDStructureElementNameTreeNode.new(id_tree_dict) : nil
    end
  end
end
