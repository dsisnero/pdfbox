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

    # Returns the role map (/RoleMap) as a String => String map.
    # Java PDStructureTreeRoot#getRoleMap.
    def role_map : Hash(String, String)
      result = {} of String => String
      role_map_dictionary = @dictionary.get_dictionary(Pdfbox::Cos::Name::ROLE_MAP)
      return result unless role_map_dictionary

      role_map_dictionary.entries.each do |name, base|
        base = base.object if base.is_a?(Pdfbox::Cos::Object)
        case base
        when Pdfbox::Cos::Name
          result[name.value] = base.value
        when Pdfbox::Cos::String
          result[name.value] = base.value
        end
      end
      result
    end

    # Sets the role map (/RoleMap) as a dictionary of names.
    # Java PDStructureTreeRoot#setRoleMap.
    def role_map=(role_map : Hash(String, String)) : Nil
      role_map_dictionary = Pdfbox::Cos::Dictionary.new
      role_map.each do |key, value|
        role_map_dictionary.set_name(key, value)
      end
      @dictionary[Pdfbox::Cos::Name::ROLE_MAP] = role_map_dictionary
    end

    # Returns the ID tree (Java PDStructureTreeRoot#getIDTree).
    def id_tree : Pdfbox::Pdmodel::Common::PDStructureElementNameTreeNode?
      id_tree_dict = @dictionary.get_dictionary(Pdfbox::Cos::Name.new("IDTree"))
      id_tree_dict ? Pdfbox::Pdmodel::Common::PDStructureElementNameTreeNode.new(id_tree_dict) : nil
    end

    def id_tree=(tree : Pdfbox::Pdmodel::Common::PDStructureElementNameTreeNode?) : Pdfbox::Pdmodel::Common::PDStructureElementNameTreeNode?
      if tree
        @dictionary.set_item(Pdfbox::Cos::Name::ID_TREE, tree.cos_object)
      else
        @dictionary.delete(Pdfbox::Cos::Name::ID_TREE)
      end
      tree
    end

    # Returns the parent tree (Java PDStructureTreeRoot#getParentTree).
    def parent_tree : Pdfbox::Pdmodel::Common::PDNumberTreeNode(Pdfbox::Pdmodel::Common::PDParentTreeValue)?
      parent_tree_dict = @dictionary.get_dictionary(Pdfbox::Cos::Name::PARENT_TREE)
      return nil unless parent_tree_dict

      Pdfbox::Pdmodel::Common::PDNumberTreeNode(Pdfbox::Pdmodel::Common::PDParentTreeValue).new(
        parent_tree_dict
      ) { |base| Pdfbox::Pdmodel::Common::PDParentTreeValue.new(base) }
    end

    def parent_tree=(tree : Pdfbox::Pdmodel::Common::PDNumberTreeNode(Pdfbox::Pdmodel::Common::PDParentTreeValue)?) : Nil
      if tree
        @dictionary.set_item(Pdfbox::Cos::Name::PARENT_TREE, tree.cos_object)
      else
        @dictionary.delete(Pdfbox::Cos::Name::PARENT_TREE)
      end
    end

    def parent_tree_next_key : Int32
      @dictionary.get_int(Pdfbox::Cos::Name::PARENT_TREE_NEXT_KEY, -1_i64).to_i32
    end

    def parent_tree_next_key=(value : Int32) : Int32
      @dictionary.set_int(Pdfbox::Cos::Name::PARENT_TREE_NEXT_KEY, value)
      value
    end
  end
end
