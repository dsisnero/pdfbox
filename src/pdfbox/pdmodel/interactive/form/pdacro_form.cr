# An interactive form, also known as an AcroForm
module Pdfbox::Pdmodel::Interactive::Form
  class PDAcroForm
    Log = ::Log.for(self)

    FLAG_SIGNATURES_EXIST = 1
    FLAG_APPEND_ONLY      = 1 << 1

    @document : Pdmodel::Document
    @dictionary : Cos::Dictionary
    @field_cache : Hash(String, PDField)?
    @scripting_handler : ScriptingHandler?
    @cache_fields = false

    def initialize(@document : Pdmodel::Document)
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name.new("Fields")] = Cos::Array.new
    end

    def initialize(@document : Pdmodel::Document, @dictionary : Cos::Dictionary)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Get the document
    def document : Pdmodel::Document
      @document
    end

    # Whether the form has an XFA resource (Java hasXFA).
    def has_xfa? : Bool
      @dictionary.has_key?(Cos::Name.new("XFA"))
    end

    # Whether the form is a dynamic XFA form (Java xfaIsDynamic).
    def xfa_is_dynamic? : Bool
      has_xfa? && fields.empty?
    end

    # The XFA resource (/XFA), or nil (Java getXFA).
    def xfa : PDXFAResource?
      base = @dictionary.get_dictionary_object(Cos::Name.new("XFA"))
      base ? PDXFAResource.new(base) : nil
    end

    # Sets the XFA resource (/XFA; Java setXFA).
    def xfa=(xfa : PDXFAResource) : PDXFAResource
      @dictionary[Cos::Name.new("XFA")] = xfa.cos_object
      xfa
    end

    # The default quadding for variable text fields (/Q; Java getQ).
    def q : Int32
      @dictionary.get_int(Cos::Name.new("Q"), 0).to_i32
    end

    def q=(q : Int32) : Int32
      @dictionary.set_int(Cos::Name.new("Q"), q)
      q
    end

    # The calculation order (/CO) array, or nil (Java getCalcOrder).
    def calc_order : Cos::Array?
      @dictionary.get_array(Cos::Name.new("CO"))
    end

    def calc_order=(calc_order : Cos::Array?) : Nil
      key = Cos::Name.new("CO")
      if calc_order
        @dictionary[key] = calc_order
      else
        @dictionary.delete(key)
      end
    end

    # Get the scripting handler used to format values.
    def scripting_handler : ScriptingHandler?
      @scripting_handler
    end

    # Set the scripting handler used to format values.
    def scripting_handler=(handler : ScriptingHandler?) : ScriptingHandler?
      @scripting_handler = handler
    end

    # Get all fields in the form
    def fields : Array(PDField)
      fields_value = @dictionary[Cos::Name.new("Fields")]
      if fields_value.is_a?(Cos::Object)
        fields_value = fields_value.object
      end
      return [] of PDField unless fields_value.is_a?(Cos::Array)
      fields_array = fields_value

      result = [] of PDField
      fields_array.items.each do |field_item|
        field_dict = field_item
        field_dict = field_dict.object if field_dict.is_a?(Cos::Object)
        if field_dict.is_a?(Cos::Dictionary)
          field = PDFieldFactory.create_field(self, field_dict, nil)
          result << field if field
        end
      end
      result
    end

    # Get a field by its fully qualified name. Java PDAcroForm#getField matches
    # field.getFullyQualifiedName() across the field tree.
    def get_field(name : String) : PDField?
      get_field_tree.each do |field|
        return field if field.fully_qualified_name == name
      end
      nil
    end

    # Get the field tree: all fields in the form, in order, recursing into
    # non-terminal children. Java PDAcroForm#getFieldTree (PDFBOX-5044 cycle guard).
    # ameba:disable Naming/AccessorMethodName
    def get_field_tree : Array(PDField)
      result = [] of PDField
      seen = Set(UInt64).new

      fields.each do |field|
        walk_field_tree(field, seen, result)
      end

      result
    end

    private def walk_field_tree(node : PDField, seen : Set(UInt64), result : Array(PDField)) : Nil
      result << node
      seen.add(node.cos_object.object_id)
      return unless node.is_a?(PDNonTerminalField)

      node.children.each do |kid|
        if seen.includes?(kid.cos_object.object_id)
          Log.warn { "Child of field '#{node.fully_qualified_name}' already exists elsewhere, ignored to avoid recursion" }
        else
          walk_field_tree(kid, seen, result)
        end
      end
    end

    # Check if signatures exist
    def signatures_exist? : Bool
      flags = @dictionary[Cos::Name.new("SigFlags")]
      return false unless flags.is_a?(Cos::Integer)
      (flags.value & FLAG_SIGNATURES_EXIST) != 0
    end

    # Check if form is append-only
    def append_only? : Bool
      flags = @dictionary[Cos::Name.new("SigFlags")]
      return false unless flags.is_a?(Cos::Integer)
      (flags.value & FLAG_APPEND_ONLY) != 0
    end

    # Set the signatures-exist flag (/SigFlags bit 1). Java setSignaturesExist.
    def signatures_exist=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("SigFlags"), FLAG_SIGNATURES_EXIST, value)
      value
    end

    # Set the append-only flag (/SigFlags bit 2). Java setAppendOnly.
    def append_only=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("SigFlags"), FLAG_APPEND_ONLY, value)
      value
    end

    # Iterates the field tree. Java PDAcroForm#getFieldIterator.
    def field_iterator : Iterator(PDField)
      get_field_tree.each
    end

    # Toggles field caching. Java PDAcroForm#setCacheFields.
    def cache_fields=(cache : Bool) : Bool
      @cache_fields = cache
      cache
    end

    # Whether field caching is enabled. Java PDAcroForm#isCachingFields.
    def caching_fields? : Bool
      @cache_fields
    end

    # Regenerates the appearance streams of every terminal field.
    # Java PDAcroForm#refreshAppearances.
    def refresh_appearances : Nil
      refresh_appearances(get_field_tree)
    end

    # Regenerates the appearance streams of the given fields (terminal fields only).
    # Java PDAcroForm#refreshAppearances(List).
    def refresh_appearances(fields : Enumerable(PDField)) : Nil
      fields.each do |field|
        field.construct_appearances if field.is_a?(PDTerminalField)
      end
    end

    # Get the default resources
    def default_resources : Pdmodel::PDResources?
      dr = @dictionary[Cos::Name.new("DR")]
      dr = dr.object if dr.is_a?(Cos::Object)
      return unless dr.is_a?(Cos::Dictionary)
      Pdmodel::PDResources.new(dr)
    end

    # Set the default resources
    def default_resources=(value : Pdmodel::PDResources) : Pdmodel::PDResources
      @dictionary[Cos::Name.new("DR")] = value.cos_object
      value
    end

    # Get the default appearance string (DA entry). Java PDAcroForm#getDefaultAppearance.
    def default_appearance : String
      value = @dictionary[Cos::Name.new("DA")]
      value = value.object if value.is_a?(Cos::Object)
      value.as?(Cos::String).try(&.value) || ""
    end

    # Set the default appearance string
    def default_appearance=(value : String) : String
      @dictionary.set_string(Cos::Name.new("DA"), value)
      value
    end

    # Check if NeedAppearances flag is set
    def need_appearances? : Bool
      value = @dictionary[Cos::Name.new("NeedAppearances")]
      return false unless value.is_a?(Cos::Boolean)
      value.value
    end

    # Set NeedAppearances flag
    def need_appearances=(value : Bool)
      @dictionary[Cos::Name.new("NeedAppearances")] = Cos::Boolean.get(value)
    end

    # Add a field to the form
    def add_field(field : PDField)
      fields_array = @dictionary[Cos::Name.new("Fields")]
      unless fields_array.is_a?(Cos::Array)
        fields_array = Cos::Array.new
        @dictionary[Cos::Name.new("Fields")] = fields_array
      end
      fields_array.add(field.cos_object)
    end

    # Set the fields of the form. Java PDAcroForm#setFields.
    # ameba:disable Naming/AccessorMethodName
    def set_fields(fields : Enumerable(PDField)) : Nil
      fields_array = Cos::Array.new
      fields.each do |field|
        fields_array.add(field.cos_object)
      end
      @dictionary[Cos::Name.new("Fields")] = fields_array
    end

    def import_fdf(fdf : Pdfbox::Pdmodel::Fdf::FDFDocument) : Nil
      fdf.catalog.fdf.fields.try(&.each do |field|
        next unless name = field.partial_field_name
        get_field(name).try(&.import_fdf(field))
      end)
    end

    def export_fdf : Pdfbox::Pdmodel::Fdf::FDFDocument
      fdf = Pdfbox::Pdmodel::Fdf::FDFDocument.new
      exported_fields = fields.map(&.export_fdf)
      fdf.catalog.fdf.fields = exported_fields unless exported_fields.empty?

      if document_id = @document.document_id
        hex = document_id.hexstring
        fdf.catalog.fdf.id = [hex, hex]
      end
      fdf
    end

    # Flatten all form fields: take the current appearance and make that part of
    # the page's content stream, then remove all fields and their annotations.
    # Java PDAcroForm#flatten.
    def flatten : Nil
      flatten(get_field_tree, false)
    end

    # Rebuild the /Fields entry from page-level widget annotations when it is
    # empty. Java AcroFormOrphanWidgetsProcessor (PDFBOX-3891/4985).
    def rebuild_fields_from_widgets : Nil
      AcroFormOrphanWidgetsProcessor.new(@document).process
    end

    # Flatten the specified form fields.
    #
    # *fields*: fields to be flattened. *refresh_appearances*: regenerate the
    # widget appearances before flattening.
    def flatten(fields : Array(PDField), refresh_appearances : Bool) : Nil
      return if fields.empty?

      if refresh_appearances
        fields.each do |field|
          field.construct_appearances if field.responds_to?(:construct_appearances)
        end
      end

      pages = @document.pages
      pages_widgets_map = build_pages_widgets_map(fields, pages)

      # preserve all non widget annotations
      pages.each do |page|
        widgets_for_page = pages_widgets_map[page.cos_object]?

        # indicates if the original content stream has been wrapped in a q...Q pair.
        is_content_stream_wrapped = false

        annotations = [] of Annotation::PDAnnotation

        page.annotations.each do |annot|
          if widgets_for_page.nil? || !widgets_for_page.includes?(annot.cos_object)
            annotations << annot
          elsif is_visible_annotation(annot)
            contents = Pdfbox::Pdmodel::PDPageContentStream.new(
              @document, page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, false)
            unless is_content_stream_wrapped
              contents.save_graphics_state
            end
            is_content_stream_wrapped = true

            appearance_stream = annot.normal_appearance_stream
            if appearance_stream
              field_object = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(appearance_stream.require_stream_object)

              contents.save_graphics_state

              transformation_matrix = resolve_transformation_matrix(annot, appearance_stream)
              contents.transform(transformation_matrix)
              contents.draw_form(field_object)
              contents.restore_graphics_state
            end
            contents.close
          end
        end
        page.annotations = annotations
      end

      # remove the fields
      remove_fields(fields)

      # remove XFA for hybrid forms
      @dictionary.delete(Cos::Name.new("XFA"))
    end

    # ameba:disable Naming/PredicateName
    private def is_visible_annotation(annot : Annotation::PDAnnotation) : Bool
      normal_appearance_stream = annot.normal_appearance_stream
      return false if normal_appearance_stream.nil?

      # the widget annotation is visible if its rect is larger than 0
      rect = annot.rectangle
      return false if rect.nil?
      rect.width > 0 && rect.height > 0
    end

    private def resolve_transformation_matrix(
      annot : Annotation::PDAnnotation,
      appearance_stream : Annotation::PDAppearanceStream,
    ) : Util::Matrix
      # 1st step transform appearance stream bbox with appearance stream matrix
      transformed_appearance_box = get_transformed_appearance_bbox(appearance_stream)
      annotation_rect = annot.rectangle || Common::PDRectangle.new

      # 2nd step calculate matrix to transform calculated rectangle into the
      # annotation Rect boundaries
      transformation_matrix = Util::Matrix.new
      transformation_matrix.translate(
        (annotation_rect.lower_left_x - transformed_appearance_box.lower_left_x).to_f32,
        (annotation_rect.lower_left_y - transformed_appearance_box.lower_left_y).to_f32
      )
      transformation_matrix.scale(
        (annotation_rect.width / transformed_appearance_box.width).to_f32,
        (annotation_rect.height / transformed_appearance_box.height).to_f32
      )
      transformation_matrix
    end

    # Apply the appearance stream Matrix to its BBox.
    private def get_transformed_appearance_bbox(appearance_stream : Annotation::PDAppearanceStream) : Common::PDRectangle
      appearance_stream_matrix = appearance_stream.matrix
      appearance_stream_bbox = appearance_stream.bbox || Common::PDRectangle.new

      # transform the four corners of the bbox and take the bounding box
      corners = [
        {appearance_stream_bbox.lower_left_x, appearance_stream_bbox.lower_left_y},
        {appearance_stream_bbox.lower_left_x, appearance_stream_bbox.upper_right_y},
        {appearance_stream_bbox.upper_right_x, appearance_stream_bbox.lower_left_y},
        {appearance_stream_bbox.upper_right_x, appearance_stream_bbox.upper_right_y},
      ]
      min_x = Float32::MAX
      min_y = Float32::MAX
      max_x = -Float32::MAX
      max_y = -Float32::MAX
      corners.each do |(x, y)|
        tx = appearance_stream_matrix.get_value(0, 0) * x + appearance_stream_matrix.get_value(1, 0) * y + appearance_stream_matrix.get_value(2, 0)
        ty = appearance_stream_matrix.get_value(0, 1) * x + appearance_stream_matrix.get_value(1, 1) * y + appearance_stream_matrix.get_value(2, 1)
        min_x = Math.min(min_x, tx)
        min_y = Math.min(min_y, ty)
        max_x = Math.max(max_x, tx)
        max_y = Math.max(max_y, ty)
      end
      Common::PDRectangle.new(min_x, min_y, max_x - min_x, max_y - min_y)
    end

    # Build a map of page COS dict => set of widget COS dicts to be flattened.
    private def build_pages_widgets_map(fields : Array(PDField), pages) : Hash(Cos::Dictionary, Set(Cos::Dictionary))
      pages_annotations_map = {} of Cos::Dictionary => Set(Cos::Dictionary)
      has_missing_page_ref = false

      fields.each do |field|
        field.widgets.each do |widget|
          page = widget.page
          if page
            fill_pages_annotation_map(pages_annotations_map, page, widget)
          else
            Log.warn { "missing /P entry (page reference) in a widget for field: #{field}" }
            has_missing_page_ref = true
          end
        end
      end

      unless has_missing_page_ref
        return pages_annotations_map
      end

      # If there is a widget with a missing page reference we need to build the
      # map reverse i.e. from the annotations to the widget.
      Log.warn { "There has been a widget with a missing page reference, will check all page annotations" }
      widget_dictionary_set = create_widget_dictionary_set(fields)
      pages.each do |page|
        page.annotations.each do |annot|
          if annot.is_a?(Annotation::PDAnnotationWidget) && widget_dictionary_set.includes?(annot.cos_object)
            fill_pages_annotation_map(pages_annotations_map, page, annot.as(Annotation::PDAnnotationWidget))
          end
        end
      end

      pages_annotations_map
    end

    # Return a set of all annotation widget dictionaries related to the fields
    # to be flattened.
    private def create_widget_dictionary_set(fields : Array(PDField)) : Set(Cos::Dictionary)
      widget_dictionary_set = Set(Cos::Dictionary).new
      fields.each do |field|
        field.widgets.each do |widget|
          widget_dictionary_set.add(widget.cos_object)
        end
      end
      widget_dictionary_set
    end

    private def fill_pages_annotation_map(
      pages_annotations_map : Hash(Cos::Dictionary, Set(Cos::Dictionary)),
      page : Page,
      widget : Annotation::PDAnnotationWidget,
    ) : Nil
      page_dict = page.cos_object || return
      widgets_for_page = pages_annotations_map[page_dict]? || begin
        created = Set(Cos::Dictionary).new
        pages_annotations_map[page_dict] = created
        created
      end
      widgets_for_page.add(widget.cos_object)
    end

    private def remove_fields(fields : Array(PDField)) : Nil
      fields.each do |field|
        array = if parent_field = field.parent
                  parent_field.cos_object.get_array(Cos::Name.new("Kids"))
                else
                  # if the field has no parent, assume it is at root level list
                  @dictionary.get_array(Cos::Name.new("Fields"))
                end
        array.try(&.remove_object(field.cos_object))
      end
    end
  end
end
