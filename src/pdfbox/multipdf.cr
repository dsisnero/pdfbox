require "./pdmodel"
require "./multipdf/splitter"

module Pdfbox::Multipdf
  # Source of truth: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/Overlay.java
  # Adds an overlay to an existing PDF document.
  class Overlay
    enum Position
      FOREGROUND
      BACKGROUND
    end

    # Stores the overlay page information (Java: LayoutPage inner class)
    struct LayoutPage
      property overlay_media_box : Pdmodel::Rectangle
      property overlay_content : String
      property overlay_resources : Cos::Dictionary
      property overlay_rotation : Int32

      def initialize(@overlay_media_box : Pdmodel::Rectangle,
                     @overlay_content : String,
                     @overlay_resources : Cos::Dictionary,
                     @overlay_rotation : Int32)
      end
    end

    @default_overlay_page : LayoutPage?
    @first_page_overlay_page : LayoutPage?
    @last_page_overlay_page : LayoutPage?
    @odd_page_overlay_page : LayoutPage?
    @even_page_overlay_page : LayoutPage?
    @default_overlay_document : Pdmodel::Document?
    @first_page_overlay_document : Pdmodel::Document?
    @last_page_overlay_document : Pdmodel::Document?
    @all_pages_overlay_document : Pdmodel::Document?
    @odd_page_overlay_document : Pdmodel::Document?
    @even_page_overlay_document : Pdmodel::Document?
    @input_pdf_document : Pdmodel::Document?
    @specific_page_overlay_layout_page_map = {} of Int32 => LayoutPage
    @open_documents = [] of Pdmodel::Document
    @position : Position = Position::BACKGROUND
    @adjust_rotation : Bool = false
    @use_all_overlay_pages : Bool = false
    @number_of_overlay_pages : Int32 = 0

    def position=(@position : Position) : Nil
    end

    def adjust_rotation=(@adjust_rotation : Bool) : Nil
    end

    def input_file=(filename : String) : Nil
      @input_pdf_document = Pdmodel::Document.load(filename)
    end

    def input_pdf=(document : Pdmodel::Document) : Nil
      @input_pdf_document = document
    end

    def default_overlay_file=(filename : String) : Nil
      @default_overlay_document = load_pdf(filename)
      if doc = @default_overlay_document
        @default_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def first_page_overlay_file=(filename : String) : Nil
      @first_page_overlay_document = load_pdf(filename)
      if doc = @first_page_overlay_document
        @first_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def last_page_overlay_file=(filename : String) : Nil
      @last_page_overlay_document = load_pdf(filename)
      if doc = @last_page_overlay_document
        @last_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def odd_page_overlay_file=(filename : String) : Nil
      @odd_page_overlay_document = load_pdf(filename)
      if doc = @odd_page_overlay_document
        @odd_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def even_page_overlay_file=(filename : String) : Nil
      @even_page_overlay_document = load_pdf(filename)
      if doc = @even_page_overlay_document
        @even_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def all_pages_overlay_file=(filename : String) : Nil
      @all_pages_overlay_document = load_pdf(filename)
      if doc = @all_pages_overlay_document
        @specific_page_overlay_layout_page_map = create_page_overlay_layout_page_map(doc)
        @use_all_overlay_pages = true
        @number_of_overlay_pages = @specific_page_overlay_layout_page_map.size
      end
    end

    # Java: overlay(Map<Integer, String> specificPageOverlayMap)
    def overlay(specific_page_overlay_map : Hash(Int32, String) = {} of Int32 => String) : Pdmodel::Document
      load_pdfs

      layouts = {} of String => LayoutPage
      specific_page_overlay_map.each do |page_num, path|
        layout_page = layouts[path]?
        unless layout_page
          doc = load_pdf(path)
          layout_page = create_layout_page_from_document(doc)
          layouts[path] = layout_page
          @open_documents << doc
        end
        @specific_page_overlay_layout_page_map[page_num] = layout_page
      end

      input_doc = @input_pdf_document
      raise ::IO::Error.new("Input document not set") unless input_doc

      process_pages(input_doc)
      input_doc
    end

    # Java: close()
    def close : Nil
      @default_overlay_document.try(&.close)
      @first_page_overlay_document.try(&.close)
      @last_page_overlay_document.try(&.close)
      @all_pages_overlay_document.try(&.close)
      @odd_page_overlay_document.try(&.close)
      @even_page_overlay_document.try(&.close)
      @open_documents.each(&.close)
    end

    # Java: loadPDFs()
    private def load_pdfs : Nil
      doc = @default_overlay_document
      if doc
        @default_overlay_page = create_layout_page_from_document(doc)
      end

      doc = @first_page_overlay_document
      if doc
        @first_page_overlay_page = create_layout_page_from_document(doc)
      end

      doc = @last_page_overlay_document
      if doc
        @last_page_overlay_page = create_layout_page_from_document(doc)
      end

      doc = @odd_page_overlay_document
      if doc
        @odd_page_overlay_page = create_layout_page_from_document(doc)
      end

      doc = @even_page_overlay_document
      if doc
        @even_page_overlay_page = create_layout_page_from_document(doc)
      end

      doc = @all_pages_overlay_document
      if doc
        @specific_page_overlay_layout_page_map = create_page_overlay_layout_page_map(doc)
        @use_all_overlay_pages = true
        @number_of_overlay_pages = @specific_page_overlay_layout_page_map.size
      end
    end

    # Java: processPages(PDDocument)
    private def process_pages(document : Pdmodel::Document) : Nil
      page_counter = 0
      number_of_pages = document.number_of_pages

      document.pages.each do |page|
        page_counter += 1
        layout_page = get_layout_page(page_counter, number_of_pages)
        next unless layout_page

        page_dict = page.cos_object
        next unless page_dict
        original_content = page_dict[Cos::Name.new("Contents")]?

        new_content_array = Cos::Array.new

        case @position
        when Position::FOREGROUND
          # save state
          new_content_array << create_stream("q\n")
          add_original_content(original_content, new_content_array)
          # restore state
          new_content_array << create_stream("Q\n")
          # overlay content last
          overlay_page(page, layout_page, new_content_array)
        when Position::BACKGROUND
          # overlay content first
          overlay_page(page, layout_page, new_content_array)
          add_original_content(original_content, new_content_array)
        end

        page_dict[Cos::Name.new("Contents")] = new_content_array
      end
    end

    # Java: addOriginalContent(COSBase, COSArray)
    private def add_original_content(contents : Cos::Base?, content_array : Cos::Array) : Nil
      return unless contents

      if contents.is_a?(Cos::Stream)
        content_array << contents
      elsif contents.is_a?(Cos::Array)
        contents.each { |item| content_array << item }
      end
    end

    # Java: overlayPage(PDPage, LayoutPage, COSArray, PDFCloneUtility)
    private def overlay_page(page : Pdmodel::Page, layout_page : LayoutPage, array : Cos::Array) : Nil
      resources = page.resources
      unless resources
        resources = Pdmodel::Resources.new
        page.resources = resources
      end

      # Create a FormXObject from the overlay content
      form_xobject = create_overlay_form_xobject(layout_page)
      form_name = resources.add(form_xobject, "OL")
      array << create_overlay_stream(page, layout_page, form_name)
    end

    # Java: getLayoutPage(int, int)
    private def get_layout_page(page_number : Int32, number_of_pages : Int32) : LayoutPage?
      if !@use_all_overlay_pages && @specific_page_overlay_layout_page_map.has_key?(page_number)
        return @specific_page_overlay_layout_page_map[page_number]
      end

      if page_number == 1 && (lp = @first_page_overlay_page)
        return lp
      end

      if page_number == number_of_pages && (lp = @last_page_overlay_page)
        return lp
      end

      if page_number.odd? && (lp = @odd_page_overlay_page)
        return lp
      end

      if page_number.even? && (lp = @even_page_overlay_page)
        return lp
      end

      if lp = @default_overlay_page
        return lp
      end

      if @use_all_overlay_pages
        use_page_num = (page_number - 1) % @number_of_overlay_pages
        return @specific_page_overlay_layout_page_map[use_page_num]?
      end

      nil
    end

    # Java: createLayoutPageFromDocument(PDDocument)
    private def create_layout_page_from_document(doc : Pdmodel::Document) : LayoutPage
      create_layout_page(doc.pages[0])
    end

    # Java: createLayoutPage(PDPage)
    private def create_layout_page(page : Pdmodel::Page) : LayoutPage
      cos_dict = page.cos_object
      contents = cos_dict ? cos_dict[Cos::Name.new("Contents")]? : nil
      resources = page.resources || Pdmodel::Resources.new
      media_box = page.media_box || Pdmodel::PageSizes::LETTER

      content_text = extract_content_text(contents)
      rotation = page.rotation

      LayoutPage.new(media_box, content_text, resources.cos_object, rotation)
    end

    # Java: createPageOverlayLayoutPageMap(PDDocument)
    private def create_page_overlay_layout_page_map(doc : Pdmodel::Document) : Hash(Int32, LayoutPage)
      layout_pages = {} of Int32 => LayoutPage
      doc.pages.each_with_index do |page, i|
        layout_pages[i] = create_layout_page(page)
      end
      layout_pages
    end

    # Java: createOverlayFormXObject(LayoutPage, PDFCloneUtility)
    private def create_overlay_form_xobject(layout_page : LayoutPage) : Cos::Stream
      stream = Cos::Stream.new
      stream.data = layout_page.overlay_content.to_slice
      stream[Cos::Name.new("Type")] = Cos::Name.new("XObject")
      stream[Cos::Name.new("Subtype")] = Cos::Name.new("Form")
      stream[Cos::Name.new("FormType")] = Cos::Integer.new(1)

      bbox = layout_page.overlay_media_box.create_retranslated_rectangle
      stream[Cos::Name.new("BBox")] = Cos::Array.new([
        Cos::Float.new(bbox.lower_left_x),
        Cos::Float.new(bbox.lower_left_y),
        Cos::Float.new(bbox.upper_right_x),
        Cos::Float.new(bbox.upper_right_y),
      ] of Cos::Base)

      # Java: rotation handling
      rotation = layout_page.overlay_rotation
      case rotation
      when 90
        matrix = Cos::Array.new([
          Cos::Float.new(0.0_f64),
          Cos::Float.new(1.0_f64),
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(layout_page.overlay_media_box.height.to_f64),
          Cos::Float.new(0.0_f64),
        ] of Cos::Base)
      when 180
        matrix = Cos::Array.new([
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(layout_page.overlay_media_box.width.to_f64),
          Cos::Float.new(layout_page.overlay_media_box.height.to_f64),
        ] of Cos::Base)
      when 270
        matrix = Cos::Array.new([
          Cos::Float.new(0.0_f64),
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(layout_page.overlay_media_box.width.to_f64),
        ] of Cos::Base)
      else
        matrix = Cos::Array.new([
          Cos::Float.new(1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(0.0_f64),
        ] of Cos::Base)
      end
      stream[Cos::Name.new("Matrix")] = matrix

      # Copy overlay resources
      stream[Cos::Name.new("Resources")] = layout_page.overlay_resources

      stream
    end

    # Java: createOverlayStream(PDPage, LayoutPage, COSName)
    private def create_overlay_stream(page : Pdmodel::Page, layout_page : LayoutPage, x_object_id : Cos::Name) : Cos::Stream
      overlay_media_box = layout_page.overlay_media_box

      # Java: calculateAffineTransform - centers overlay on destination page
      page_media_box = page.media_box || Pdmodel::PageSizes::LETTER
      h_shift = page_media_box.lower_left_x + (page_media_box.width - overlay_media_box.width) / 2.0_f32
      v_shift = page_media_box.lower_left_y + (page_media_box.height - overlay_media_box.height) / 2.0_f32

      # Java: rotation adjustment in createOverlayStream
      if layout_page.overlay_rotation == 90 || layout_page.overlay_rotation == 270
        overlay_media_box = Pdmodel::Rectangle.from_dimensions(
          overlay_media_box.height,
          overlay_media_box.width
        )
        # Java: recalculate shift for rotated overlay
        h_shift = page_media_box.lower_left_x + (page_media_box.width - overlay_media_box.width) / 2.0_f32
        v_shift = page_media_box.lower_left_y + (page_media_box.height - overlay_media_box.height) / 2.0_f32
      end

      # Java: build overlay stream: q\nq\n ... cm\n /name Do Q\nQ\n
      content = String.build do |io|
        io << "q\nq\n"
        io << FloatString.float_to_string(h_shift) << ' '
        io << FloatString.float_to_string(0.0_f32) << ' '
        io << FloatString.float_to_string(0.0_f32) << ' '
        io << FloatString.float_to_string(v_shift) << ' '
        io << FloatString.float_to_string(1.0_f32) << ' '
        io << FloatString.float_to_string(0.0_f32) << ' '
        io << " cm\n"
        io << " /" << x_object_id.value << " Do Q\nQ\n"
      end

      create_stream(content)
    end

    # Java: float2String
    private def float_to_string(value : Float32) : String
      FloatString.float_to_string(value)
    end

    # Extract content text from a COS content (stream or array of streams)
    private def extract_content_text(contents : Cos::Base?) : String
      return "" unless contents

      if contents.is_a?(Cos::Stream)
        String.new(contents.create_input_stream.getb_to_end)
      elsif contents.is_a?(Cos::Array)
        parts = [] of String
        contents.each do |item|
          if item.is_a?(Cos::Stream)
            parts << String.new(item.create_input_stream.getb_to_end)
          end
        end
        parts.join
      else
        ""
      end
    end

    # Create a COS stream from a string
    private def create_stream(content : String) : Cos::Stream
      stream = Cos::Stream.new
      stream.data = content.to_slice
      stream[Cos::Name.new("Length")] = Cos::Integer.new(content.bytesize)
      stream
    end

    # Java: loadPDF
    private def load_pdf(filename : String) : Pdmodel::Document
      Pdmodel::Document.load(filename)
    end
  end

  # Float to string conversion matching Java PDFBox format
  module FloatString
    def self.float_to_string(value : Float32 | Float64) : String
      if value == value.round
        value.round.to_i.to_s
      else
        formatted = "%.6f" % value
        # Remove trailing zeros like Java
        formatted = formatted.rstrip('0')
        formatted = formatted.rstrip('.')
        formatted
      end
    end
  end

  # Minimal PageExtractor parity helper, mirroring the Java API surface used by COSWriterTest.
  class PageExtractor
    @source_document : Pdmodel::Document
    @start_page : Int32
    @end_page : Int32

    def initialize(@source_document : Pdmodel::Document, start_page : Int = 1, end_page : Int? = nil)
      @start_page = start_page.to_i32
      @end_page = (end_page || @source_document.number_of_pages).to_i32
    end

    def start_page : Int32
      @start_page
    end

    def start_page=(value : Int) : Int32
      @start_page = value.to_i32
    end

    def end_page : Int32
      @end_page
    end

    def end_page=(value : Int) : Int32
      @end_page = value.to_i32
    end

    def extract : Pdmodel::Document
      return Pdmodel::Document.create if (@end_page - @start_page + 1) <= 0

      first_page = Math.max(@start_page, 1)
      last_page = Math.min(@end_page, @source_document.number_of_pages)
      return Pdmodel::Document.create if first_page > last_page

      extracted = Pdmodel::Document.create
      (first_page..last_page).each do |page_number|
        page = @source_document.page(page_number - 1)
        next unless page
        page_dict = page.cos_object
        if page_dict
          cloned_page_dict = Cos::Dictionary.new
          page_dict.entries.each do |key, value|
            cloned_page_dict[key] = value
          end
          extracted.add_page(Pdmodel::Page.new(cloned_page_dict))
        else
          extracted.add_page(Pdmodel::Page.new)
        end
      end
      extracted
    end
  end

  # Imports pages as Form XObjects and appends them as optional-content layers.
  # Port of Apache PDFBox multipdf/LayerUtility (portable subset: wrapInSaveRestore,
  # importPageAsForm, appendFormAsLayer).
  class LayerUtility
    def initialize(@target_doc : Pdmodel::Document)
    end

    def document : Pdmodel::Document
      @target_doc
    end

    # Wrap the page's contents in a save/restore pair (q ... Q).
    def wrap_in_save_restore(page : Pdmodel::Page) : Nil
      save = Pdfbox::Cos::Stream.new
      save.create_output_stream.tap do |io|
        io << "q\n"
        io.close
      end
      restore = Pdfbox::Cos::Stream.new
      restore.create_output_stream.tap do |io|
        io << "Q\n"
        io.close
      end

      cos_page = page.cos_object || raise "page missing COS dictionary"
      contents = cos_page[Pdfbox::Cos::Name.new("Contents")]?
      contents = contents.object if contents.is_a?(Pdfbox::Cos::Object)

      case contents
      when Pdfbox::Cos::Stream
        array = Pdfbox::Cos::Array.new
        array.add(save)
        array.add(contents)
        array.add(restore)
        cos_page[Pdfbox::Cos::Name.new("Contents")] = array
      when Pdfbox::Cos::Array
        contents.add(0, save)
        contents.add(restore)
      else
        raise ::IO::Error.new("Contents are unknown type: #{contents.class}")
      end
    end

    # Import a page from a source document as a Form XObject.
    def import_page_as_form(source_doc : Pdmodel::Document, page_number : Int32) : Pdmodel::Graphics::Form::PDFormXObject
      import_page_as_form(source_doc, source_doc.get_page(page_number))
    end

    def import_page_as_form(_source_doc : Pdmodel::Document, page : Pdmodel::Page) : Pdmodel::Graphics::Form::PDFormXObject
      cos_page = page.cos_object || raise "page missing COS dictionary"
      contents = cos_page[Pdfbox::Cos::Name.new("Contents")]?
      contents = contents.object if contents.is_a?(Pdfbox::Cos::Object)

      stream = Pdfbox::Cos::Stream.new
      copy_contents(stream, contents)
      form = Pdmodel::Graphics::Form::PDFormXObject.new(stream)

      if resources = page.resources
        form.resources = Pdfbox::Pdmodel::PDResources.new(resources.cos_object)
      end

      view_box = page.crop_box || page.media_box
      if view_box
        form.bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(
          view_box.lower_left_x.to_f32,
          view_box.lower_left_y.to_f32,
          view_box.width.to_f32,
          view_box.height.to_f32
        )
      end
      form
    end

    # Append a form over the page as an optional-content layer (marked content /OC
    # plus an OCG added to the catalog OCProperties).
    def append_form_as_layer(target_page : Pdmodel::Page, form : Pdmodel::Graphics::Form::PDFormXObject,
                             transform : Pdfbox::Util::Matrix, layer_name : String) : Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup
      catalog = @target_doc.document_catalog || raise "document has no catalog"
      ocprops = catalog.oc_properties
      unless ocprops
        ocprops = Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new
        catalog.oc_properties = ocprops
      end
      if ocprops.has_group?(layer_name)
        raise ArgumentError.new("Optional group (layer) already exists: #{layer_name}")
      end

      layer = Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new(layer_name)
      ocprops.add_group(layer)

      content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(
        @target_doc, target_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, false
      )
      content_stream.begin_marked_content(Pdfbox::Cos::Name.new("OC"), layer)
      content_stream.save_graphics_state
      content_stream.transform(transform)
      content_stream.draw_form(form)
      content_stream.restore_graphics_state
      content_stream.end_marked_content
      content_stream.close

      layer
    end

    private def copy_contents(target : Pdfbox::Cos::Stream, contents : Pdfbox::Cos::Base?) : Nil
      data = case contents
             when Pdfbox::Cos::Stream
               contents.data
             when Pdfbox::Cos::Array
               buffer = ::IO::Memory.new
               contents.items.each do |item|
                 item = item.object if item.is_a?(Pdfbox::Cos::Object)
                 buffer.write(item.data) if item.is_a?(Pdfbox::Cos::Stream)
               end
               buffer.to_slice
             else
               Bytes.empty
             end
      target.data = data
    end
  end

  # Deep-clones COS objects into a destination document.
  # Port of Apache PDFBox multipdf/PDFCloneUtility.
  class PDFCloneUtility
    def initialize(@destination : Pdmodel::Document)
      @cloned_version = {} of UInt64 => Pdfbox::Cos::Base
      @cloned_values = Set(UInt64).new
    end

    def destination : Pdmodel::Document
      @destination
    end

    # Deep-clone a COS object into the destination document, remapping indirect
    # references. Java PDFCloneUtility#cloneForNewDocument.
    def clone_for_new_document(base : Pdfbox::Cos::Base?) : Pdfbox::Cos::Base?
      return nil unless base

      if existing = @cloned_version[base.object_id]?
        return existing
      end
      # Don't clone a clone.
      return base if @cloned_values.includes?(base.object_id)

      retval = clone_cos_base_for_new_document(base)
      @cloned_version[base.object_id] = retval
      @cloned_values << retval.object_id
      retval
    end

    # Merge the members of base into target (Java PDFCloneUtility#cloneMerge).
    def clone_merge(base : Pdfbox::Pdmodel::Common::COSObjectable, target : Pdfbox::Pdmodel::Common::COSObjectable) : Nil
      return if base.same?(target)

      clone_merge_cos_base(base.cos_object, target.cos_object)
    end

    private def clone_cos_base_for_new_document(base : Pdfbox::Cos::Base) : Pdfbox::Cos::Base
      case base
      when Pdfbox::Cos::Object
        clone_for_new_document(base.object) || Pdfbox::Cos::Null.instance
      when Pdfbox::Cos::Array
        clone_cos_array(base)
      when Pdfbox::Cos::Stream
        clone_cos_stream(base)
      when Pdfbox::Cos::Dictionary
        clone_cos_dictionary(base)
      else
        base
      end
    end

    private def clone_cos_array(array : Pdfbox::Cos::Array) : Pdfbox::Cos::Array
      new_array = Pdfbox::Cos::Array.new
      array.items.each do |value|
        if has_self_reference(array, value)
          new_array.add(new_array)
        else
          new_array.add(clone_for_new_document(value) || Pdfbox::Cos::Null.instance)
        end
      end
      new_array
    end

    private def clone_cos_stream(stream : Pdfbox::Cos::Stream) : Pdfbox::Cos::Stream
      new_stream = Pdfbox::Cos::Stream.new
      new_stream.data = stream.data
      @cloned_version[stream.object_id] = new_stream
      stream.entries.each do |key, value|
        if has_self_reference(stream, value)
          new_stream[key] = new_stream
        else
          new_stream[key] = clone_for_new_document(value) || Pdfbox::Cos::Null.instance
        end
      end
      new_stream
    end

    private def clone_cos_dictionary(dictionary : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Dictionary
      new_dictionary = Pdfbox::Cos::Dictionary.new
      @cloned_version[dictionary.object_id] = new_dictionary
      dictionary.entries.each do |key, value|
        if has_self_reference(dictionary, value)
          new_dictionary[key] = new_dictionary
        else
          new_dictionary[key] = clone_for_new_document(value) || Pdfbox::Cos::Null.instance
        end
      end
      new_dictionary
    end

    private def clone_merge_cos_base(source : Pdfbox::Cos::Base, target : Pdfbox::Cos::Base) : Nil
      source_base = source.is_a?(Pdfbox::Cos::Object) ? source.object : source
      target_base = target.is_a?(Pdfbox::Cos::Object) ? target.object : target
      return unless source_base && target_base

      if source_base.is_a?(Pdfbox::Cos::Array) && target_base.is_a?(Pdfbox::Cos::Array)
        source_base.items.each do |value|
          target_base.add(clone_for_new_document(value) || Pdfbox::Cos::Null.instance)
        end
      elsif source_base.is_a?(Pdfbox::Cos::Dictionary) && target_base.is_a?(Pdfbox::Cos::Dictionary)
        source_base.entries.each do |key, value|
          if existing = target_base[key]?
            clone_merge_cos_base(value, existing)
          else
            target_base[key] = clone_for_new_document(value) || Pdfbox::Cos::Null.instance
          end
        end
      end
    end

    # True if an array/dictionary element refers back to its parent.
    private def has_self_reference(parent : Pdfbox::Cos::Base, value : Pdfbox::Cos::Base) : Bool
      if value.is_a?(Pdfbox::Cos::Object)
        actual = value.object
        return true if actual && actual.same?(parent)
      end
      false
    end
  end

  # Merges PDF documents, appending one document's pages into another.
  # Port of Apache PDFBox multipdf/PDFMergerUtility (portable subset:
  # appendDocument(destination, source) and mergeDocuments).
  class PDFMergerUtility
    enum AcroFormMergeMode
      PDFBOX_LEGACY_MODE
      JOIN_FIELDS_MODE
    end

    @sources = [] of Pdmodel::Document
    @destination_file_name : String?
    @acro_form_merge_mode : AcroFormMergeMode = AcroFormMergeMode::PDFBOX_LEGACY_MODE

    def destination_file_name : String?
      @destination_file_name
    end

    def destination_file_name=(value : String?) : String?
      @destination_file_name = value
    end

    def acro_form_merge_mode : AcroFormMergeMode
      @acro_form_merge_mode
    end

    def acro_form_merge_mode=(value : AcroFormMergeMode) : AcroFormMergeMode
      @acro_form_merge_mode = value
    end

    # Register a source file to be merged (Java PDFMergerUtility#addSource).
    def add_source(path : String) : Nil
      @sources << Pdfbox::Loader.load_pdf(path)
    end

    def add_source(document : Pdmodel::Document) : Nil
      @sources << document
    end

    # Merge all sources into the destination file (Java PDFMergerUtility#mergeDocuments).
    def merge_documents(destination_file : String? = nil) : Nil
      out_path = @destination_file_name || destination_file
      raise ArgumentError.new("destination file name is not set") unless out_path

      destination = Pdmodel::Document.create
      @sources.each { |source| append_document(destination, source) }
      destination.save(out_path)
      destination.close
    end

    # Append all pages of source into destination (Java PDFMergerUtility#appendDocument).
    def append_document(destination : Pdmodel::Document, source : Pdmodel::Document) : Nil
      return if destination.same?(source)

      cloner = PDFCloneUtility.new(destination)
      merge_information(destination, source, cloner)
      source.pages.to_a.each do |page|
        page_dict = page.cos_object
        next unless page_dict

        cloned = cloner.clone_for_new_document(page_dict)
        next unless cloned

        cloned_dict = cloned.as(Pdfbox::Cos::Dictionary)
        # The clone carries the source /Parent; the destination tree sets it.
        cloned_dict.delete(Pdfbox::Cos::Name.new("Parent"))
        destination.add_page(Pdmodel::Page.new(cloned_dict))
      end

      merge_acro_forms(destination, source, cloner)

      source_catalog = source.document_catalog
      destination_catalog = destination.document_catalog
      if source_catalog && destination_catalog
        # Merge the optional content properties if the destination has none.
        if destination_catalog.oc_properties.nil? && (source_ocp = source_catalog.oc_properties)
          cloned_dict = cloner.clone_for_new_document(source_ocp.cos_object).as(Pdfbox::Cos::Dictionary)
          destination_catalog.oc_properties = Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new(cloned_dict)
        end

        # Merge the named destinations (/Dests). Java cloneMerge / clone.
        if source_dests = source_catalog.dests
          if dest_dests = destination_catalog.dests
            cloner.clone_merge(source_dests, dest_dests)
          else
            cloned = cloner.clone_for_new_document(source_dests.cos_object).as(Pdfbox::Cos::Dictionary)
            destination_catalog.cos_object[Pdfbox::Cos::Name.new("Dests")] = cloned
          end
        end

        merge_open_action(destination_catalog, source_catalog, cloner)
      end
    end

    # Merge simple and nested entries of the source document information into the
    # destination (deep-cloning values). Java PDFMergerUtility#mergeInto used by
    # appendDocument for the /Info dictionary.
    private def merge_information(destination : Pdmodel::Document, source : Pdmodel::Document, cloner : PDFCloneUtility) : Nil
      src_info = source.document_information
      return unless src_info

      dest_info = destination.document_information
      dest_dict = dest_info.try(&.cos_object) || Cos::Dictionary.new
      src_info.cos_object.entries.each do |key, value|
        next if dest_dict.has_key?(key)
        cloned = cloner.clone_for_new_document(value)
        dest_dict[key] = cloned || Cos::Null::INSTANCE
      end
      destination.set_document_information(Pdmodel::DocumentInformation.new(dest_dict)) unless dest_info
    end

    # Copy the source /OpenAction into the destination if it has none. Java
    # PDFMergerUtility#mergeOpenAction.
    private def merge_open_action(destination_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                                  cloner : PDFCloneUtility) : Nil
      return if destination_catalog.open_action

      source_action = source_catalog.open_action
      return unless source_action

      cloned = cloner.clone_for_new_document(source_action.cos_object)
      return unless cloned

      open_action = case cloned
                    when Pdfbox::Cos::Dictionary
                      Pdfbox::Pdmodel::Interactive::Action::PDActionFactory.create_action(cloned)
                    when Pdfbox::Cos::Array
                      Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDDestination.create(cloned)
                    end
      return unless open_action

      destination_catalog.open_action = open_action
    end

    # Merge the source AcroForm into the destination. Legacy mode keeps unique
    # fully-qualified field names (Java PDFMergerUtility#mergeAcroForm legacy).
    private def merge_acro_forms(destination : Pdmodel::Document, source : Pdmodel::Document, cloner : PDFCloneUtility) : Nil
      source_form = source.document_catalog.try(&.acro_form)
      return unless source_form

      catalog = destination.document_catalog
      return unless catalog

      destination_form = catalog.acro_form
      if destination_form.nil?
        cloned = cloner.clone_for_new_document(source_form.cos_object).as(Pdfbox::Cos::Dictionary)
        catalog.acro_form = Pdmodel::Interactive::Form::PDAcroForm.new(destination, cloned)
        return
      end

      # Java PDFMergerUtility#acroFormLegacyMode: clone every source root field,
      # renaming ones that clash with an existing FQN to a unique dummyFieldNameN.
      src_fields = source_form.fields
      return if src_fields.empty?

      prefix = "dummyFieldName"
      next_num = 1
      destination_form.get_field_tree.each do |field|
        name = field.partial_name
        next unless name && name.starts_with?(prefix)

        suffix = name[prefix.size..]
        next_num = Math.max(next_num, suffix.to_i + 1) if suffix.matches?(/\A\d+\z/)
      end

      fields_base = destination_form.cos_object[Pdfbox::Cos::Name.new("Fields")]?
      fields_base = fields_base.object if fields_base.is_a?(Pdfbox::Cos::Object)
      dest_fields = fields_base.as?(Pdfbox::Cos::Array) || Pdfbox::Cos::Array.new

      src_fields.each do |src_field|
        cloned = cloner.clone_for_new_document(src_field.cos_object).as(Pdfbox::Cos::Dictionary)
        if destination_form.get_field(src_field.fully_qualified_name)
          cloned.set_string("T", "#{prefix}#{next_num}")
          next_num += 1
        end
        dest_fields.add(cloned)
      end
      destination_form.cos_object[Pdfbox::Cos::Name.new("Fields")] = dest_fields
    end

    # Flatten a number tree into a single map. Java PDFMergerUtility#getNumberTreeAsMap.
    def self.get_number_tree_as_map(tree : Pdmodel::Common::PDNumberTreeNode(T)?) : Hash(Int32, T) forall T
      result = {} of Int32 => T
      return result unless tree

      if numbers = tree.numbers
        numbers.each { |key, value| result[key] = value }
      end
      if kids = tree.kids
        kids.size.times do |i|
          get_number_tree_as_map(kids.get(i)).each { |key, value| result[key] = value }
        end
      end
      result
    end

    # Flatten a name tree of structure elements. Java PDFMergerUtility#getIDTreeAsMap.
    def self.get_id_tree_as_map(tree : Pdmodel::Common::PDNameTreeNode(
                                  Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement,
                                )?) : Hash(String, Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement)
      result = {} of String => Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement
      return result unless tree

      if names = tree.names
        names.each { |key, value| result[key] = value }
      end
      if kids = tree.kids
        kids.size.times do |i|
          get_id_tree_as_map(kids.get(i)).each { |key, value| result[key] = value }
        end
      end
      result
    end
  end
end
