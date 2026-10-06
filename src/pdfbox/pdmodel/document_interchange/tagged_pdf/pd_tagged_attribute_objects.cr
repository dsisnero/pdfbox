module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  # A Layout attribute object (Java PDLayoutAttributeObject).
  class PDLayoutAttributeObject < PDStandardAttributeObject
    OWNER_LAYOUT = "Layout"

    WIDTH_AUTO  = "Auto"
    HEIGHT_AUTO = "Auto"

    BLOCK_ALIGN_BEFORE  = "Before"
    BLOCK_ALIGN_MIDDLE  = "Middle"
    BLOCK_ALIGN_AFTER   = "After"
    BLOCK_ALIGN_JUSTIFY = "Justify"

    INLINE_ALIGN_START  = "Start"
    INLINE_ALIGN_CENTER = "Center"
    INLINE_ALIGN_END    = "End"

    LINE_HEIGHT_AUTO = "Auto"

    def initialize
      super
      self.owner = OWNER_LAYOUT
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def width : Float32 | String
      get_number_or_name("Width", WIDTH_AUTO)
    end

    def height : Float32 | String
      get_number_or_name("Height", HEIGHT_AUTO)
    end

    def block_align : String
      get_name("BlockAlign", BLOCK_ALIGN_BEFORE)
    end

    def block_align=(value : String) : Nil
      set_name("BlockAlign", value)
    end

    def inline_align : String
      get_name("InlineAlign", INLINE_ALIGN_START)
    end

    def inline_align=(value : String) : Nil
      set_name("InlineAlign", value)
    end
  end

  # A Table attribute object (Java PDTableAttributeObject).
  class PDTableAttributeObject < PDStandardAttributeObject
    OWNER_TABLE = "Table"

    SCOPE_BOTH   = "Both"
    SCOPE_COLUMN = "Column"
    SCOPE_ROW    = "Row"

    def initialize
      super
      self.owner = OWNER_TABLE
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def row_span : Int32
      get_integer("RowSpan", 1)
    end

    def row_span=(value : Int32) : Nil
      set_integer("RowSpan", value)
    end

    def col_span : Int32
      get_integer("ColSpan", 1)
    end

    def col_span=(value : Int32) : Nil
      set_integer("ColSpan", value)
    end

    def headers : Array(String)?
      array = cos_object.get_array(Cos::Name.new("Headers"))
      return unless array
      array.items.compact_map do |item|
        deref = item
        deref = deref.object if deref.is_a?(Cos::Object)
        deref.as?(Cos::Name).try(&.value)
      end
    end

    def headers=(values : Array(String)) : Nil
      array = Cos::Array.new
      values.each { |value| array.add(Cos::String.new(value)) }
      cos_object[Cos::Name.new("Headers")] = array
    end

    def scope : String?
      get_name("Scope")
    end

    def scope=(value : String) : Nil
      set_name("Scope", value)
    end

    def summary : String?
      get_string("Summary")
    end

    def summary=(value : String) : Nil
      set_string("Summary", value)
    end
  end

  # A List attribute object (Java PDListAttributeObject).
  class PDListAttributeObject < PDStandardAttributeObject
    OWNER_LIST = "List"

    def initialize
      super
      self.owner = OWNER_LIST
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end
  end

  # A PrintField attribute object (Java PDPrintFieldAttributeObject).
  class PDPrintFieldAttributeObject < PDStandardAttributeObject
    OWNER_PRINT_FIELD = "PrintField"

    def initialize
      super
      self.owner = OWNER_PRINT_FIELD
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end
  end

  # An ExportFormat attribute object (Java PDExportFormatAttributeObject).
  class PDExportFormatAttributeObject < PDLayoutAttributeObject
    OWNER_XML_1_00  = "XML-1.00"
    OWNER_HTML_3_20 = "HTML-3.2"
    OWNER_HTML_4_01 = "HTML-4.01"
    OWNER_OEB_1_00  = "OEB-1.00"
    OWNER_RTF_1_05  = "RTF-1.05"
    OWNER_CSS_1_00  = "CSS-1.00"
    OWNER_CSS_2_00  = "CSS-2.00"

    def initialize
      super
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end
  end
end
