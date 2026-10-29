require "../pdmodel"

# Splits a PDF document into multiple documents.
# Port of Apache PDFBox multipdf/Splitter.
module Pdfbox::Multipdf
  class Splitter
    Log = ::Log.for(self)

    @source_document : Pdmodel::Document?
    @current_destination_document : Pdmodel::Document?
    @destination_documents = [] of Pdmodel::Document
    @split_length : Int32 = 1
    @start_page : Int32 = Int32::MIN
    @end_page : Int32 = Int32::MAX
    @page_dict_map = {} of UInt64 => Cos::Dictionary
    @page_dict_maps = [] of Hash(UInt64, Cos::Dictionary)
    @struct_dict_map = {} of UInt64 => Cos::Dictionary
    @annot_dict_map = {} of UInt64 => Cos::Dictionary
    @annot_dict_maps = [] of Hash(UInt64, Cos::Dictionary)
    @dest_to_fix_map = [] of Tuple(Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination, Pdmodel::Page)
    @id_set = Set(String).new
    @role_set = Set(String).new
    @current_page_number = 0

    def split_length : Int32
      @split_length
    end

    def start_page : Int32
      @start_page
    end

    def end_page : Int32
      @end_page
    end

    # This will tell the splitting algorithm where to split the pages. The default
    # is 1, so every page will become a new document.
    def set_split_at_page(split : Int32) : Nil # ameba:disable Naming/AccessorMethodName
      raise ArgumentError.new("Number of pages is smaller than one") if split <= 0
      @split_length = split
    end

    # Sets the start page (1-based). Java Splitter#setStartPage.
    def set_start_page(start : Int32) : Nil # ameba:disable Naming/AccessorMethodName
      raise ArgumentError.new("Start page is smaller than one") if start <= 0
      @start_page = start
    end

    # Sets the end page (1-based). Java Splitter#setEndPage.
    def set_end_page(last : Int32) : Nil # ameba:disable Naming/AccessorMethodName
      raise ArgumentError.new("End page is smaller than one") if last <= 0
      raise ArgumentError.new("End page is smaller than startPage") if last < @start_page
      @end_page = last
    end

    # Splits the given document. Java Splitter#split.
    def split(document : Pdmodel::Document) : Array(Pdmodel::Document)
      @current_page_number = 0
      @destination_documents = [] of Pdmodel::Document
      @source_document = document
      @page_dict_maps = [] of Hash(UInt64, Cos::Dictionary)
      @annot_dict_maps = [] of Hash(UInt64, Cos::Dictionary)
      @dest_to_fix_map = [] of Tuple(Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination, Pdmodel::Page)
      @id_set = Set(String).new
      @role_set = Set(String).new
      @current_destination_document = nil

      process_pages

      @destination_documents.each_with_index do |destination_document, index|
        @page_dict_map = @page_dict_maps[index]
        @annot_dict_map = @annot_dict_maps[index]
        clone_structure_tree(destination_document)
        fix_destinations(destination_document)
      end

      @destination_documents
    end

    private def process_pages : Nil
      source = @source_document
      return unless source
      source.pages.each do |page|
        if @current_page_number + 1 >= @start_page && @current_page_number + 1 <= @end_page
          process_page(page)
          @current_page_number += 1
        else
          break if @current_page_number > @end_page
          @current_page_number += 1
        end
      end
    end

    private def create_new_document_if_necessary : Nil
      if split_at_page(@current_page_number) || @current_destination_document.nil?
        new_document = create_new_document
        @current_destination_document = new_document
        @destination_documents << new_document
        @page_dict_map = {} of UInt64 => Cos::Dictionary
        @page_dict_maps << @page_dict_map
        @annot_dict_map = {} of UInt64 => Cos::Dictionary
        @annot_dict_maps << @annot_dict_map
      end
    end

    # Java Splitter#splitAtPage.
    protected def split_at_page(page_number : Int32) : Bool
      (page_number + 1 - Math.max(1, @start_page)) % @split_length == 0
    end

    # Java Splitter#createNewDocument.
    protected def create_new_document : Pdmodel::Document
      source = @source_document
      raise ArgumentError.new("source document is not set") unless source
      document = Pdmodel::Document.create
      document.set_version(source.version)

      # Java Splitter#createNewDocument copies the /Info entries; the accessor is
      # never nil, so an empty source metadata dictionary simply copies nothing.
      info = source.document_information
      dest_info = Cos::Dictionary.new
      info.cos_object.entries.each do |key, value|
        next if key == Cos::Name::TYPE
        raw = value.is_a?(Cos::Object) ? value.object : value
        next if raw.is_a?(Cos::Dictionary)
        dest_info[key] = value
      end
      document.set_document_information(Pdmodel::DocumentInformation.new(dest_info))

      dest_catalog = document.document_catalog
      source_catalog = source.document_catalog
      if dest_catalog && source_catalog
        {"ViewerPreferences", "Lang", "MarkInfo", "Metadata"}.each do |key|
          name = Cos::Name.new(key)
          if value = source_catalog.cos_object[name]?
            dest_catalog.cos_object[name] = value
          end
        end
      end
      document
    end

    # Java Splitter#processPage.
    protected def process_page(page : Pdmodel::Page) : Nil
      create_new_document_if_necessary

      destination = @current_destination_document
      return unless destination
      imported = destination.import_page(page)
      if (resources = page.resources) && !page.cos_object.try(&.has_key?(Cos::Name::RESOURCES))
        imported.resources = resources
      end
      imported_dict = imported.cos_object
      return unless imported_dict
      if imported_dict.has_key?(Cos::Name::B)
        imported_dict.delete(Cos::Name::B)
      end
      process_annotations(imported)

      source_dict = page.cos_object
      @page_dict_map[source_dict.object_id] = imported_dict if source_dict
    end

    # Java Splitter#processAnnotations: shallow-clone every annotation, fix link
    # destinations and popup/markup cross references.
    private def process_annotations(imported : Pdmodel::Page) : Nil
      annotations = imported.annotations
      return if annotations.size == 0

      cloned_annotations = [] of Pdmodel::Interactive::Annotation::PDAnnotation
      annotations.each do |annot|
        cloned_dict = Cos::Dictionary.new(annot.cos_object.entries.dup)
        annotation_clone = Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(cloned_dict)
        @annot_dict_map[annot.cos_object.object_id] = cloned_dict
        cloned_annotations << annotation_clone
        process_link_annotation(annotation_clone, imported)
        if annotation_clone.is_a?(Pdmodel::Interactive::Annotation::PDAnnotationWidget) &&
           annotation_clone.cos_object.has_key?(Cos::Name::PARENT)
          annotation_clone.cos_object.delete(Cos::Name::PARENT)
        end
        annotation_clone.page = imported if annot.page
      end

      cloned_annotations.each do |annot|
        process_markup_annotation(annot, imported)
      end
      imported.annotations = cloned_annotations
    end

    private def process_link_annotation(annotation_clone : Pdmodel::Interactive::Annotation::PDAnnotation, imported : Pdmodel::Page) : Nil
      return unless annotation_clone.is_a?(Pdmodel::Interactive::Annotation::PDAnnotationLink)

      link = annotation_clone
      src_destination = nil
      begin
        src_destination = link.destination
      rescue
        link.destination = nil
      end
      action = nil
      if src_destination.nil?
        action = link.action
        if action.is_a?(Pdmodel::Interactive::Action::PDActionGoTo)
          begin
            src_destination = action.destination
          rescue
            link.action = nil
          end
        end
      end
      if src_destination.is_a?(Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination)
        source = @source_document
        src_destination = source.document_catalog.try(&.find_named_destination_page(src_destination)) if source
      end
      return unless src_destination.is_a?(Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)

      destination_page = src_destination.page
      return unless destination_page

      cloned_destination_array = Cos::Array.new(src_destination.cos_object.items)
      created = Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(cloned_destination_array)
      return unless created.is_a?(Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)

      dst_destination = created
      @dest_to_fix_map << {dst_destination, imported}

      if action
        cloned_action_dict = Cos::Dictionary.new(action.cos_object.entries.dup)
        dst_action = Pdmodel::Interactive::Action::PDActionFactory.create_action(cloned_action_dict)
        if dst_action.is_a?(Pdmodel::Interactive::Action::PDActionGoTo)
          dst_action.destination = dst_destination
          link.action = dst_action
        end
      else
        link.destination = dst_destination
      end
    end

    private def process_markup_annotation(annot : Pdmodel::Interactive::Annotation::PDAnnotation, imported : Pdmodel::Page) : Nil
      if annot.is_a?(Pdmodel::Interactive::Annotation::PDAnnotationMarkup)
        popup = annot.popup
        if popup
          if cloned_popup_dict = @annot_dict_map[popup.cos_object.object_id]?
            annot.cos_object[Cos::Name.new("Popup")] = cloned_popup_dict
          else
            cloned_popup_dict = Cos::Dictionary.new(popup.cos_object.entries.dup)
            @annot_dict_map[popup.cos_object.object_id] = cloned_popup_dict
            popup_clone = Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(cloned_popup_dict)
            if popup_clone.is_a?(Pdmodel::Interactive::Annotation::PDAnnotationPopup)
              popup_clone.parent = annot
              annot.popup = popup_clone
              popup_clone.page = imported if popup_clone.page
            end
          end
        end
      end
      if annot.is_a?(Pdmodel::Interactive::Annotation::PDAnnotationPopup)
        markup = annot.parent
        if markup
          cloned_markup_dict = @annot_dict_map[markup.cos_object.object_id]?
          if cloned_markup_dict
            annot.cos_object[Cos::Name::PARENT] = cloned_markup_dict
          else
            annot.cos_object.delete(Cos::Name::PARENT)
          end
        end
      end
    end

    # Replace page destinations when the source and destination pages are in the
    # target document. Java Splitter#fixDestinations.
    private def fix_destinations(destination_document : Pdmodel::Document) : Nil
      pages = destination_document.pages
      @dest_to_fix_map.each do |entry|
        page_destination = entry[0]
        src_page = entry[1]
        next if page_index_of(pages, src_page) < 0

        src_page_dict = page_destination.page
        next unless src_page_dict
        dst_page_dict = @page_dict_map[src_page_dict.object_id]?

        if dst_page_dict && page_index_of(pages, Pdmodel::Page.new(dst_page_dict)) >= 0
          page_destination.page = dst_page_dict
        else
          page_destination.page = nil
        end
      end
    end

    private def clone_structure_tree(destination_document : Pdmodel::Document) : Nil
      source = @source_document
      return unless source
      src_tree_root = source.document_catalog.try(&.structure_tree_root)
      return unless src_tree_root

      @struct_dict_map = {} of UInt64 => Cos::Dictionary
      dst_tree_root = Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot.new
      dst_pages = destination_document.pages

      k1 = src_tree_root.k
      k2 = KCloner.new(dst_pages, @struct_dict_map, @page_dict_map, @annot_dict_map, @id_set, @role_set)
        .create_clone(k1, dst_tree_root.cos_object, nil)
      dst_tree_root.k = k2

      src_parent_tree = src_tree_root.parent_tree
      src_number_tree_as_map = PDFMergerUtility.get_number_tree_as_map(src_parent_tree)
      dst_number_tree_as_map = {} of Int32 => Pdmodel::Common::PDParentTreeValue
      dst_pages.each do |page|
        sp1 = page.struct_parents
        clone_tree_element(src_number_tree_as_map, dst_number_tree_as_map, sp1) if sp1 != -1
        page.annotations.each do |annot|
          sp2 = annot.struct_parent
          clone_tree_element(src_number_tree_as_map, dst_number_tree_as_map, sp2) if sp2 != -1
          if appearance = annot.normal_appearance_stream
            process_resources(appearance.resources.try(&.cos_object), src_number_tree_as_map, dst_number_tree_as_map, Set(UInt64).new)
          end
        end
        process_resources(page.resources.try(&.cos_object), src_number_tree_as_map, dst_number_tree_as_map, Set(UInt64).new)
      end

      dst_number_tree_node = Pdmodel::Common::PDNumberTreeNode(Pdmodel::Common::PDParentTreeValue).new(
        ->(base : Cos::Base) { Pdmodel::Common::PDParentTreeValue.new(base) }
      )
      dst_number_tree_node.numbers = dst_number_tree_as_map
      dst_tree_root.parent_tree = dst_number_tree_node
      if upper = dst_number_tree_node.upper_limit
        dst_tree_root.parent_tree_next_key = upper + 1
      end

      if class_map = src_tree_root.cos_object.get_dictionary(Cos::Name::CLASS_MAP)
        dst_tree_root.cos_object[Cos::Name::CLASS_MAP] = class_map
      end
      clone_role_map(src_tree_root, dst_tree_root)
      clone_id_tree(src_tree_root, dst_tree_root)

      if catalog = destination_document.document_catalog
        catalog.structure_tree_root = dst_tree_root
      end
    end

    private def clone_id_tree(src_tree_root : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                              dst_tree_root : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot) : Nil
      src_id_tree = src_tree_root.id_tree
      return unless src_id_tree

      src_id_tree_as_map = PDFMergerUtility.get_id_tree_as_map(src_id_tree)
      dest_names = {} of String => Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement
      src_id_tree_as_map.each do |key, value|
        next unless @id_set.includes?(key)
        dst_dict = @struct_dict_map[value.cos_object.object_id]?
        dest_names[key] = Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(dst_dict) if dst_dict
      end
      dest_id_tree = Pdmodel::Common::PDStructureElementNameTreeNode.new
      dest_id_tree.names = dest_names
      dst_tree_root.id_tree = dest_id_tree
    end

    private def clone_role_map(src_tree_root : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                               dst_tree_root : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot) : Nil
      src_dict = src_tree_root.cos_object.get_dictionary(Cos::Name::ROLE_MAP)
      return unless src_dict

      dst_dict = Cos::Dictionary.new
      src_dict.entries.each do |key, value|
        dst_dict[key] = value if @role_set.includes?(key.value)
      end
      dst_tree_root.cos_object[Cos::Name::ROLE_MAP] = dst_dict
    end

    private def clone_tree_element(src_map : Hash(Int32, Pdmodel::Common::PDParentTreeValue),
                                   dst_map : Hash(Int32, Pdmodel::Common::PDParentTreeValue),
                                   sp : Int32) : Nil
      src_obj = src_map[sp]?
      return unless src_obj

      actual = src_obj.cos_object
      dst_obj : Cos::Base? = nil
      if actual.is_a?(Cos::Array)
        dst_array = Cos::Array.new
        actual.items.each do |element|
          element = element.object if element.is_a?(Cos::Object)
          cloned = element ? @struct_dict_map[element.object_id]? : nil
          dst_array.add(cloned || Cos::Null::INSTANCE)
        end
        dst_obj = dst_array
      elsif actual.is_a?(Cos::Dictionary)
        dst_obj = @struct_dict_map[actual.object_id]?
        if dst_obj.nil?
          Log.warn { "ParentTree index #{sp} dictionary not found in /K" }
        end
      end
      dst_map[sp] = Pdmodel::Common::PDParentTreeValue.new(dst_obj) if dst_obj
    end

    private def process_resources(resource : Cos::Base?,
                                  src_map : Hash(Int32, Pdmodel::Common::PDParentTreeValue),
                                  dst_map : Hash(Int32, Pdmodel::Common::PDParentTreeValue),
                                  visited : Set(UInt64)) : Nil
      resource_dict = resource.as?(Cos::Dictionary)
      return unless resource_dict

      id = resource_dict.object_id.to_u64
      return if visited.includes?(id)
      visited.add(id)

      xobject_dict = resource_dict.get_dictionary(Cos::Name.new("XObject"))
      return unless xobject_dict

      xobject_dict.entries.each do |_name, value|
        value = value.object if value.is_a?(Cos::Object)
        stream = value.as?(Cos::Stream)
        next unless stream

        sp2 = -1
        case stream.get_name_as_string(Cos::Name::SUBTYPE)
        when "Form"
          form = Pdmodel::Graphics::Form::PDFormXObject.new(stream)
          sp2 = form.struct_parents
          process_resources(form.resources.try(&.cos_object), src_map, dst_map, visited)
        when "Image"
          sp2 = stream.get_int(Cos::Name::STRUCT_PARENT, -1_i64).to_i32
        end
        clone_tree_element(src_map, dst_map, sp2) if sp2 != -1
      end
    end

    private def page_index_of(pages : Array(Pdmodel::Page), page : Pdmodel::Page) : Int32
      cos_page = page.cos_object
      return -1 unless cos_page
      pages.index { |candidate| candidate.cos_object.try(&.same?(cos_page)) } || -1
    end

    # Clones the /K structure tree, keeping only elements that belong to the
    # destination pages. Java Splitter.KCloner.
    private class KCloner
      def initialize(@dst_pages : Array(Pdmodel::Page),
                     @struct_dict_map : Hash(UInt64, Cos::Dictionary),
                     @page_dict_map : Hash(UInt64, Cos::Dictionary),
                     @annot_dict_map : Hash(UInt64, Cos::Dictionary),
                     @id_set : Set(String),
                     @role_set : Set(String))
      end

      def create_clone(src : Cos::Base?, dst_parent : Cos::Base?, current_page_dict : Cos::Dictionary?) : Cos::Base?
        case src
        when Cos::Array
          create_array_clone(src, dst_parent, current_page_dict)
        when Cos::Dictionary
          create_dictionary_clone(src, dst_parent, current_page_dict)
        else
          src
        end
      end

      private def create_array_clone(src : Cos::Array, dst_parent : Cos::Base?, current_page_dict : Cos::Dictionary?) : Cos::Base?
        dst = Cos::Array.new
        src.items.each do |base|
          base = base.object if base.is_a?(Cos::Object)
          cloned = create_clone(base, dst_parent, current_page_dict)
          dst.add(cloned) if cloned
        end
        dst.empty? ? nil : dst
      end

      private def create_dictionary_clone(src_dict : Cos::Dictionary, dst_parent : Cos::Base?,
                                          current_page_dict : Cos::Dictionary?) : Cos::Base?
        if existing = @struct_dict_map[src_dict.object_id]?
          return existing
        end

        src_page_dict = src_dict.get_dictionary(Cos::Name::PG)
        dst_page_dict : Cos::Dictionary? = nil
        kid = src_dict.get_dictionary_object(Cos::Name::K)
        type = src_dict.get_name_as_string(Cos::Name::TYPE)
        if src_page_dict
          dst_page_dict = @page_dict_map[src_page_dict.object_id]?
          if dst_page_dict
            if page_index_of(dst_page_dict) == -1
              return nil
            end
          elsif type == "MCR" || type == "OBJR" || has_mcids?(kid)
            return nil
          end
        end

        if type == "MCR" && dst_page_dict.nil? && dst_parent.is_a?(Cos::Dictionary) &&
           dst_parent.get_dictionary(Cos::Name::PG).nil?
          return nil
        end

        dst_dict = Cos::Dictionary.new
        @struct_dict_map[src_dict.object_id] = dst_dict
        src_dict.entries.each do |key, value|
          next if key == Cos::Name::K || key == Cos::Name::PG || key == Cos::Name::P
          dst_dict[key] = value
        end

        if type == "OBJR"
          src_obj = src_dict.get_dictionary(Cos::Name::OBJ)
          if src_obj
            dst_obj = @annot_dict_map[src_obj.object_id]?
            if dst_obj
              dst_dict[Cos::Name::OBJ] = dst_obj
            else
              remove_possible_orphan_annotation(src_obj, src_dict, current_page_dict, dst_dict)
            end
          end
          return nil if dst_dict.size == 1
          if dst_page_dict.nil? && dst_parent.is_a?(Cos::Dictionary) &&
             dst_parent.get_dictionary(Cos::Name::PG).nil?
            return nil
          end
        end

        unless type == "OBJR" || type == "MCR"
          dst_dict[Cos::Name::P] = dst_parent || Cos::Null::INSTANCE
        end
        dst_dict[Cos::Name::PG] = dst_page_dict || Cos::Null::INSTANCE

        clone_kid = create_clone(kid, dst_dict, dst_page_dict || current_page_dict)
        if clone_kid.nil? && !kid.nil?
          return nil
        end
        if dst_page_dict.nil? && clone_kid.nil? && current_page_dict.nil?
          return nil
        end
        dst_dict[Cos::Name::K] = clone_kid || Cos::Null::INSTANCE

        if id = dst_dict.get_string(Cos::Name::ID)
          @id_set.add(id)
        end
        if s = dst_dict.get_name_as_string(Cos::Name::S)
          @role_set.add(s)
        end
        dst_dict
      end

      private def has_mcids?(kid : Cos::Base?) : Bool
        return true if kid.is_a?(Cos::Integer)
        if kid.is_a?(Cos::Array)
          kid.items.any?(Cos::Integer)
        else
          false
        end
      end

      private def remove_possible_orphan_annotation(src_obj : Cos::Dictionary, src_dict : Cos::Dictionary,
                                                    current_page_dict : Cos::Dictionary?,
                                                    dst_dict : Cos::Dictionary) : Nil
        obj_type = src_obj.get_name_as_string(Cos::Name::TYPE)
        obj_subtype = src_obj.get_name_as_string(Cos::Name::SUBTYPE)
        return unless obj_type == "Annot" || obj_subtype == "Link"

        src_page_dict = src_dict.get_dictionary(Cos::Name::PG) || current_page_dict
        return unless src_page_dict

        annotations = src_page_dict.get_array(Cos::Name::ANNOTS)
        in_page = annotations && annotations.items.any? do |entry|
          entry = entry.object if entry.is_a?(Cos::Object)
          entry.same?(src_obj)
        end
        unless in_page
          Log.warn { "An annotation OBJ that isn't in the page has been removed from the structure tree" }
          dst_dict.delete(Cos::Name::OBJ)
        end
      end

      private def page_index_of(dict : Cos::Dictionary) : Int32
        @dst_pages.index { |page| page.cos_object.try(&.same?(dict)) } || -1
      end
    end
  end
end
