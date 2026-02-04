# PDF Document Model module for PDFBox Crystal
#
# This module contains the high-level PDF document model classes,
# corresponding to the pdmodel package in Apache PDFBox.
module Pdfbox::Pdmodel
  # Main PDF document class
  class Document
    @cos_document : Cos::Dictionary?
    @version : String
    @pages : Array(Page)
    @catalog : DocumentCatalog?

    def initialize(@cos_document : Cos::Dictionary? = nil, @version : String = "1.4")
      @pages = [] of Page
      @catalog = @cos_document ? DocumentCatalog.new(@cos_document.as(Cos::Dictionary), self) : nil
    end

    # Get PDF version (e.g., "1.4")
    def version : String
      @version
    end

    # Set PDF version (e.g., "1.5")
    def version=(version : String) : String
      @version = version
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
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
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
        save(file)
      end
    end

    # Save the document to an IO stream
    def save(io : ::IO) : Nil
      # Use writer to write PDF
      writer = Pdfbox::Pdfwriter::Writer.new(io, self)
      writer.write
    end

    # Add a page to the document
    def add_page(page : Page) : Page
      @pages << page
      page
    end

    # Create and add a new page
    def add_page : Page
      page = Page.new
      add_page(page)
    end

    # Get all pages in the document
    def pages : Array(Page)
      @pages
    end

    # Get the number of pages
    def page_count : Int32
      pages.size
    end

    # Get the document catalog
    def document_catalog : DocumentCatalog?
      @catalog
    end

    # Get a page by index (0-based)
    def get_page(index : Int) : Page?
      pages[index]?
    end

    # Remove a page from the document
    def remove_page(page : Page) : Bool
      @pages.delete(page)
    end

    # Remove a page by index
    def remove_page(index : Int) : Bool
      !!@pages.delete_at?(index)
    end

    # Close the document and release resources
    def close : Nil
      # TODO: Implement cleanup
    end
  end

  # PDF page class
  class Page
    @cos_page : Cos::Dictionary?

    def initialize(@cos_page : Cos::Dictionary? = nil)
      # TODO: Initialize page structure
    end

    # Get page media box (boundaries)
    def media_box : Rectangle?
      # TODO: Implement media box retrieval
      nil
    end

    # Set page media box
    def media_box=(rect : Rectangle) : Rectangle
      # TODO: Implement media box setting
      rect
    end

    # Get page crop box
    def crop_box : Rectangle?
      # TODO: Implement crop box retrieval
      nil
    end

    # Set page crop box
    def crop_box=(rect : Rectangle) : Rectangle
      # TODO: Implement crop box setting
      rect
    end

    # Get page rotation
    def rotation : Int32
      # TODO: Implement rotation retrieval
      0
    end

    # Set page rotation
    def rotation=(degrees : Int32) : Int32
      # TODO: Implement rotation setting
      degrees
    end

    # Get page resources dictionary
    def resources : Cos::Dictionary?
      # TODO: Implement resources retrieval
      nil
    end

    # Get page contents stream
    def contents : Cos::Stream?
      # TODO: Implement contents retrieval
      nil
    end

    # Set page contents stream
    def contents=(stream : Cos::Stream) : Cos::Stream
      # TODO: Implement contents setting
      stream
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
  end

  # Common page sizes
  module PageSizes
    # US Letter: 8.5 x 11 inches
    LETTER = Rectangle.from_dimensions(612.0, 792.0) # 72 DPI

    # US Legal: 8.5 x 14 inches
    LEGAL = Rectangle.from_dimensions(612.0, 1008.0)

    # A4: 210 x 297 mm
    A4 = Rectangle.from_dimensions(595.0, 842.0)

    # A3: 297 x 420 mm
    A3 = Rectangle.from_dimensions(842.0, 1190.0)

    # A2: 420 x 594 mm
    A2 = Rectangle.from_dimensions(1190.0, 1684.0)

    # A1: 594 x 841 mm
    A1 = Rectangle.from_dimensions(1684.0, 2384.0)

    # A0: 841 x 1189 mm
    A0 = Rectangle.from_dimensions(2384.0, 3370.0)
  end

  # Document catalog class
  class DocumentCatalog
    Log = ::Log.for(self)

    @cos_dict : Cos::Dictionary
    @document : Document?

    def initialize(@cos_dict : Cos::Dictionary, @document : Document? = nil)
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
        if item.is_a?(Cos::Dictionary)
          result << NumberTreeNode(T).new(item) { |cos| @converter.call(cos) }
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
    def get_value(index : Int32) : T?
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
            return child.get_value(index)
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
      limits = get_or_create_limits_array
      if upper
        limits[1] = Cos::Integer.new(upper.to_i64)
      else
        limits[1] = Cos::Null.instance
      end
    end

    private def set_lower_limit(lower : Int32?)
      limits = get_or_create_limits_array
      if lower
        limits[0] = Cos::Integer.new(lower.to_i64)
      else
        limits[0] = Cos::Null.instance
      end
    end

    private def get_or_create_limits_array : Cos::Array
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
end
