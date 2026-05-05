# PDF Document Model module for PDFBox Crystal
#
# This module contains the high-level PDF document model classes,
# corresponding to the pdmodel package in Apache PDFBox.
require "./pdmodel/common"
require "./pdmodel/encryption"
require "./pdmodel/interactive"
require "./pdmodel/fdf"
require "./pdmodel/graphics"
require "./pdmodel/document_interchange"
require "./pdmodel/font"
require "./pdmodel/resources"
require "./pdmodel/pdappearance_content_stream"
require "./pdmodel/pdform_content_stream"
require "./pdmodel/pdpattern_content_stream"
require "./pdmodel/page_content_stream"
require "./pdmodel/page"
require "./pdmodel/page_layout"
require "./pdmodel/page_mode"
require "./pdmodel/graphics/color/icc_profile"

module Pdfbox::Pdmodel
  # Main PDF document class
  class Document
    Log = ::Log.for(self)

    @cos_document : Cos::Dictionary?
    @version : String
    @pages : Array(Page)
    @catalog : DocumentCatalog?
    @trailer : Cos::Dictionary?
    @encryption : Encryption::PDEncryption?
    @document_id : Bytes?
    @current_access_permission : Encryption::AccessPermission?
    @all_security_to_be_removed : Bool = false
    @fonts_for_save = [] of Font::PDFont

    def initialize(cos_document : Cos::Dictionary? = nil, version : String = "1.4", trailer : Cos::Dictionary? = nil)
      @version = version
      @trailer = trailer
      @cos_document = cos_document || self.class.build_default_catalog_dictionary
      @pages = [] of Page
      @catalog = @cos_document ? DocumentCatalog.new(@cos_document.as(Cos::Dictionary), self) : nil
      @encryption = nil
      @document_id = nil
      @current_access_permission = nil

      if cos_document.nil?
        @catalog.try(&.version=(@version))
      end

      load_trailer_state
    end

    def self.build_default_catalog_dictionary : Cos::Dictionary
      catalog_dict = Cos::Dictionary.new
      catalog_dict[Cos::Name.new("Type")] = Cos::Name.new("Catalog")

      pages_dict = Cos::Dictionary.new
      pages_dict[Cos::Name.new("Type")] = Cos::Name.new("Pages")
      pages_dict[Cos::Name.new("Kids")] = Cos::Array.new
      pages_dict[Cos::Name.new("Count")] = Cos::Integer.new(0)

      catalog_dict[Cos::Name.new("Pages")] = pages_dict
      catalog_dict
    end

    # Get the effective PDF version (e.g., 1.4f).
    def version : Float32
      header_version = header_version_as_float
      return header_version if header_version < 1.4_f32

      catalog_version = document_catalog.try(&.version)
      return header_version unless catalog_version

      parsed_catalog_version = catalog_version.to_f32?
      unless parsed_catalog_version
        Log.error { "Can't extract the version number of the document catalog: #{catalog_version.inspect}" }
        return header_version
      end

      Math.max(parsed_catalog_version, header_version).to_f32
    end

    # Get the header PDF version string (e.g., "1.4")
    def header_version : String
      @version
    end

    # Set the header PDF version string directly.
    def header_version=(version : String) : String
      @version = version
    end

    def version=(new_version : Number) : Float32
      set_version(new_version.to_f32)
      version
    end

    # Load a PDF document from a file
    def self.load(filename : String, lenient : Bool = true) : Document
      File.open(filename) do |file|
        load(file, lenient: lenient)
      end
    end

    # Load a PDF document from an IO stream
    def self.load(io : ::IO, lenient : Bool = true) : Document
      # Use parser to read PDF
      # Read all bytes as binary data
      file_size = io.size
      if file_size > Int32::MAX
        raise "File too large: #{file_size} bytes"
      end
      bytes = Bytes.new(file_size.to_i32)
      io.read_fully(bytes)
      source = Pdfbox::IO::RandomAccessReadBuffer.new(bytes)
      parser = Pdfbox::Pdfparser::Parser.new(source)
      parser.lenient = lenient
      parser.parse
    end

    # Create a new empty PDF document
    def self.create : Document
      Document.new
    end

    # Save the document to a file
    def save(filename : String) : Nil
      File.open(filename, "w") do |file|
        save(file, Pdfbox::Pdfwriter::Compress::CompressParameters::DEFAULT_COMPRESSION)
      end
    end

    def save(filename : String, parameters : Pdfbox::Pdfwriter::Compress::CompressParameters) : Nil
      File.open(filename, "w") do |file|
        save(file, parameters)
      end
    end

    # Save the document to an IO stream
    def save(io : ::IO) : Nil
      save(io, Pdfbox::Pdfwriter::Compress::CompressParameters::DEFAULT_COMPRESSION)
    end

    def save(io : ::IO, parameters : Pdfbox::Pdfwriter::Compress::CompressParameters) : Nil
      subset_embedded_fonts

      # Prepare encryption if document is protected
      if encrypted? && (encryption = self.encryption) && (handler = encryption.security_handler)
        if handler.is_a?(Pdfbox::Pdmodel::Encryption::StandardSecurityHandler)
          handler.prepare_document_for_encryption(self)
        end
      end

      writer = Pdfbox::Pdfwriter::Writer.new(io, self, parameters)
      writer.write
    end

    # Save the document incrementally.
    # Current Crystal port fallback writes a full document.
    def save_incremental(io : ::IO) : Nil
      save(io)
    end

    # Add a page to the document
    def add_page(page : Page) : Page
      ensure_pages_loaded
      @pages << page
      add_page_to_tree(page)
      page
    end

    def register_font_for_save(font : Font::PDFont) : Nil
      return if @fonts_for_save.any? { |existing| existing.object_id == font.object_id }
      @fonts_for_save << font
    end

    # Append a page that was already resolved from the page tree during parsing.
    # This avoids recursive hydration while the parser is constructing the document.
    def add_parsed_page(page : Page) : Page
      @pages << page
      page
    end

    private def add_page_to_tree(page : Page) : Nil
      catalog = @catalog
      return unless catalog

      pages_entry = catalog.cos_object[Cos::Name.new("Pages")]
      return unless pages_entry.is_a?(Cos::Dictionary)

      kids = pages_entry[Cos::Name.new("Kids")]
      unless kids.is_a?(Cos::Array)
        kids = Cos::Array.new
        pages_entry[Cos::Name.new("Kids")] = kids
      end

      # Ensure page dictionary is indirect
      page_dict = page.cos_object
      return unless page_dict
      page_dict.direct = false

      # Create indirect object reference for page
      page_obj = Cos::Object.new(page_dict)
      kids.add(page_obj)

      # Update page count
      count = pages_entry[Cos::Name.new("Count")]
      if count.is_a?(Cos::Integer)
        pages_entry[Cos::Name.new("Count")] = Cos::Integer.new(count.value + 1)
      else
        pages_entry[Cos::Name.new("Count")] = Cos::Integer.new(1)
      end

      # Set parent reference in page dictionary
      page_dict[Cos::Name.new("Parent")] = Cos::Object.new(pages_entry)
    end

    # Create and add a new page
    def add_page : Page
      page = Page.new
      add_page(page)
    end

    # Get all pages in the document
    def pages : Array(Page)
      ensure_pages_loaded
      @pages
    end

    # Get the number of pages
    def page_count : Int32
      pages.size
    end

    def number_of_pages : Int32
      page_count
    end

    def get_number_of_pages : Int32 # ameba:disable Naming/AccessorMethodName
      page_count
    end

    # Get the document catalog
    def document_catalog : DocumentCatalog?
      @catalog
    end

    def get_document_catalog : DocumentCatalog? # ameba:disable Naming/AccessorMethodName
      document_catalog
    end

    def get_document : Cos::Dictionary? # ameba:disable Naming/AccessorMethodName
      @cos_document
    end

    # ameba:disable Naming/AccessorMethodName
    def set_version(new_version : Number) : Nil
      current_version = version
      proposed_version = new_version.to_f32
      return if proposed_version == current_version

      if proposed_version < current_version
        Log.error { "It's not allowed to downgrade the version of a pdf." }
        return
      end

      if header_version_as_float >= 1.4_f32
        @catalog.try(&.version=(format_version_number(proposed_version)))
      else
        @version = format_version_number(proposed_version)
      end
    end

    # ameba:enable Naming/AccessorMethodName

    # Get a page by index (0-based)
    def page(index : Int) : Page?
      pages[index]?
    end

    def get_page(index : Int) : Page
      page(index) || raise IndexError.new
    end

    def get_pages : Array(Page) # ameba:disable Naming/AccessorMethodName
      pages
    end

    # Remove a page from the document
    def remove_page(page : Page) : Bool
      ensure_pages_loaded
      @pages.delete(page)
    end

    # Remove a page by index
    def remove_page(index : Int) : Bool
      ensure_pages_loaded
      return false if index < 0 || index >= @pages.size
      @pages.delete_at(index)
      true
    end

    # Get the document trailer dictionary
    def trailer : Cos::Dictionary?
      @trailer
    end

    # Get the encryption dictionary, if present
    def encryption : Encryption::PDEncryption?
      @encryption
    end

    def encryption=(encryption : Encryption::PDEncryption) : Encryption::PDEncryption
      @encryption = encryption
    end

    # Returns true if the document is encrypted.
    def encrypted? : Bool
      !@encryption.nil?
    end

    # Get the document ID bytes, required for password validation
    def document_id : Bytes?
      @document_id
    end

    def get_document_id : Bytes? # ameba:disable Naming/AccessorMethodName
      @document_id
    end

    def document_id=(document_id : Bytes?) : Bytes?
      @document_id = document_id
    end

    def set_document_id(document_id : Bytes?) : Nil # ameba:disable Naming/AccessorMethodName
      @document_id = document_id
    end

    # Attempt to decrypt the document with the given password
    # Returns true if password is correct and decryption succeeded
    def decrypt(password : String) : Bool
      return false unless @encryption && @document_id
      encryption = @encryption
      return false unless encryption

      # Get security handler from encryption dictionary
      security_handler = encryption.security_handler
      return false unless security_handler

      # Create decryption material
      material = Encryption::StandardDecryptionMaterial.new(password)

      security_handler.prepare_for_decryption(encryption, @document_id, material)
      # After successful preparation, security handler should have current access permission
      @current_access_permission = security_handler.current_access_permission
      true
    end

    # Protects the document with a protection policy.
    # The document content will be really encrypted when it is saved.
    #
    # @param policy The protection policy.
    def protect(policy : Encryption::ProtectionPolicy) : Nil
      if @all_security_to_be_removed
        # In Java: LOG.warn("do not call setAllSecurityToBeRemoved(true) before calling protect(), "
        #                 + "as protect() implies setAllSecurityToBeRemoved(false)")
        @all_security_to_be_removed = false
      end

      unless @encryption
        @encryption = Encryption::PDEncryption.new
      end

      # For StandardProtectionPolicy, create a StandardSecurityHandler
      if policy.is_a?(Encryption::StandardProtectionPolicy)
        security_handler = Encryption::StandardSecurityHandler.new(policy)
      else
        raise ::IO::Error.new("Unsupported protection policy type: #{policy.class}")
      end

      # Set the security handler on the encryption
      if encryption = @encryption
        encryption.security_handler = security_handler
      end
    end

    # Get document information (metadata)
    def document_information : DocumentInformation?
      trailer = @trailer
      return unless trailer

      # Get /Info dictionary from trailer
      info_dict = trailer[Cos::Name.new("Info")]
      return unless info_dict

      # Handle indirect references
      if info_dict.is_a?(Cos::Object)
        info_dict = info_dict.object
      end

      return unless info_dict.is_a?(Cos::Dictionary)

      DocumentInformation.new(info_dict)
    end

    def get_document_information : DocumentInformation? # ameba:disable Naming/AccessorMethodName
      document_information
    end

    def set_document_information(info : DocumentInformation?) : Nil # ameba:disable Naming/AccessorMethodName
      trailer = (@trailer ||= Cos::Dictionary.new)
      key = Cos::Name.new("Info")
      if info
        trailer[key] = info.cos_object
      else
        trailer.delete(key)
      end
    end

    # Get current access permissions for encrypted documents
    def current_access_permission : Encryption::AccessPermission
      @current_access_permission || Encryption::AccessPermission.new
    end

    def all_security_to_be_removed=(remove_all_security : Bool) : Bool
      @all_security_to_be_removed = remove_all_security
    end

    def all_security_to_be_removed? : Bool
      @all_security_to_be_removed
    end

    def is_all_security_to_be_removed : Bool # ameba:disable Naming/PredicateName
      @all_security_to_be_removed
    end

    # Java API compatibility wrapper.
    # ameba:disable Naming/AccessorMethodName
    def set_all_security_to_be_removed(_remove_all_security : Bool) : Nil
      self.all_security_to_be_removed = _remove_all_security
    end

    # ameba:enable Naming/AccessorMethodName

    # Close the document and release resources
    def close : Nil
      # TODO: Implement cleanup
    end

    private def ensure_pages_loaded : Nil
      return unless @pages.empty?

      catalog = @catalog
      return unless catalog

      pages_entry = catalog.cos_object[Cos::Name.new("Pages")]
      return unless pages_entry

      pages_dict = dereference_dictionary(pages_entry)
      return unless pages_dict

      kids = pages_dict[Cos::Name.new("Kids")]
      kids = kids.object if kids.is_a?(Cos::Object)
      return unless kids.is_a?(Cos::Array)

      kids.items.each do |kid|
        page_dict = dereference_dictionary(kid)
        next unless page_dict
        @pages << Page.new(page_dict)
      end
    end

    private def subset_embedded_fonts : Nil
      @fonts_for_save.each do |font|
        type0_font = font.as?(Font::PDType0Font)
        next unless type0_font
        next unless type0_font.will_be_subset?
        type0_font.subset
      end
    end

    private def header_version_as_float : Float32
      @version.to_f32? || 1.4_f32
    end

    private def format_version_number(number : Float32) : String
      "%.1f" % number
    end

    private def load_trailer_state : Nil
      trailer = @trailer
      return unless trailer

      load_encryption_from_trailer(trailer)
      load_document_id_from_trailer(trailer)
    end

    private def load_encryption_from_trailer(trailer : Cos::Dictionary) : Nil
      encrypt_entry = dereference_base(trailer[Cos::Name.new("Encrypt")])
      return unless encrypt_entry.is_a?(Cos::Dictionary)

      @encryption = Encryption::PDEncryption.new(encrypt_entry)
    end

    private def load_document_id_from_trailer(trailer : Cos::Dictionary) : Nil
      id_entry = dereference_base(trailer[Cos::Name.new("ID")])
      return unless id_entry.is_a?(Cos::Array) && id_entry.size > 0

      id_first = id_entry[0]
      @document_id = id_first.bytes if id_first.is_a?(Cos::String)
    end

    private def dereference_base(base : Cos::Base?) : Cos::Base?
      return unless base
      return base.object if base.is_a?(Cos::Object)
      base
    end

    private def dereference_dictionary(base : Cos::Base) : Cos::Dictionary?
      candidate = base
      if candidate.is_a?(Cos::Object)
        deref = candidate.object
        return unless deref
        candidate = deref
      end
      candidate.as?(Cos::Dictionary)
    end
  end

  # Rectangle class for PDF boxes
  class Rectangle
    @lower_left_x : Float64
    @lower_left_y : Float64
    @upper_right_x : Float64
    @upper_right_y : Float64

    def initialize(@lower_left_x : Float64, @lower_left_y : Float64,
                   @upper_right_x : Float64, @upper_right_y : Float64)
    end

    # Create rectangle from width and height (lower-left at 0,0)
    def self.from_dimensions(width : Float64, height : Float64) : Rectangle
      new(0.0, 0.0, width, height)
    end

    def lower_left_x : Float64
      @lower_left_x
    end

    def lower_left_y : Float64
      @lower_left_y
    end

    def upper_right_x : Float64
      @upper_right_x
    end

    def upper_right_y : Float64
      @upper_right_y
    end

    def width : Float64
      @upper_right_x - @lower_left_x
    end

    def height : Float64
      @upper_right_y - @lower_left_y
    end

    def to_a : Array(Float64)
      [@lower_left_x, @lower_left_y, @upper_right_x, @upper_right_y]
    end

    # Java: createRetranslatedRectangle - returns a rectangle with lower-left at (0,0)
    def create_retranslated_rectangle : Rectangle
      Rectangle.new(
        0.0,
        0.0,
        width,
        height
      )
    end
  end

  # Common page sizes
  module PageSizes
    # US Letter: 8.5 x 11 inches
    LETTER = Rectangle.from_dimensions(612.0, 792.0) # 72 DPI

    # US Tabloid: 11 x 17 inches
    TABLOID = Rectangle.from_dimensions(792.0, 1224.0)

    # US Legal: 8.5 x 14 inches
    LEGAL = Rectangle.from_dimensions(612.0, 1008.0)

    # A0: 841 x 1189 mm
    A0 = Rectangle.from_dimensions(2384.0, 3370.0)

    # A1: 594 x 841 mm
    A1 = Rectangle.from_dimensions(1684.0, 2384.0)

    # A2: 420 x 594 mm
    A2 = Rectangle.from_dimensions(1190.0, 1684.0)

    # A3: 297 x 420 mm
    A3 = Rectangle.from_dimensions(842.0, 1190.0)

    # A4: 210 x 297 mm
    A4 = Rectangle.from_dimensions(595.0, 842.0)

    # A5: 148 x 210 mm
    A5 = Rectangle.from_dimensions(420.0, 595.0)

    # A6: 105 x 148 mm
    A6 = Rectangle.from_dimensions(298.0, 420.0)
  end

  # Range class for specifying numeric ranges [min, max]
  # Used by page labels, color spaces, and other PDF structures
  class PDRange
    @range_array : Cos::Array
    @starting_index : Int32

    # Default constructor creates a range [0.0, 1.0]
    def initialize
      @range_array = Cos::Array.new
      @range_array.add(Cos::Float.new(0.0))
      @range_array.add(Cos::Float.new(1.0))
      @starting_index = 0
    end

    # Create from existing COSArray starting at index 0
    def initialize(range_array : Cos::Array)
      @range_array = range_array
      @starting_index = 0
    end

    # Create from COSArray with a specific starting index
    # Arrays can contain multiple ranges: [min1, max1, min2, max2, ...]
    # starting_index specifies which range pair (0 = first pair)
    def initialize(@range_array : Cos::Array, @starting_index : Int32)
    end

    # Get the underlying COSArray
    def cos_array : Cos::Array
      @range_array
    end

    # Get the minimum value of the range
    def min : Float64
      value = @range_array[@starting_index * 2]
      case value
      when Cos::Integer then value.value.to_f64
      when Cos::Float   then value.value
      else
        0.0
      end
    end

    # Set the minimum value of the range
    def min=(value : Float64)
      @range_array[@starting_index * 2] = Cos::Float.new(value)
    end

    # Get the maximum value of the range
    def max : Float64
      value = @range_array[@starting_index * 2 + 1]
      case value
      when Cos::Integer then value.value.to_f64
      when Cos::Float   then value.value
      else
        1.0
      end
    end

    # Set the maximum value of the range
    def max=(value : Float64)
      @range_array[@starting_index * 2 + 1] = Cos::Float.new(value)
    end

    # Convert to string representation
    def to_s(io : IO) : Nil
      io << "PDRange{" << min << ", " << max << "}"
    end

    # Explicit to_s for compatibility
    def to_s : String
      "PDRange{#{min}, #{max}}"
    end
  end

  # Document catalog class
  class DocumentCatalog
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary
    @document : Document?

    def initialize(@cos_dict : Cos::Dictionary, @document : Document? = nil)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get page labels
    def page_labels : PageLabels?
      Log.debug { "catalog dict entries:" }
      @cos_dict.entries.each do |key, value|
        Log.debug { "  #{key.value}: #{value.class} #{value.inspect}" }
      end

      # Check for PageLabels entry
      page_labels_dict = @cos_dict[Cos::Name.new("PageLabels")]
      Log.debug { "PageLabels entry: #{page_labels_dict.inspect}" }

      return unless page_labels_dict

      # Create PageLabels object
      PageLabels.new(page_labels_dict, self)
    end

    # Get total number of pages in document
    def page_count : Int32
      if doc = @document
        doc.page_count
      else
        # Fallback: try to get from /Pages tree
        0
      end
    end

    def version : String?
      @cos_dict.get_name_as_string(Cos::Name.new("Version"))
    end

    def version=(version : String?) : String?
      key = Cos::Name.new("Version")
      if version
        @cos_dict.set_name(key, version)
      else
        @cos_dict.delete(key)
      end
      version
    end

    # Get document outline (bookmarks)
    def document_outline : DocumentOutline?
      outlines_dict = @cos_dict[Cos::Name.new("Outlines")]
      return unless outlines_dict

      # Handle indirect references
      if outlines_dict.is_a?(Cos::Object)
        outlines_dict = outlines_dict.object
      end

      return unless outlines_dict.is_a?(Cos::Dictionary)

      DocumentOutline.new(outlines_dict)
    end

    def document_outline=(outline : DocumentOutline) : DocumentOutline
      @cos_dict[Cos::Name.new("Outlines")] = outline.cos_object
      outline
    end

    # Java API compatibility wrapper.
    # ameba:disable Naming/AccessorMethodName
    def set_document_outline(outline : DocumentOutline) : Nil
      self.document_outline = outline
    end

    # ameba:enable Naming/AccessorMethodName

    # Get document names dictionary
    def names : DocumentNameDictionary?
      names_dict = @cos_dict[Cos::Name.new("Names")]
      return unless names_dict

      # Handle indirect references
      if names_dict.is_a?(Cos::Object)
        names_dict = names_dict.object
      end

      return unless names_dict.is_a?(Cos::Dictionary)

      DocumentNameDictionary.new(names_dict, self)
    end

    def acro_form : Interactive::Form::PDAcroForm?
      form_dict = @cos_dict[Cos::Name.new("AcroForm")]
      form_dict = form_dict.object if form_dict.is_a?(Cos::Object)
      return unless form_dict.is_a?(Cos::Dictionary)
      return unless @document
      document = @document
      return unless document

      Interactive::Form::PDAcroForm.new(document, form_dict)
    end

    def acro_form=(form : Interactive::Form::PDAcroForm) : Interactive::Form::PDAcroForm
      @cos_dict[Cos::Name.new("AcroForm")] = form.cos_object
      form
    end

    def viewer_preferences : Interactive::PDViewerPreferences?
      prefs = @cos_dict.get_dictionary(Cos::Name.new("ViewerPreferences"))
      prefs ? Interactive::PDViewerPreferences.new(prefs) : nil
    end

    def viewer_preferences=(preferences : Interactive::PDViewerPreferences) : Interactive::PDViewerPreferences
      @cos_dict[Cos::Name.new("ViewerPreferences")] = preferences.cos_object
      preferences
    end

    # Get XMP metadata from document catalog
    # Java equivalent: PDDocumentCatalog.getMetadata()
    def metadata : Pdmodel::Common::PDMetadata?
      meta_obj = @cos_dict.get_stream(Cos::Name.new("Metadata"))
      meta_obj ? Pdmodel::Common::PDMetadata.new(meta_obj) : nil
    end

    # Get output intents
    def output_intents : Array(OutputIntent)
      output_intents_value = @cos_dict[Cos::Name.new("OutputIntents")]
      return [] of OutputIntent unless output_intents_value

      # Handle indirect references
      if output_intents_value.is_a?(Cos::Object)
        output_intents_value = output_intents_value.object
      end

      return [] of OutputIntent unless output_intents_value.is_a?(Cos::Array)

      result = [] of OutputIntent
      output_intents_value.items.each do |item|
        dict = item
        # Handle indirect references
        if dict.is_a?(Cos::Object)
          dict = dict.object
        end

        if dict.is_a?(Cos::Dictionary)
          result << OutputIntent.new(dict)
        end
      end
      result
    end

    # Add an output intent to the list
    def add_output_intent(output_intent : OutputIntent) : Nil
      output_intents_value = @cos_dict[Cos::Name.new("OutputIntents")]

      if output_intents_value.nil? || !output_intents_value.is_a?(Cos::Array)
        output_intents_value = Cos::Array.new
        @cos_dict[Cos::Name.new("OutputIntents")] = output_intents_value
      end

      output_intents_value.as(Cos::Array).items << output_intent.cos_object
    end

    # Replace the list of output intents
    def output_intents=(output_intents : Array(OutputIntent)) : Nil
      if output_intents.empty?
        @cos_dict.delete(Cos::Name.new("OutputIntents"))
      else
        array = Cos::Array.new
        output_intents.each do |intent|
          array.items << intent.cos_object
        end
        @cos_dict[Cos::Name.new("OutputIntents")] = array
      end
    end

    # Get open action
    def open_action
      open_action_value = @cos_dict[Cos::Name.new("OpenAction")]
      return unless open_action_value

      # Handle indirect references
      if open_action_value.is_a?(Cos::Object)
        open_action_value = open_action_value.object
      end

      # Return nil for boolean values (e.g., false) as per PDF spec
      return if open_action_value.is_a?(Cos::Boolean)

      # TODO: Implement proper action/destination parsing
      # For now, just return the raw value
      open_action_value
    end
  end

  # Output intent class for color reproduction characteristics
  class OutputIntent
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    # Create an output intent of GTS_PDFA1 subtype.
    #
    # @param doc The document.
    # @param color_profile the ICC color profile data.
    # @raise ICCProfileError if the color_profile does not contain valid ICC Profile data.
    def self.create(doc : Document, color_profile : Bytes) : self
      # Parse ICC profile
      icc_profile = Graphics::Color::ICCProfile.from_bytes(color_profile)

      dictionary = Cos::Dictionary.new
      dictionary[Cos::Name::TYPE] = Cos::Name::OUTPUT_INTENT
      dictionary[Cos::Name::S] = Cos::Name::GTS_PDFA1

      # Create stream with ICC profile data
      # Note: In Java, this would create a PDStream attached to the document
      # Since we don't have a PDDocument, we create a standalone Cos::Stream
      stream_dict = Cos::Dictionary.new
      stream_dict[Cos::Name::LENGTH] = Cos::Integer.new(color_profile.size)
      stream_dict[Cos::Name::FILTER] = Cos::Name::FLATE_DECODE

      # Set N parameter to number of components from ICC profile
      stream_dict[Cos::Name::N] = Cos::Integer.new(icc_profile.num_components)

      # Create stream object with ICC profile data
      stream = Cos::Stream.new(entries: stream_dict.entries, data: color_profile)
      dictionary[Cos::Name::DEST_OUTPUT_PROFILE] = stream

      new(dictionary)
    end

    def initialize(@cos_dict : Cos::Dictionary = Cos::Dictionary.new)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get info
    def info : String?
      value = @cos_dict[Cos::Name::INFO]
      value.as?(Cos::String).try(&.value)
    end

    # Set info
    def info=(info : String) : Nil
      @cos_dict[Cos::Name::INFO] = Cos::String.new(info)
    end

    # Get output condition
    def output_condition : String?
      value = @cos_dict[Cos::Name::OUTPUT_CONDITION]
      value.as?(Cos::String).try(&.value)
    end

    # Set output condition
    def output_condition=(output_condition : String) : Nil
      @cos_dict[Cos::Name::OUTPUT_CONDITION] = Cos::String.new(output_condition)
    end

    # Get output condition identifier
    def output_condition_identifier : String?
      value = @cos_dict[Cos::Name::OUTPUT_CONDITION_IDENTIFIER]
      value.as?(Cos::String).try(&.value)
    end

    # Set output condition identifier
    def output_condition_identifier=(output_condition_identifier : String) : Nil
      @cos_dict[Cos::Name::OUTPUT_CONDITION_IDENTIFIER] = Cos::String.new(output_condition_identifier)
    end

    # Get registry name
    def registry_name : String?
      value = @cos_dict[Cos::Name::REGISTRY_NAME]
      value.as?(Cos::String).try(&.value)
    end

    # Set registry name
    def registry_name=(registry_name : String) : Nil
      @cos_dict[Cos::Name::REGISTRY_NAME] = Cos::String.new(registry_name)
    end
  end

  # Page label range class
  class PageLabelRange
    Log = ::Log.for(self)

    @root : Cos::Dictionary

    # Style constants
    STYLE_DECIMAL       = "D"
    STYLE_ROMAN_UPPER   = "R"
    STYLE_ROMAN_LOWER   = "r"
    STYLE_LETTERS_UPPER = "A"
    STYLE_LETTERS_LOWER = "a"

    # Key constants
    KEY_START  = Cos::Name.new("ST")
    KEY_PREFIX = Cos::Name.new("P")
    KEY_STYLE  = Cos::Name.new("S")

    def initialize(@root : Cos::Dictionary)
    end

    private def resolve_value(value : Cos::Base?) : Cos::Base?
      return unless value
      if value.is_a?(Cos::Object)
        value.object
      else
        value
      end
    end

    # Get the underlying dictionary
    def cos_object : Cos::Dictionary
      @root
    end

    # Returns the numbering style for this page range
    def style : String?
      value = resolve_value(@root[KEY_STYLE])
      return unless value
      value.as(Cos::Name).value
    end

    # Sets the numbering style for this page range
    def style=(style : String?) : Nil
      if style
        @root[KEY_STYLE] = Cos::Name.new(style)
      else
        @root.delete(KEY_STYLE)
      end
    end

    # Returns the start value for page numbering in this page range
    def start : Int32
      value = resolve_value(@root[KEY_START])
      return 1 unless value
      value.as(Cos::Integer).value.to_i32
    end

    # Sets the start value for page numbering in this page range
    def start=(start : Int32) : Nil
      if start <= 0
        raise ArgumentError.new("The page numbering start value must be a positive integer")
      end
      @root[KEY_START] = Cos::Integer.new(start.to_i64)
    end

    # Returns the page label prefix for this page range
    def prefix : String?
      value = resolve_value(@root[KEY_PREFIX])
      return unless value
      value.as(Cos::String).value
    end

    # Sets the page label prefix for this page range
    def prefix=(prefix : String?) : Nil
      if prefix
        @root[KEY_PREFIX] = Cos::String.new(prefix)
      else
        @root.delete(KEY_PREFIX)
      end
    end
  end

  # Page labels class
  class PageLabels
    Log = ::Log.for(self)

    @cos_dict : Cos::Base
    @catalog : DocumentCatalog
    @labels : Hash(Int32, PageLabelRange)

    def initialize(@cos_dict : Cos::Base, @catalog : DocumentCatalog)
      Log.debug { "initialize: cos_dict type: #{@cos_dict.class}, value: #{@cos_dict.inspect}" }
      @labels = parse_number_tree
    end

    # Get labels by page indices
    def labels_by_page_indices : Array(String)
      Log.debug { "labels_by_page_indices: called" }
      total_pages = @catalog.page_count
      Log.debug { "labels_by_page_indices: total_pages=#{total_pages}" }
      return [] of String if total_pages <= 0

      result = Array(String).new(total_pages)
      sorted_keys = @labels.keys.sort!

      return [] of String if sorted_keys.empty?

      # Iterate through ranges
      page_index = 0
      sorted_keys.each_with_index do |start_page, idx|
        label_range = @labels[start_page]
        next_start = idx + 1 < sorted_keys.size ? sorted_keys[idx + 1] : total_pages
        num_pages = next_start - start_page

        num_pages.times do |i|
          label = generate_label(label_range, i)
          result << label
          page_index += 1
        end
      end

      result
    end

    private def parse_number_tree : Hash(Int32, PageLabelRange)
      labels = {} of Int32 => PageLabelRange
      Log.debug { "parse_number_tree: cos_dict type: #{@cos_dict.class}" }

      # Get the actual dictionary (could be indirect reference)
      dict = @cos_dict
      if dict.is_a?(Cos::Object)
        Log.debug { "parse_number_tree: dict is Cos::Object, object: #{dict.object.inspect}" }
        obj = dict.object
        return labels unless obj.is_a?(Cos::Dictionary)
        dict = obj
      end

      return labels unless dict.is_a?(Cos::Dictionary)
      Log.debug { "parse_number_tree: dict is Cos::Dictionary, entries: #{dict.entries.keys.map(&.value)}" }

      # Create NumberTreeNode to parse the number tree
      node = NumberTreeNode(PageLabelRange).new(dict) do |cos|
        # Converter proc: Convert Cos::Base to PageLabelRange
        # cos could be Cos::Object (reference) or Cos::Dictionary
        dict_to_use = cos
        if dict_to_use.is_a?(Cos::Object)
          obj = dict_to_use.object
          dict_to_use = obj if obj.is_a?(Cos::Dictionary)
        end

        unless dict_to_use.is_a?(Cos::Dictionary)
          Log.error { "parse_number_tree: expected Cos::Dictionary for PageLabelRange, got #{dict_to_use.class}" }
          raise Pdfbox::PDFError.new("Expected dictionary for PageLabelRange, got #{dict_to_use.class}")
        end

        PageLabelRange.new(dict_to_use)
      end

      # Recursively collect labels from the number tree
      find_labels(node, labels)

      Log.debug { "parse_number_tree: found #{labels.size} label ranges" }
      labels
    end

    private def find_labels(node : NumberTreeNode(PageLabelRange), labels : Hash(Int32, PageLabelRange)) : Nil
      # Check kids first (recursive traversal)
      kids = node.kids
      if kids
        kids.each do |kid|
          find_labels(kid, labels)
        end
      else
        # Leaf node: get numbers
        numbers = node.numbers
        if numbers
          numbers.each do |key, value|
            if key >= 0
              labels[key] = value
            end
          end
        end
      end
    end

    private def generate_label(range : PageLabelRange, offset : Int32) : String
      result = ""

      # Add prefix if present
      if prefix = range.prefix
        # Remove null bytes if present (PDFBOX-1047)
        if idx = prefix.index('\u0000')
          prefix = prefix[0...idx]
        end
        result += prefix
      end

      # Add number if style present
      if style = range.style
        result += format_number(range.start + offset, style)
      end

      result
    end

    private def format_number(num : Int32, style : String) : String
      case style
      when PageLabelRange::STYLE_DECIMAL
        num.to_s
      when PageLabelRange::STYLE_LETTERS_LOWER
        make_letter_label(num)
      when PageLabelRange::STYLE_LETTERS_UPPER
        make_letter_label(num).upcase
      when PageLabelRange::STYLE_ROMAN_LOWER
        make_roman_label(num)
      when PageLabelRange::STYLE_ROMAN_UPPER
        make_roman_label(num).upcase
      else
        # Fall back to decimal
        num.to_s
      end
    end

    private def make_roman_label(num : Int32) : String
      # Roman numeral conversion for numbers 1-3999
      # Simple implementation for now
      roman_map = {
        1000 => "m", 900 => "cm", 500 => "d", 400 => "cd",
        100 => "c", 90 => "xc", 50 => "l", 40 => "xl",
        10 => "x", 9 => "ix", 5 => "v", 4 => "iv", 1 => "i",
      }

      result = ""
      n = num
      roman_map.each do |value, numeral|
        while n >= value
          result += numeral
          n -= value
        end
      end
      result
    end

    private def make_letter_label(num : Int32) : String
      # PDF spec: a..z, aa..zz, aaa..zzz ...
      # num is 0-based? In PDF, page numbering starts at 1.
      # Java implementation uses: num % 26 + 26 * (1 - Integer.signum(num % 26)) + 'a' - 1
      # Let's implement simpler: convert to base-26 with digits a-z, where 0=a, 1=b, ... 25=z
      # For PDF: 1=a, 2=b, ..., 26=z, 27=aa, 28=ab, ...
      n = num # num is already start + offset, should be >= 1
      return "" if n <= 0

      result = ""
      while n > 0
        n -= 1
        remainder = n % 26
        result = ('a'.ord + remainder).chr + result
        n //= 26
      end
      result
    end
  end

  # Document names dictionary (corresponds to PDDocumentNameDictionary in Apache PDFBox)
  class DocumentNameDictionary
    Log = ::Log.for(self)

    @names_dict : Cos::Dictionary
    @catalog : DocumentCatalog

    def initialize(@names_dict : Cos::Dictionary, @catalog : DocumentCatalog)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get the destination output intent stream
    def dest_output_intent : Cos::Stream?
      value = @cos_dict[Cos::Name::DEST_OUTPUT_PROFILE]
      value.as?(Cos::Stream)
    end

    # Get embedded files name tree
    def embedded_files : NameTreeNode(ComplexFileSpecification)?
      embedded_files_value = @names_dict[Cos::Name.new("EmbeddedFiles")]
      return unless embedded_files_value

      # Handle indirect references
      if embedded_files_value.is_a?(Cos::Object)
        embedded_files_value = embedded_files_value.object
      end

      return unless embedded_files_value.is_a?(Cos::Dictionary)

      # Create converter from COS dictionary to ComplexFileSpecification
      converter = ->(cos : Cos::Base) {
        Log.debug { "embedded_files converter: received #{cos.class}" }
        # cos could be Cos::Object (reference), Cos::Dictionary, or Cos::Null
        dict_to_use = cos
        if dict_to_use.is_a?(Cos::Object)
          obj = dict_to_use.object
          Log.debug { "embedded_files converter: object points to #{obj.class}" }
          dict_to_use = obj if obj.is_a?(Cos::Dictionary)
        end

        # Handle null by creating empty dictionary (PDF may have null entries)
        if dict_to_use.is_a?(Cos::Null)
          Log.debug { "embedded_files converter: creating empty dictionary for null entry" }
          dict_to_use = Cos::Dictionary.new
        end

        unless dict_to_use.is_a?(Cos::Dictionary)
          Log.error { "embedded_files converter: expected Cos::Dictionary for ComplexFileSpecification, got #{dict_to_use.class}" }
          raise Pdfbox::PDFError.new("Expected dictionary for ComplexFileSpecification, got #{dict_to_use.class}")
        end

        ComplexFileSpecification.new(dict_to_use)
      }
      NameTreeNode(ComplexFileSpecification).new(converter, embedded_files_value)
    end
  end

  # Name tree node for string keys (corresponds to PDNameTreeNode in Apache PDFBox)
  class NameTreeNode(T)
    @node : Cos::Dictionary
    @converter : Proc(Cos::Base, T)

    # Constructor with converter proc
    def initialize(@converter : Proc(Cos::Base, T), @node : Cos::Dictionary = Cos::Dictionary.new)
    end

    # Constructor from existing dictionary
    def self.new(dict : Cos::Dictionary, &block : Cos::Base -> T) : self
      new(block, dict)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @node
    end

    # Return the children of this node
    def kids : Array(NameTreeNode(T))?
      kids_array = @node[Cos::Name.new("Kids")]
      return unless kids_array.is_a?(Cos::Array)

      result = [] of NameTreeNode(T)
      kids_array.items.each do |item|
        dict = item
        # Handle indirect references
        if dict.is_a?(Cos::Object)
          obj = dict.object
          dict = obj if obj.is_a?(Cos::Dictionary)
        end

        if dict.is_a?(Cos::Dictionary)
          result << NameTreeNode(T).new(dict) { |cos| @converter.call(cos) }
        end
      end
      result
    end

    # Get names map from this node
    def names : Hash(String, T)?
      names_array = @node[Cos::Name.new("Names")]
      return unless names_array.is_a?(Cos::Array)

      size = names_array.size
      return unless size % 2 == 0

      result = {} of String => T
      i = 0
      while i < size
        key_item = names_array[i]
        value_item = names_array[i + 1]
        Log.debug { "NameTreeNode.names: key_item=#{key_item.class}, value_item=#{value_item.class}" }

        if key_item.is_a?(Cos::String)
          key = key_item.value
          # Convert value using converter (converter handles null)
          value = @converter.call(value_item)
          result[key] = value
        elsif key_item.is_a?(Cos::Name)
          # Names in name trees can be either strings or names
          key = key_item.value
          # Convert value using converter (converter handles null)
          value = @converter.call(value_item)
          result[key] = value
        end
        i += 2
      end

      Log.debug { "NameTreeNode.names: returning #{result.size} entries" }
      result
    end

    # Get value for a given name
    def value(name : String) : T?
      # Check local names first
      local_names = names
      if local_names && local_names.has_key?(name)
        return local_names[name]
      end

      # Check kids recursively
      kids_list = kids
      if kids_list
        kids_list.each do |child|
          # Name trees don't have limits like number trees
          # Need to search all kids
          if value = child.value(name)
            return value
          end
        end
      end

      nil
    end
  end

  # Alias for embedded files name tree node
  alias EmbeddedFilesNameTreeNode = NameTreeNode(ComplexFileSpecification)

  # Complex file specification (corresponds to PDComplexFileSpecification in Apache PDFBox)
  class ComplexFileSpecification
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    def initialize(@cos_dict : Cos::Dictionary)
      Log.debug { "ComplexFileSpecification: dict keys = #{@cos_dict.entries.keys.map(&.value)}" }
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get embedded file for general platform
    def embedded_file : EmbeddedFile?
      ef_dict = @cos_dict[Cos::Name.new("EF")]
      return unless ef_dict

      # Handle indirect references
      if ef_dict.is_a?(Cos::Object)
        ef_dict = ef_dict.object
      end

      return unless ef_dict.is_a?(Cos::Dictionary)

      embedded_file_value = ef_dict[Cos::Name.new("F")]
      return unless embedded_file_value

      # Handle indirect references
      if embedded_file_value.is_a?(Cos::Object)
        embedded_file_value = embedded_file_value.object
      end

      return unless embedded_file_value.is_a?(Cos::Dictionary)

      EmbeddedFile.new(embedded_file_value)
    end

    # Get embedded file for Mac platform
    def embedded_file_mac : EmbeddedFile?
      ef_dict = @cos_dict[Cos::Name.new("EF")]
      return unless ef_dict

      # Handle indirect references
      if ef_dict.is_a?(Cos::Object)
        ef_dict = ef_dict.object
      end

      return unless ef_dict.is_a?(Cos::Dictionary)

      embedded_file_value = ef_dict[Cos::Name.new("Mac")]
      return unless embedded_file_value

      # Handle indirect references
      if embedded_file_value.is_a?(Cos::Object)
        embedded_file_value = embedded_file_value.object
      end

      return unless embedded_file_value.is_a?(Cos::Dictionary)

      EmbeddedFile.new(embedded_file_value)
    end

    # Get embedded file for DOS platform
    def embedded_file_dos : EmbeddedFile?
      ef_dict = @cos_dict[Cos::Name.new("EF")]
      return unless ef_dict

      # Handle indirect references
      if ef_dict.is_a?(Cos::Object)
        ef_dict = ef_dict.object
      end

      return unless ef_dict.is_a?(Cos::Dictionary)

      embedded_file_value = ef_dict[Cos::Name.new("DOS")]
      return unless embedded_file_value

      # Handle indirect references
      if embedded_file_value.is_a?(Cos::Object)
        embedded_file_value = embedded_file_value.object
      end

      return unless embedded_file_value.is_a?(Cos::Dictionary)

      EmbeddedFile.new(embedded_file_value)
    end

    # Get embedded file for Unix platform
    def embedded_file_unix : EmbeddedFile?
      ef_dict = @cos_dict[Cos::Name.new("EF")]
      return unless ef_dict

      # Handle indirect references
      if ef_dict.is_a?(Cos::Object)
        ef_dict = ef_dict.object
      end

      return unless ef_dict.is_a?(Cos::Dictionary)

      embedded_file_value = ef_dict[Cos::Name.new("Unix")]
      return unless embedded_file_value

      # Handle indirect references
      if embedded_file_value.is_a?(Cos::Object)
        embedded_file_value = embedded_file_value.object
      end

      return unless embedded_file_value.is_a?(Cos::Dictionary)

      EmbeddedFile.new(embedded_file_value)
    end

    # Get file name
    def file : String?
      file_value = @cos_dict[Cos::Name.new("UF")] || @cos_dict[Cos::Name.new("F")]
      return unless file_value

      # Handle indirect references
      if file_value.is_a?(Cos::Object)
        file_value = file_value.object
      end

      if file_value.is_a?(Cos::String)
        file_value.value
      end
    end
  end

  # Embedded file (corresponds to PDEmbeddedFile in Apache PDFBox)
  class EmbeddedFile
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    def initialize(@cos_dict : Cos::Dictionary)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get embedded file stream
    def stream : Cos::Stream?
      @cos_dict.as?(Cos::Stream)
    end

    # Get file length
    def length : Int32?
      length_value = @cos_dict[Cos::Name.new("Length")]
      return unless length_value

      # Handle indirect references
      if length_value.is_a?(Cos::Object)
        length_value = length_value.object
      end

      case length_value
      when Cos::Integer
        length_value.value.to_i32
      when Cos::Float
        length_value.value.to_i32
      end
    end

    def subtype : String?
      subtype_value = @cos_dict[Cos::Name.new("Subtype")]?
      return unless subtype_value

      if subtype_value.is_a?(Cos::Object)
        subtype_value = subtype_value.object
      end

      case subtype_value
      when Cos::Name
        subtype_value.value
      when Cos::String
        subtype_value.value
      end
    end

    # Create input stream for embedded file data
    def create_input_stream : ::IO?
      stream = self.stream
      return unless stream

      stream.create_input_stream
    end

    # Get embedded file data as bytes
    def to_byte_array : Bytes
      io = create_input_stream
      return Bytes.empty unless io
      io.gets_to_end.to_slice
    end
  end

  # Number tree node class
  # Corresponds to PDNumberTreeNode in Apache PDFBox
  # Represents a PDF Number tree. See the PDF Reference 1.7 section 7.9.7
  class NumberTreeNode(T)
    @node : Cos::Dictionary
    @converter : Proc(Cos::Base, T)

    # Constructor with converter proc
    def initialize(@converter : Proc(Cos::Base, T), @node : Cos::Dictionary = Cos::Dictionary.new)
    end

    # Constructor from existing dictionary
    def self.new(dict : Cos::Dictionary, &block : Cos::Base -> T) : self
      new(block, dict)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @node
    end

    # Return the children of this node
    def kids : Array(NumberTreeNode(T))?
      kids_array = @node[Cos::Name.new("Kids")]
      return unless kids_array.is_a?(Cos::Array)

      result = [] of NumberTreeNode(T)
      kids_array.items.each do |item|
        dict = item
        # Handle indirect references
        if dict.is_a?(Cos::Object)
          obj = dict.object
          dict = obj if obj.is_a?(Cos::Dictionary)
        end

        if dict.is_a?(Cos::Dictionary)
          result << NumberTreeNode(T).new(dict) { |cos| @converter.call(cos) }
        end
      end
      result
    end

    # Set the children of this number tree
    def kids=(kids : Array(NumberTreeNode(T))?)
      if kids && !kids.empty?
        first_kid = kids.first
        last_kid = kids.last
        lower_limit = first_kid.lower_limit
        upper_limit = last_kid.upper_limit

        set_lower_limit(lower_limit)
        set_upper_limit(upper_limit)

        cos_array = Cos::Array.new
        kids.each do |kid|
          cos_array.add(kid.cos_object)
        end
        @node[Cos::Name.new("Kids")] = cos_array
      elsif !@node.has_key?(Cos::Name.new("Nums"))
        # Remove limits if there are no kids and no numbers set
        @node.delete(Cos::Name.new("Limits"))
        @node.delete(Cos::Name.new("Kids"))
      end
    end

    # Get value for a given index
    def value(index : Int32) : T?
      # Check local numbers first
      numbers = self.numbers
      if numbers && numbers.has_key?(index)
        return numbers[index]
      end

      # Check kids recursively
      kids_list = kids
      if kids_list
        kids_list.each do |child|
          lower = child.lower_limit
          upper = child.upper_limit
          if lower && upper && lower <= index && upper >= index
            return child.value(index)
          end
        end
      end

      nil
    end

    # Get numbers map from this node
    def numbers : Hash(Int32, T)?
      nums_array = @node[Cos::Name.new("Nums")]
      return unless nums_array.is_a?(Cos::Array)

      size = nums_array.size
      return unless size % 2 == 0

      result = {} of Int32 => T
      i = 0
      while i < size
        key_item = nums_array[i]
        value_item = nums_array[i + 1]

        if key_item.is_a?(Cos::Integer)
          key = key_item.value.to_i32
          # Convert value using converter
          value = @converter.call(value_item)
          result[key] = value
        end
        i += 2
      end

      result
    end

    # Set numbers for this node
    def numbers=(numbers : Hash(Int32, T)?)
      if numbers.nil?
        @node.delete(Cos::Name.new("Nums"))
        @node.delete(Cos::Name.new("Limits"))
      else
        # Sort keys
        sorted_keys = numbers.keys.sort!
        array = Cos::Array.new

        sorted_keys.each do |key|
          array.add(Cos::Integer.new(key.to_i64))
          value = numbers[key]
          if value.responds_to?(:cos_object)
            array.add(value.cos_object)
          else
            # Default: assume it's a COS object already
            array.add(value.as(Cos::Base))
          end
        end

        lower = sorted_keys.empty? ? nil : sorted_keys.first
        upper = sorted_keys.empty? ? nil : sorted_keys.last

        set_upper_limit(upper)
        set_lower_limit(lower)
        @node[Cos::Name.new("Nums")] = array
      end
    end

    # Get upper limit
    def upper_limit : Int32?
      limits = @node[Cos::Name.new("Limits")]
      return unless limits.is_a?(Cos::Array) && limits.size >= 2

      upper_item = limits[1]
      return unless upper_item.is_a?(Cos::Integer)

      upper_item.value.to_i32
    end

    # Get lower limit
    def lower_limit : Int32?
      limits = @node[Cos::Name.new("Limits")]
      return unless limits.is_a?(Cos::Array) && limits.size >= 2

      lower_item = limits[0]
      return unless lower_item.is_a?(Cos::Integer)

      lower_item.value.to_i32
    end

    private def set_upper_limit(upper : Int32?)
      limits = or_create_limits_array
      if upper
        limits[1] = Cos::Integer.new(upper.to_i64)
      else
        limits[1] = Cos::Null.instance
      end
    end

    private def set_lower_limit(lower : Int32?)
      limits = or_create_limits_array
      if lower
        limits[0] = Cos::Integer.new(lower.to_i64)
      else
        limits[0] = Cos::Null.instance
      end
    end

    private def or_create_limits_array : Cos::Array
      limits = @node[Cos::Name.new("Limits")]
      unless limits.is_a?(Cos::Array)
        limits = Cos::Array.new
        limits.add(Cos::Null.instance)
        limits.add(Cos::Null.instance)
        @node[Cos::Name.new("Limits")] = limits
      end
      limits
    end
  end

  # PDF document outline (bookmarks)
  # Corresponds to PDDocumentOutline in Apache PDFBox
  class DocumentOutline
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    def initialize
      @cos_dict = Cos::Dictionary.new
      @cos_dict[Cos::Name.new("Type")] = Cos::Name.new("Outlines")
    end

    def initialize(@cos_dict : Cos::Dictionary)
      @cos_dict[Cos::Name.new("Type")] = Cos::Name.new("Outlines")
    end

    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get the first child outline item
    def first_child : OutlineItem?
      first_dict = @cos_dict[Cos::Name.new("First")]
      return unless first_dict

      # Handle indirect references
      if first_dict.is_a?(Cos::Object)
        first_dict = first_dict.object
      end

      return unless first_dict.is_a?(Cos::Dictionary)

      OutlineItem.new(first_dict)
    end

    def last_child : OutlineItem?
      last_dict = @cos_dict[Cos::Name.new("Last")]
      return unless last_dict

      if last_dict.is_a?(Cos::Object)
        last_dict = last_dict.object
      end

      return unless last_dict.is_a?(Cos::Dictionary)
      OutlineItem.new(last_dict)
    end

    def add_last(new_child : OutlineItem) : Nil
      if new_child.next_sibling || new_child.previous_sibling
        raise ArgumentError.new("A single node with no siblings is required")
      end

      new_child.parent = self
      if previous_last = last_child
        previous_last.next_sibling = new_child
        new_child.previous_sibling = previous_last
      else
        @cos_dict[Cos::Name.new("First")] = new_child.cos_object
      end
      @cos_dict[Cos::Name.new("Last")] = new_child.cos_object
    end
  end

  # Individual outline item (bookmark)
  # Corresponds to PDOutlineItem in Apache PDFBox
  class OutlineItem
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    def initialize
      @cos_dict = Cos::Dictionary.new
    end

    def initialize(@cos_dict : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @cos_dict
    end

    def parent : DocumentOutline | OutlineItem?
      parent_dict = @cos_dict[Cos::Name.new("Parent")]
      return unless parent_dict
      if parent_dict.is_a?(Cos::Object)
        parent_dict = parent_dict.object
      end
      return unless parent_dict.is_a?(Cos::Dictionary)
      type = parent_dict[Cos::Name.new("Type")]
      if type.is_a?(Cos::Name) && type.value == "Outlines"
        DocumentOutline.new(parent_dict)
      else
        OutlineItem.new(parent_dict)
      end
    end

    def parent=(outline_node : DocumentOutline | OutlineItem) : DocumentOutline | OutlineItem
      @cos_dict[Cos::Name.new("Parent")] = outline_node.cos_object
      outline_node
    end

    # Get the title of this outline item
    def title : String?
      title_value = @cos_dict[Cos::Name.new("Title")]
      return unless title_value

      # Handle indirect references
      if title_value.is_a?(Cos::Object)
        title_value = title_value.object
      end

      if title_value.is_a?(Cos::String)
        title_value.value
      else
        # Try to convert to string (some PDFs have incorrect types)
        title_value.to_s
      end
    end

    def destination : Cos::Base?
      destination = @cos_dict[Cos::Name.new("Dest")]
      if destination.is_a?(Cos::Object)
        destination = destination.object
      end
      destination
    end

    def find_destination_page(document : Document) : Page?
      dest = destination
      return unless dest

      case dest
      when Cos::Array
        page_entry = dest[0]?
        return unless page_entry

        if page_entry.is_a?(Cos::Object)
          page_entry = page_entry.object
        end

        case page_entry
        when Cos::Dictionary
          Page.new(page_entry)
        when Cos::Integer
          page_number = page_entry.value.to_i
          return if page_number < 0 || page_number >= document.page_count
          document.get_page(page_number)
        else
          nil
        end
      else
        nil
      end
    end

    # Get the next sibling outline item
    def next_sibling : OutlineItem?
      next_dict = @cos_dict[Cos::Name.new("Next")]
      return unless next_dict

      # Handle indirect references
      if next_dict.is_a?(Cos::Object)
        next_dict = next_dict.object
      end

      return unless next_dict.is_a?(Cos::Dictionary)

      OutlineItem.new(next_dict)
    end

    def next_sibling=(outline_node : OutlineItem?) : OutlineItem?
      if outline_node
        @cos_dict[Cos::Name.new("Next")] = outline_node.cos_object
      else
        @cos_dict.delete(Cos::Name.new("Next"))
      end
      outline_node
    end

    # Get the previous sibling outline item
    def previous_sibling : OutlineItem?
      prev_dict = @cos_dict[Cos::Name.new("Prev")]
      return unless prev_dict

      # Handle indirect references
      if prev_dict.is_a?(Cos::Object)
        prev_dict = prev_dict.object
      end

      return unless prev_dict.is_a?(Cos::Dictionary)

      OutlineItem.new(prev_dict)
    end

    def previous_sibling=(outline_node : OutlineItem?) : OutlineItem?
      if outline_node
        @cos_dict[Cos::Name.new("Prev")] = outline_node.cos_object
      else
        @cos_dict.delete(Cos::Name.new("Prev"))
      end
      outline_node
    end

    # Get the first child outline item
    def first_child : OutlineItem?
      first_dict = @cos_dict[Cos::Name.new("First")]
      return unless first_dict

      # Handle indirect references
      if first_dict.is_a?(Cos::Object)
        first_dict = first_dict.object
      end

      return unless first_dict.is_a?(Cos::Dictionary)

      OutlineItem.new(first_dict)
    end

    # Get the last child outline item
    def last_child : OutlineItem?
      last_dict = @cos_dict[Cos::Name.new("Last")]
      return unless last_dict

      # Handle indirect references
      if last_dict.is_a?(Cos::Object)
        last_dict = last_dict.object
      end

      return unless last_dict.is_a?(Cos::Dictionary)

      OutlineItem.new(last_dict)
    end
  end

  # PDF document information (metadata)
  # Corresponds to PDDocumentInformation in Apache PDFBox
  class DocumentInformation
    @info_dict : Cos::Dictionary

    # Create a new empty document information object
    def initialize
      @info_dict = Cos::Dictionary.new
    end

    # Create from existing COS dictionary (typically from trailer)
    def initialize(@info_dict : Cos::Dictionary)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @info_dict
    end

    # Get the title of the document
    def title : String?
      string(Cos::Name.new("Title"))
    end

    # Set the title of the document
    def title=(title : String?) : Nil
      set_string(Cos::Name.new("Title"), title)
    end

    # Get the author of the document
    def author : String?
      string(Cos::Name.new("Author"))
    end

    # Set the author of the document
    def author=(author : String?) : Nil
      set_string(Cos::Name.new("Author"), author)
    end

    # Get the subject of the document
    def subject : String?
      string(Cos::Name.new("Subject"))
    end

    # Set the subject of the document
    def subject=(subject : String?) : Nil
      set_string(Cos::Name.new("Subject"), subject)
    end

    # Get keywords for the document
    def keywords : String?
      string(Cos::Name.new("Keywords"))
    end

    # Set keywords for the document
    def keywords=(keywords : String?) : Nil
      set_string(Cos::Name.new("Keywords"), keywords)
    end

    # Get the creator of the document
    def creator : String?
      string(Cos::Name.new("Creator"))
    end

    # Set the creator of the document
    def creator=(creator : String?) : Nil
      set_string(Cos::Name.new("Creator"), creator)
    end

    # Get the producer of the document
    def producer : String?
      string(Cos::Name.new("Producer"))
    end

    # Set the producer of the document
    def producer=(producer : String?) : Nil
      set_string(Cos::Name.new("Producer"), producer)
    end

    # Get the creation date as a string (PDF date format)
    def creation_date : String?
      string(Cos::Name.new("CreationDate"))
    end

    # Set the creation date (PDF date format string)
    def creation_date=(date : String?) : Nil
      set_string(Cos::Name.new("CreationDate"), date)
    end

    # Get the modification date as a string (PDF date format)
    def modification_date : String?
      string(Cos::Name.new("ModDate"))
    end

    # Set the modification date (PDF date format string)
    def modification_date=(date : String?) : Nil
      set_string(Cos::Name.new("ModDate"), date)
    end

    # Get the trapped value
    def trapped : String?
      string(Cos::Name.new("Trapped"))
    end

    # Set the trapped value
    def trapped=(trapped : String?) : Nil
      set_string(Cos::Name.new("Trapped"), trapped)
    end

    def metadata_keys : Array(String)
      @info_dict.entries.keys.map(&.value)
    end

    def custom_metadata_value(field_name : String) : String?
      string(Cos::Name.new(field_name))
    end

    private def string(name : Cos::Name) : String?
      value = @info_dict[name]
      return unless value

      # Handle indirect references
      if value.is_a?(Cos::Object)
        value = value.object
      end

      if value.is_a?(Cos::String)
        value.value
      else
        # Try to convert to string (some PDFs have incorrect types)
        value.to_s
      end
    end

    private def set_string(name : Cos::Name, value : String?) : Nil
      if value
        @info_dict[name] = Cos::String.new(value)
      else
        @info_dict.delete(name)
      end
    end
  end

  module Font
    # PDF font descriptor
    # Corresponds to PDFontDescriptor in Apache PDFBox

    # PDF font descriptor
    # Corresponds to PDFontDescriptor in Apache PDFBox
    class FontDescriptor
      Log = ::Log.for(self)

      @cos_dict : Cos::Dictionary

      def initialize(@cos_dict : Cos::Dictionary)
      end

      # Get the underlying COS dictionary
      def cos_object : Cos::Dictionary
        @cos_dict
      end

      # Get FontFile2 entry (embedded TrueType font)
      def font_file2 : Cos::Stream?
        font_file2_value = @cos_dict[Cos::Name.new("FontFile2")]
        return unless font_file2_value

        # Handle indirect references
        if font_file2_value.is_a?(Cos::Object)
          font_file2_value = font_file2_value.object
        end

        font_file2_value.as?(Cos::Stream)
      end

      # Get Length1 value from FontFile2 stream
      def length1 : Int32?
        stream = font_file2
        return unless stream

        length1_value = stream[Cos::Name.new("Length1")]
        return unless length1_value

        # Handle indirect references
        if length1_value.is_a?(Cos::Object)
          length1_value = length1_value.object
        end

        case length1_value
        when Cos::Integer
          length1_value.value.to_i32
        when Cos::String
          length1_value.value.to_i32? rescue nil
        when Cos::Float
          length1_value.value.to_i32
        end
      end
    end

    # PDF font base class
    # Corresponds to PDFont in Apache PDFBox
    class Font
      Log = ::Log.for(self)

      @cos_dict : Cos::Dictionary

      def initialize(@cos_dict : Cos::Dictionary)
      end

      # Get the underlying COS dictionary
      def cos_object : Cos::Dictionary
        @cos_dict
      end

      # Get font descriptor
      def font_descriptor : FontDescriptor?
        # Check for direct FontDescriptor entry
        descriptor_value = @cos_dict[Cos::Name.new("FontDescriptor")]
        if descriptor_value
          # Handle indirect references
          if descriptor_value.is_a?(Cos::Object)
            descriptor_value = descriptor_value.object
          end

          return FontDescriptor.new(descriptor_value) if descriptor_value.is_a?(Cos::Dictionary)
        end

        # Handle Type 0 fonts (composite fonts) which have DescendantFonts
        subtype_value = @cos_dict[Cos::Name.new("Subtype")]
        if subtype_value.is_a?(Cos::Name) && subtype_value.value == "Type0"
          descendant_fonts_value = @cos_dict[Cos::Name.new("DescendantFonts")]
          return unless descendant_fonts_value

          # Handle indirect references
          if descendant_fonts_value.is_a?(Cos::Object)
            descendant_fonts_value = descendant_fonts_value.object
          end

          return unless descendant_fonts_value.is_a?(Cos::Array)
          return if descendant_fonts_value.size == 0

          # Get first descendant font
          first_descendant = descendant_fonts_value[0]
          # Handle indirect references
          if first_descendant.is_a?(Cos::Object)
            first_descendant = first_descendant.object
          end

          return unless first_descendant.is_a?(Cos::Dictionary)

          # Create a Font instance for the descendant and get its descriptor
          descendant_font = Font.new(first_descendant)
          return descendant_font.font_descriptor
        end

        nil
      end
    end
  end

  # Page resources
  class Resources
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary

    def initialize(@cos_dict : Cos::Dictionary = Cos::Dictionary.new)
    end

    # Get the underlying COS dictionary
    def cos_object : Cos::Dictionary
      @cos_dict
    end

    # Get font by name
    def font(name : Cos::Name) : Font::PDFont?
      fonts_dict = @cos_dict[Cos::Name.new("Font")]
      return unless fonts_dict

      # Handle indirect references
      if fonts_dict.is_a?(Cos::Object)
        fonts_dict = fonts_dict.object
      end

      return unless fonts_dict.is_a?(Cos::Dictionary)

      font_dict = fonts_dict[name]
      return unless font_dict

      # Handle indirect references
      if font_dict.is_a?(Cos::Object)
        font_dict = font_dict.object
      end

      return unless font_dict.is_a?(Cos::Dictionary)

      Font::PDFontFactory.create_font(font_dict)
    end

    def font_names : Array(Cos::Name)
      fonts_dict = @cos_dict[Cos::Name.new("Font")]
      return [] of Cos::Name unless fonts_dict

      if fonts_dict.is_a?(Cos::Object)
        fonts_dict = fonts_dict.object
      end

      return [] of Cos::Name unless fonts_dict.is_a?(Cos::Dictionary)
      fonts_dict.entries.keys
    end

    def xobject(name : Cos::Name) : Cos::Base?
      xobjects_dict = @cos_dict[Cos::Name.new("XObject")]
      return unless xobjects_dict

      if xobjects_dict.is_a?(Cos::Object)
        xobjects_dict = xobjects_dict.object
      end

      return unless xobjects_dict.is_a?(Cos::Dictionary)

      xobject = xobjects_dict[name]?
      return unless xobject

      if xobject.is_a?(Cos::Object)
        xobject.object
      else
        xobject
      end
    end

    # Add an XObject to the resources with the given prefix, returns the resource name.
    # Java: PDResources.add(PDFormXObject, String)
    def add(xobject : Cos::Stream, prefix : String) : Cos::Name
      xobjects_dict = @cos_dict[Cos::Name.new("XObject")]?
      unless xobjects_dict
        xobjects_dict = Cos::Dictionary.new
        @cos_dict[Cos::Name.new("XObject")] = xobjects_dict
      end

      if xobjects_dict.is_a?(Cos::Object)
        xobjects_dict = xobjects_dict.object
      end

      return Cos::Name.new("#{prefix}0") unless xobjects_dict.is_a?(Cos::Dictionary)

      # Find the next available name
      index = 1
      while xobjects_dict.has_key?(Cos::Name.new("#{prefix}#{index}"))
        index += 1
      end

      name = Cos::Name.new("#{prefix}#{index}")
      xobjects_dict[name] = xobject
      name
    end
  end
end
