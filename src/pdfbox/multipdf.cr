require "./pdmodel"

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

    def set_input_file(filename : String) : Nil
      @input_pdf_document = Pdmodel::Document.load(filename)
    end

    def set_input_pdf(document : Pdmodel::Document) : Nil
      @input_pdf_document = document
    end

    def set_default_overlay_file(filename : String) : Nil
      @default_overlay_document = load_pdf(filename)
      if doc = @default_overlay_document
        @default_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def set_first_page_overlay_file(filename : String) : Nil
      @first_page_overlay_document = load_pdf(filename)
      if doc = @first_page_overlay_document
        @first_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def set_last_page_overlay_file(filename : String) : Nil
      @last_page_overlay_document = load_pdf(filename)
      if doc = @last_page_overlay_document
        @last_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def set_odd_page_overlay_file(filename : String) : Nil
      @odd_page_overlay_document = load_pdf(filename)
      if doc = @odd_page_overlay_document
        @odd_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def set_even_page_overlay_file(filename : String) : Nil
      @even_page_overlay_document = load_pdf(filename)
      if doc = @even_page_overlay_document
        @even_page_overlay_page = create_layout_page_from_document(doc)
      end
    end

    def set_all_pages_overlay_file(filename : String) : Nil
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
end
