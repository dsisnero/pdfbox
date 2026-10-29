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
    # Java: rotatedDefaultOverlayPagesMap
    @rotated_default_overlay_pages_map = {} of Int32 => LayoutPage
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

    def default_overlay_pdf=(document : Pdmodel::Document) : Nil
      @default_overlay_document = document
      @default_overlay_page = create_layout_page_from_document(document)
    end

    # Java: setFirstPageOverlayPDF(PDDocument)
    def first_page_overlay_pdf=(document : Pdmodel::Document) : Nil
      @first_page_overlay_document = document
      @first_page_overlay_page = create_layout_page_from_document(document)
    end

    # Java: setLastPageOverlayPDF(PDDocument)
    def last_page_overlay_pdf=(document : Pdmodel::Document) : Nil
      @last_page_overlay_document = document
      @last_page_overlay_page = create_layout_page_from_document(document)
    end

    # Java: setOddPageOverlayPDF(PDDocument)
    def odd_page_overlay_pdf=(document : Pdmodel::Document) : Nil
      @odd_page_overlay_document = document
      @odd_page_overlay_page = create_layout_page_from_document(document)
    end

    # Java: setEvenPageOverlayPDF(PDDocument)
    def even_page_overlay_pdf=(document : Pdmodel::Document) : Nil
      @even_page_overlay_document = document
      @even_page_overlay_page = create_layout_page_from_document(document)
    end

    # Java: setAllPagesOverlayPDF(PDDocument)
    def all_pages_overlay_pdf=(document : Pdmodel::Document) : Nil
      @all_pages_overlay_document = document
      @specific_page_overlay_layout_page_map = create_page_overlay_layout_page_map(document)
      @use_all_overlay_pages = true
      @number_of_overlay_pages = @specific_page_overlay_layout_page_map.size
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

    # Java: overlayDocuments(Map<Integer, PDDocument>). Adds the given overlay
    # documents to specific (1-based) pages of the input document and returns it.
    def overlay_documents(specific_page_overlay_document_map : Hash(Int32, Pdmodel::Document)) : Pdmodel::Document
      load_pdfs

      specific_page_overlay_document_map.each do |page_num, doc|
        @specific_page_overlay_layout_page_map[page_num] = create_layout_page_from_document(doc)
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
      contents = contents.object if contents.is_a?(Cos::Object)
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
        # PDFBOX-6049: consider the rotation of the document page
        if @adjust_rotation
          if input_document = @input_pdf_document
            rotation = input_document.get_page(page_number - 1).rotation
            return create_adjusted_layout_page(rotation) if rotation != 0
          end
        end
        return lp
      end

      if @use_all_overlay_pages
        use_page_num = (page_number - 1) % @number_of_overlay_pages
        return @specific_page_overlay_layout_page_map[use_page_num]?
      end

      nil
    end

    # Java: createAdjustedLayoutPage(int)
    private def create_adjusted_layout_page(rotation : Int32) : LayoutPage?
      if cached = @rotated_default_overlay_pages_map[rotation]?
        return cached
      end

      # createLayoutPage must be called because we can't reuse the COSStream
      overlay_document = @default_overlay_document
      return nil unless overlay_document

      rotated_layout_page = create_layout_page(overlay_document.get_page(0))
      new_rotation = (rotated_layout_page.overlay_rotation - rotation + 360) % 360
      rotated_layout_page.overlay_rotation = new_rotation
      @rotated_default_overlay_pages_map[rotation] = rotated_layout_page
      rotated_layout_page
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

      # Java: AffineTransform#translate followed by #quadrantRotate, flattened
      # into a b c d e f. Rotation 90 rotates by 270 and translates by the width;
      # rotation 270 rotates by 90 and translates by the height.
      rotation = layout_page.overlay_rotation
      case rotation
      when 90
        matrix = Cos::Array.new([
          Cos::Float.new(0.0_f64),
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(layout_page.overlay_media_box.width.to_f64),
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
          Cos::Float.new(1.0_f64),
          Cos::Float.new(-1.0_f64),
          Cos::Float.new(0.0_f64),
          Cos::Float.new(layout_page.overlay_media_box.height.to_f64),
          Cos::Float.new(0.0_f64),
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
      # Java writes AffineTransform#getMatrix's flat a b c d e f, so the
      # calculated translate(hShift, vShift) is written as 1 0 0 1 h v.
      content = String.build do |io|
        io << "q\nq\n"
        io << FloatString.float_to_string(1.0_f32) << ' '
        io << FloatString.float_to_string(0.0_f32) << ' '
        io << FloatString.float_to_string(0.0_f32) << ' '
        io << FloatString.float_to_string(1.0_f32) << ' '
        io << FloatString.float_to_string(h_shift) << ' '
        io << FloatString.float_to_string(v_shift) << ' '
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
      contents = contents.object if contents.is_a?(Cos::Object)
      return "" unless contents

      if contents.is_a?(Cos::Stream)
        return "" unless contents.has_data
        String.new(contents.create_input_stream.getb_to_end)
      elsif contents.is_a?(Cos::Array)
        parts = [] of String
        contents.each do |item|
          item = item.object if item.is_a?(Cos::Object)
          if item.is_a?(Cos::Stream) && item.has_data
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

    # Java PDFMergerUtility.DocumentMergeMode.
    enum DocumentMergeMode
      OPTIMIZE_RESOURCES_MODE
      PDFBOX_LEGACY_MODE
    end

    @sources = [] of Pdmodel::Document
    @destination_file_name : String?
    @destination_stream : ::IO?
    @acro_form_merge_mode : AcroFormMergeMode = AcroFormMergeMode::PDFBOX_LEGACY_MODE
    @document_merge_mode : DocumentMergeMode = DocumentMergeMode::OPTIMIZE_RESOURCES_MODE
    @destination_document_information : Pdmodel::DocumentInformation?
    @destination_metadata : Pdmodel::Common::PDMetadata?
    @ignore_acro_form_errors = false

    def document_merge_mode : DocumentMergeMode
      @document_merge_mode
    end

    def document_merge_mode=(value : DocumentMergeMode) : DocumentMergeMode
      @document_merge_mode = value
    end

    def destination_document_information : Pdmodel::DocumentInformation?
      @destination_document_information
    end

    def destination_document_information=(value : Pdmodel::DocumentInformation?) : Pdmodel::DocumentInformation?
      @destination_document_information = value
    end

    def destination_metadata : Pdmodel::Common::PDMetadata?
      @destination_metadata
    end

    def destination_metadata=(value : Pdmodel::Common::PDMetadata?) : Pdmodel::Common::PDMetadata?
      @destination_metadata = value
    end

    def ignore_acro_form_errors? : Bool
      @ignore_acro_form_errors
    end

    def ignore_acro_form_errors=(value : Bool) : Bool
      @ignore_acro_form_errors = value
    end

    def destination_file_name : String?
      @destination_file_name
    end

    def destination_file_name=(value : String?) : String?
      @destination_file_name = value
    end

    def destination_stream : ::IO?
      @destination_stream
    end

    def destination_stream=(value : ::IO?) : ::IO?
      @destination_stream = value
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

    # Register multiple source documents (Java PDFMergerUtility#addSources).
    def add_sources(sources : Enumerable(Pdmodel::Document)) : Nil
      sources.each { |source| @sources << source }
    end

    # Merge all sources into the destination file (Java PDFMergerUtility#mergeDocuments).
    def merge_documents(destination_file : String? = nil) : Nil
      out_path = @destination_file_name || destination_file
      out_stream = @destination_stream
      raise ArgumentError.new("destination file name is not set") unless out_path || out_stream

      destination = Pdmodel::Document.create
      @sources.each { |source| append_document(destination, source) }

      # Java mergeDocuments applies the configured destination info/metadata.
      if info = @destination_document_information
        destination.set_document_information(info)
      end
      if meta = @destination_metadata
        destination.document_catalog.try(&.metadata = meta)
      end

      if out_stream
        destination.save(out_stream)
      elsif out_path
        destination.save(out_path)
      end
      destination.close
    end

    # Append all pages of source into destination (Java PDFMergerUtility#appendDocument).
    def append_document(destination : Pdmodel::Document, source : Pdmodel::Document) : Nil
      return if destination.same?(source)

      cloner = PDFCloneUtility.new(destination)
      merge_information(destination, source, cloner)

      source_catalog = source.document_catalog
      dest_catalog = destination.document_catalog
      return unless source_catalog && dest_catalog

      destination.set_version(source.version) if destination.version < source.version

      merge_acro_forms(destination, source, cloner)
      merge_threads(dest_catalog, source_catalog, cloner)
      merge_names(dest_catalog, source_catalog, cloner)
      merge_dests(dest_catalog, source_catalog, cloner)
      merge_outline(dest_catalog, source_catalog, cloner)
      merge_page_mode(dest_catalog, source_catalog)
      merge_page_labels(destination, dest_catalog, source_catalog, cloner)
      merge_metadata(dest_catalog, source_catalog, cloner)
      merge_output_intents(source_catalog, dest_catalog, cloner)
      merge_oc_properties(dest_catalog, source_catalog, cloner)
      merge_pages_and_structure(destination, source, cloner)
    end

    # Java PDFMergerUtility#appendDocument page label merge: append the source
    # /PageLabels /Nums with the destination page count as an offset.
    private def merge_page_labels(destination : Pdmodel::Document, dest_catalog : Pdmodel::DocumentCatalog,
                                  source_catalog : Pdmodel::DocumentCatalog, cloner : PDFCloneUtility) : Nil
      src_labels = source_catalog.cos_object.get_dictionary(Cos::Name::PAGE_LABELS)
      return unless src_labels

      dest_page_count = destination.pages.size
      dest_labels = dest_catalog.cos_object.get_dictionary(Cos::Name::PAGE_LABELS)
      dest_nums : Cos::Array
      if dest_labels.nil?
        dest_labels = Cos::Dictionary.new
        dest_nums = Cos::Array.new
        dest_labels[Cos::Name.new("Nums")] = dest_nums
        dest_catalog.cos_object[Cos::Name::PAGE_LABELS] = dest_labels
      else
        dest_nums = dest_labels.get_array(Cos::Name.new("Nums")) || Cos::Array.new
        dest_labels[Cos::Name.new("Nums")] = dest_nums
      end

      src_nums = src_labels.get_array(Cos::Name.new("Nums"))
      return unless src_nums

      start_size = dest_nums.size
      index = 0
      while index < src_nums.size
        base = src_nums[index]?
        base = base.object if base.is_a?(Cos::Object)
        label_index = case base
                      when Cos::Integer then base.value
                      when Cos::Float   then base.value.to_i64
                      else
                        nil
                      end
        if label_index.nil?
          # remove what we added
          while dest_nums.size > start_size
            dest_nums.remove(start_size)
          end
          break
        end
        dest_nums.add(Cos::Integer.new(label_index + dest_page_count))
        cloned = cloner.clone_for_new_document(src_nums[index + 1]?)
        dest_nums.add(cloned || Cos::Null::INSTANCE)
        index += 2
      end
    end

    # Java PDFMergerUtility#appendDocument metadata merge: when the destination
    # has no /Metadata, create a new unfiltered stream from the source's decoded
    # metadata and copy its dictionary (except /Filter and /Length).
    private def merge_metadata(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                               cloner : PDFCloneUtility) : Nil
      return unless dest_catalog.cos_object.get_stream(Cos::Name::METADATA).nil?

      src_metadata = source_catalog.cos_object.get_stream(Cos::Name::METADATA)
      return unless src_metadata

      new_stream = Cos::Stream.new
      if src_metadata.has_data
        new_stream.data = src_metadata.create_input_stream.getb_to_end
      end
      merge_into(src_metadata, new_stream, cloner, Set{Cos::Name::FILTER, Cos::Name::LENGTH})
      dest_catalog.cos_object[Cos::Name::METADATA] = new_stream
    end

    # Java PDFMergerUtility#mergeOutputIntents.
    private def merge_output_intents(source_catalog : Pdmodel::DocumentCatalog,
                                     dest_catalog : Pdmodel::DocumentCatalog, cloner : PDFCloneUtility) : Nil
      src_intents = source_catalog.output_intents
      return if src_intents.empty?

      dst_intents = dest_catalog.output_intents
      src_intents.each do |src_intent|
        identifier = src_intent.output_condition_identifier
        if identifier && identifier != "Custom"
          next if dst_intents.any? { |dst_intent| dst_intent.output_condition_identifier == identifier }
        end
        cloned = cloner.clone_for_new_document(src_intent.cos_object)
        next unless cloned
        dest_catalog.add_output_intent(Pdmodel::OutputIntent.new(cloned.as(Cos::Dictionary)))
      end
    end

    private def merge_threads(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                              cloner : PDFCloneUtility) : Nil
      src_threads = source_catalog.cos_object.get_dictionary_object(Cos::Name.new("Threads"))
      return unless src_threads

      cloned = cloner.clone_for_new_document(src_threads)
      dest_threads = dest_catalog.cos_object.get_dictionary_object(Cos::Name.new("Threads"))
      if dest_threads.nil?
        dest_catalog.cos_object[Cos::Name.new("Threads")] = cloned || Cos::Null::INSTANCE
      elsif cloned.is_a?(Cos::Array) && dest_threads.is_a?(Cos::Array)
        cloned.items.each { |item| dest_threads.add(item) }
      end
    end

    private def merge_names(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                            cloner : PDFCloneUtility) : Nil
      source_names = source_catalog.names
      if source_names
        if dest_names = dest_catalog.names
          cloner.clone_merge(source_names, dest_names)
        else
          cloned = cloner.clone_for_new_document(source_names.cos_object)
          dest_catalog.cos_object[Cos::Name.new("Names")] = cloned || Cos::Null::INSTANCE
        end
      end
      # Java: an /IDTree under /Names doesn't belong there.
      if (dest_names = dest_catalog.names) && dest_names.cos_object.has_key?(Cos::Name::ID_TREE)
        dest_names.cos_object.delete(Cos::Name::ID_TREE)
      end
    end

    private def merge_dests(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                            cloner : PDFCloneUtility) : Nil
      source_dests = source_catalog.dests
      return unless source_dests

      if dest_dests = dest_catalog.dests
        cloner.clone_merge(source_dests, dest_dests)
      else
        cloned = cloner.clone_for_new_document(source_dests.cos_object)
        dest_catalog.cos_object[Cos::Name.new("Dests")] = cloned || Cos::Null::INSTANCE
      end
    end

    private def merge_outline(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                              cloner : PDFCloneUtility) : Nil
      source_outline = source_catalog.document_outline
      return unless source_outline

      dest_outline = dest_catalog.document_outline
      if dest_outline.nil? || dest_outline.first_child.nil?
        cloned = cloner.clone_for_new_document(source_outline.cos_object)
        return unless cloned

        dest_catalog.document_outline = Pdmodel::DocumentOutline.new(cloned.as(Cos::Dictionary))
        return
      end

      # Java: search the last sibling (the /Last entry is sometimes wrong) and
      # insert each cloned source child after it.
      dest_last = dest_outline.first_child
      return unless dest_last

      while sibling = dest_last.next_sibling
        dest_last = sibling
      end

      src_item = source_outline.first_child
      while src_item
        cloned = cloner.clone_for_new_document(src_item.cos_object)
        next_item = src_item.next_sibling
        if cloned
          cloned_dict = cloned.as(Cos::Dictionary)
          cloned_dict.delete(Cos::Name::PREV)
          cloned_dict.delete(Cos::Name::NEXT)
          cloned_item = Pdmodel::OutlineItem.new(cloned_dict)
          dest_last.next_sibling = cloned_item
          cloned_dict[Cos::Name::PREV] = dest_last.cos_object
          dest_last = cloned_item
        end
        src_item = next_item
      end
      dest_outline.cos_object[Cos::Name.new("Last")] = dest_last.cos_object
    end

    private def merge_page_mode(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog) : Nil
      name = Cos::Name.new("PageMode")
      return unless dest_catalog.cos_object.get_dictionary_object(name).nil?

      if src_mode = source_catalog.cos_object.get_dictionary_object(name)
        dest_catalog.cos_object[name] = src_mode
      end
    end

    private def merge_oc_properties(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                                    cloner : PDFCloneUtility) : Nil
      if dest_catalog.oc_properties.nil? && (source_ocp = source_catalog.oc_properties)
        cloned = cloner.clone_for_new_document(source_ocp.cos_object)
        dest_catalog.oc_properties = Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new(cloned.as(Cos::Dictionary)) if cloned
      end
    end

    # Clone source pages and merge the logical structure hierarchy.
    # Java PDFMergerUtility#appendDocument (page loop + structure tree merge).
    private def merge_pages_and_structure(destination : Pdmodel::Document, source : Pdmodel::Document,
                                          cloner : PDFCloneUtility) : Nil
      source_catalog = source.document_catalog
      return unless source_catalog
      dest_catalog = destination.document_catalog
      return unless dest_catalog

      merge_struct_tree = false
      dest_parent_tree_next_key = -1
      src_number_tree_as_map = {} of Int32 => Pdmodel::Common::PDParentTreeValue
      dest_number_tree_as_map = {} of Int32 => Pdmodel::Common::PDParentTreeValue

      src_struct_tree = source_catalog.structure_tree_root
      dest_struct_tree = dest_catalog.structure_tree_root
      if dest_struct_tree.nil? && src_struct_tree
        # Create a dummy structure tree so the source tree is cloned.
        dest_struct_tree = Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot.new
        dest_catalog.structure_tree_root = dest_struct_tree
        dest_struct_tree.parent_tree = new_parent_tree_node
        # PDFBOX-4429: remove bogus StructParent(s) from the destination.
        destination.pages.each do |page|
          page.cos_object.try(&.delete(Cos::Name::STRUCT_PARENTS))
          page.annotations.each { |annot| annot.cos_object.delete(Cos::Name::STRUCT_PARENT) }
        end
      end

      if dest_struct_tree
        dest_parent_tree = dest_struct_tree.parent_tree
        dest_parent_tree_next_key = dest_struct_tree.parent_tree_next_key
        if dest_parent_tree
          dest_number_tree_as_map = PDFMergerUtility.get_number_tree_as_map(dest_parent_tree)
          if dest_parent_tree_next_key < 0
            dest_parent_tree_next_key = dest_number_tree_as_map.empty? ? 0 : dest_number_tree_as_map.keys.max + 1
          end
          if dest_parent_tree_next_key >= 0 && src_struct_tree
            src_parent_tree = src_struct_tree.parent_tree
            if src_parent_tree
              src_number_tree_as_map = PDFMergerUtility.get_number_tree_as_map(src_parent_tree)
              merge_struct_tree = true unless src_number_tree_as_map.empty?
            end
          end
        end
      end

      obj_mapping = {} of UInt64 => Cos::Dictionary
      source.pages.each do |page|
        page_dict = page.cos_object
        next unless page_dict

        cloned = cloner.clone_for_new_document(page_dict)
        next unless cloned

        new_page_dict = cloned.as(Cos::Dictionary)
        new_page = Pdmodel::Page.new(new_page_dict)
        unless merge_struct_tree
          new_page_dict.delete(Cos::Name::STRUCT_PARENTS)
          new_page.annotations.each { |annot| annot.cos_object.delete(Cos::Name::STRUCT_PARENT) }
        end
        if crop = page.crop_box
          new_page.crop_box = Pdmodel::Rectangle.new(crop.lower_left_x, crop.lower_left_y, crop.upper_right_x, crop.upper_right_y)
        end
        if media = page.media_box
          new_page.media_box = Pdmodel::Rectangle.new(media.lower_left_x, media.lower_left_y, media.upper_right_x, media.upper_right_y)
        end
        new_page.rotation = page.rotation
        if resources = page.resources
          cloned_resources = cloner.clone_for_new_document(resources.cos_object)
          new_page.resources = cloned_resources ? Pdmodel::Resources.new(cloned_resources.as(Cos::Dictionary)) : Pdmodel::Resources.new
        else
          new_page.resources = Pdmodel::Resources.new
        end
        if merge_struct_tree
          update_struct_parent_entries(new_page, dest_parent_tree_next_key)
          obj_mapping[page_dict.object_id.to_u64] = new_page_dict
          old_annotations = page.annotations
          new_annotations = new_page.annotations
          old_annotations.size.times do |index|
            next if index >= new_annotations.size
            obj_mapping[old_annotations.get(index).cos_object.object_id.to_u64] = new_annotations.get(index).cos_object
          end
        end
        destination.add_page(new_page)
      end

      merge_open_action(dest_catalog, source_catalog, cloner)

      return unless merge_struct_tree && src_struct_tree && dest_struct_tree

      update_page_references(cloner, src_number_tree_as_map, obj_mapping)
      max_src_key = -1
      src_number_tree_as_map.each do |src_key, value|
        max_src_key = Math.max(src_key, max_src_key)
        cloned_value = cloner.clone_for_new_document(value.cos_object)
        next unless cloned_value
        dest_number_tree_as_map[dest_parent_tree_next_key + src_key] = Pdmodel::Common::PDParentTreeValue.new(cloned_value)
      end
      dest_parent_tree_next_key += max_src_key + 1
      new_parent_tree = new_parent_tree_node
      new_parent_tree.numbers = dest_number_tree_as_map
      dest_struct_tree.parent_tree = new_parent_tree
      dest_struct_tree.parent_tree_next_key = dest_parent_tree_next_key

      merge_k_entries(cloner, src_struct_tree, dest_struct_tree)
      merge_role_map(src_struct_tree, dest_struct_tree, cloner)
      merge_id_tree(cloner, src_struct_tree, dest_struct_tree)
      merge_mark_info(dest_catalog, source_catalog)
      merge_language(dest_catalog, source_catalog)
      merge_viewer_preferences(dest_catalog, source_catalog, cloner)
    end

    private def new_parent_tree_node : Pdmodel::Common::PDNumberTreeNode(Pdmodel::Common::PDParentTreeValue)
      Pdmodel::Common::PDNumberTreeNode(Pdmodel::Common::PDParentTreeValue).new(
        ->(base : Cos::Base) { Pdmodel::Common::PDParentTreeValue.new(base) }
      )
    end

    private def update_struct_parent_entries(page : Pdmodel::Page, offset : Int32) : Nil
      struct_parents = page.struct_parents
      page.struct_parents = struct_parents + offset if struct_parents >= 0
      annotations = page.annotations.to_a
      annotations.each do |annot|
        struct_parent = annot.struct_parent
        annot.struct_parent = struct_parent + offset if struct_parent >= 0
      end
      page.annotations = annotations
    end

    private def update_page_references(cloner : PDFCloneUtility,
                                       number_tree_as_map : Hash(Int32, Pdmodel::Common::PDParentTreeValue),
                                       obj_mapping : Hash(UInt64, Cos::Dictionary)) : Nil
      number_tree_as_map.each_value do |value|
        base = value.cos_object
        if base.is_a?(Cos::Array)
          update_page_references(cloner, base, obj_mapping)
        elsif base.is_a?(Cos::Dictionary)
          update_page_references(cloner, base, obj_mapping)
        end
      end
    end

    private def update_page_references(cloner : PDFCloneUtility, entry : Cos::Dictionary,
                                       obj_mapping : Hash(UInt64, Cos::Dictionary)) : Nil
      if page_dict = entry.get_dictionary(Cos::Name::PG)
        if mapped = obj_mapping[page_dict.object_id.to_u64]?
          entry[Cos::Name::PG] = mapped
        end
      end
      if obj_dict = entry.get_dictionary(Cos::Name::OBJ)
        if mapped = obj_mapping[obj_dict.object_id.to_u64]?
          entry[Cos::Name::OBJ] = mapped
        else
          cloned = cloner.clone_for_new_document(obj_dict)
          entry[Cos::Name::OBJ] = cloned || Cos::Null::INSTANCE
        end
      end
      k_entry = entry.get_dictionary_object(Cos::Name::K)
      if k_entry.is_a?(Cos::Array)
        update_page_references(cloner, k_entry, obj_mapping)
      elsif k_entry.is_a?(Cos::Dictionary)
        update_page_references(cloner, k_entry, obj_mapping)
      end
    end

    private def update_page_references(cloner : PDFCloneUtility, entry : Cos::Array,
                                       obj_mapping : Hash(UInt64, Cos::Dictionary)) : Nil
      entry.items.each do |item|
        item = item.object if item.is_a?(Cos::Object)
        if item.is_a?(Cos::Array)
          update_page_references(cloner, item, obj_mapping)
        elsif item.is_a?(Cos::Dictionary)
          update_page_references(cloner, item, obj_mapping)
        end
      end
    end

    private def merge_k_entries(cloner : PDFCloneUtility,
                                src_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                                dest_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot) : Nil
      src_k_array = Cos::Array.new
      cloned_src = cloner.clone_for_new_document(src_struct_tree.k)
      if cloned_src.is_a?(Cos::Array)
        cloned_src.items.each { |item| src_k_array.add(item) }
      elsif cloned_src.is_a?(Cos::Dictionary)
        src_k_array.add(cloned_src)
      end
      return if src_k_array.empty?

      dst_k_array = Cos::Array.new
      dst_k_entry = dest_struct_tree.k
      if dst_k_entry.is_a?(Cos::Array)
        dst_k_entry.items.each { |item| dst_k_array.add(item) }
      elsif dst_k_entry.is_a?(Cos::Dictionary)
        dst_k_array.add(dst_k_entry)
      end

      if dst_k_array.size == 1
        top = dst_k_array[0]?.as?(Cos::Dictionary)
        if top && top.get_name_as_string(Cos::Name.new("S")) == "Document"
          k_level_one = top.get_array(Cos::Name::K)
          if k_level_one && has_only_documents_or_parts?(k_level_one)
            src_k_array.items.each { |item| k_level_one.add(item) }
            update_parent_entry(k_level_one, top, Cos::Name.new("Part"))
            return
          end
        end
      end

      if dst_k_array.empty?
        update_parent_entry(src_k_array, dest_struct_tree.cos_object, nil)
        dest_struct_tree.k = src_k_array
        return
      end

      src_k_array.items.each { |item| dst_k_array.add(item) }
      k_level_zero = Cos::Dictionary.new
      new_structure_type = has_only_documents_or_parts?(dst_k_array) ? Cos::Name.new("Part") : nil
      update_parent_entry(dst_k_array, k_level_zero, new_structure_type)
      k_level_zero[Cos::Name::K] = dst_k_array
      k_level_zero[Cos::Name::P] = Cos::Object.new(dest_struct_tree.cos_object)
      k_level_zero.set_name(Cos::Name.new("S"), "Document")
      dest_struct_tree.k = k_level_zero
    end

    private def has_only_documents_or_parts?(k_array : Cos::Array) : Bool
      k_array.items.all? do |item|
        item = item.object if item.is_a?(Cos::Object)
        dict = item.as?(Cos::Dictionary)
        next false unless dict
        s = dict.get_name_as_string(Cos::Name.new("S"))
        s == "Document" || s == "Part"
      end
    end

    private def update_parent_entry(k_array : Cos::Array, new_parent : Cos::Base, new_structure_type : Cos::Name?) : Nil
      k_array.items.each do |item|
        item = item.object if item.is_a?(Cos::Object)
        dict = item.as?(Cos::Dictionary)
        next unless dict
        # Wrap the parent in an indirect reference so the /K <-> /P cycle is
        # written as an object reference instead of recursing inline.
        if new_parent.is_a?(Cos::Dictionary)
          dict[Cos::Name::P] = Cos::Object.new(new_parent)
        else
          dict[Cos::Name::P] = new_parent
        end
        dict[Cos::Name::S] = new_structure_type if new_structure_type
      end
    end

    private def merge_role_map(src_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                               dest_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                               cloner : PDFCloneUtility) : Nil
      src_dict = src_struct_tree.cos_object.get_dictionary(Cos::Name::ROLE_MAP)
      return unless src_dict

      dest_dict = dest_struct_tree.cos_object.get_dictionary(Cos::Name::ROLE_MAP)
      if dest_dict.nil?
        cloned = cloner.clone_for_new_document(src_dict)
        dest_struct_tree.cos_object[Cos::Name::ROLE_MAP] = cloned || Cos::Null::INSTANCE
        return
      end
      src_dict.entries.each do |key, value|
        dest_value = dest_dict.get_dictionary_object(key)
        next if dest_value && dest_value == value
        next if dest_dict.has_key?(key)
        cloned = cloner.clone_for_new_document(value)
        dest_dict[key] = cloned || Cos::Null::INSTANCE
      end
    end

    private def merge_id_tree(cloner : PDFCloneUtility,
                              src_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot,
                              dest_struct_tree : Pdmodel::DocumentInterchange::LogicalStructure::PDStructureTreeRoot) : Nil
      src_id_tree = src_struct_tree.id_tree
      return unless src_id_tree

      dest_id_tree = dest_struct_tree.id_tree
      dest_names = dest_id_tree ? PDFMergerUtility.get_id_tree_as_map(dest_id_tree) : {} of String => Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement
      PDFMergerUtility.get_id_tree_as_map(src_id_tree).each do |key, value|
        next if dest_names.has_key?(key)
        cloned = cloner.clone_for_new_document(value.cos_object)
        next unless cloned
        dest_names[key] = Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(cloned.as(Cos::Dictionary))
      end
      new_dest_id_tree = Pdmodel::Common::PDStructureElementNameTreeNode.new
      new_dest_id_tree.names = dest_names
      dest_struct_tree.id_tree = new_dest_id_tree
    end

    # Java PDFMergerUtility#mergeMarkInfo. Note: PDMarkInfo#setSuspect writes
    # false unconditionally (upstream quirk), so /Suspects is always cleared.
    private def merge_mark_info(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog) : Nil
      dest_mark = dest_catalog.mark_info || Pdmodel::DocumentInterchange::LogicalStructure::PDMarkInfo.new
      src_mark = source_catalog.mark_info || Pdmodel::DocumentInterchange::LogicalStructure::PDMarkInfo.new
      dest_mark.marked = true
      dest_mark.suspect = src_mark.suspect? || dest_mark.suspect?
      dest_mark.uses_user_properties = src_mark.uses_user_properties? || dest_mark.uses_user_properties?
      dest_catalog.mark_info = dest_mark
    end

    private def merge_language(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog) : Nil
      return unless dest_catalog.cos_object.get_dictionary_object(Cos::Name::LANG).nil?

      if src_lang = source_catalog.cos_object.get_dictionary_object(Cos::Name::LANG)
        dest_catalog.cos_object[Cos::Name::LANG] = src_lang
      end
    end

    private def merge_viewer_preferences(dest_catalog : Pdmodel::DocumentCatalog, source_catalog : Pdmodel::DocumentCatalog,
                                         cloner : PDFCloneUtility) : Nil
      name = Cos::Name.new("ViewerPreferences")
      src_vp = source_catalog.cos_object.get_dictionary(name)
      return unless src_vp

      dest_vp = dest_catalog.cos_object.get_dictionary(name) || Cos::Dictionary.new
      merge_into(src_vp, dest_vp, cloner, Set(Cos::Name).new)
      {
        "HideToolbar", "HideMenubar", "HideWindowUI",
        "FitWindow", "CenterWindow", "DisplayDocTitle",
      }.each do |flag|
        flag_name = Cos::Name.new(flag)
        if dict_boolean(src_vp, flag) || dict_boolean(dest_vp, flag)
          dest_vp.set_boolean(flag_name, true)
        end
      end
      dest_catalog.cos_object[name] = dest_vp
    end

    # Java PDFMergerUtility#mergeInto: copy entries not in `exclude` and not
    # already present, deep-cloning values.
    private def merge_into(src : Cos::Dictionary, dst : Cos::Dictionary, cloner : PDFCloneUtility,
                           exclude : Set(Cos::Name)) : Nil
      src.entries.each do |key, value|
        next if exclude.includes?(key)
        next if dst.has_key?(key)
        cloned = cloner.clone_for_new_document(value)
        dst[key] = cloned || Cos::Null::INSTANCE
      end
    end

    private def dict_boolean(dict : Cos::Dictionary, key : String) : Bool
      value = dict.get_dictionary_object(Cos::Name.new(key))
      value.is_a?(Cos::Boolean) && value.value
    end

    # Merge simple and nested entries of the source document information into the
    # destination (deep-cloning values). Java PDFMergerUtility#mergeInto used by
    # appendDocument for the /Info dictionary.
    private def merge_information(destination : Pdmodel::Document, source : Pdmodel::Document, cloner : PDFCloneUtility) : Nil
      # Both accessors are never nil (Java getDocumentInformation), so merging
      # into a document without /Info simply fills the lazily created one.
      src_info = source.document_information
      dest_info = destination.document_information
      dest_dict = dest_info.cos_object
      src_info.cos_object.entries.each do |key, value|
        next if dest_dict.has_key?(key)
        cloned = cloner.clone_for_new_document(value)
        dest_dict[key] = cloned || Cos::Null::INSTANCE
      end
      destination.set_document_information(dest_info)
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
