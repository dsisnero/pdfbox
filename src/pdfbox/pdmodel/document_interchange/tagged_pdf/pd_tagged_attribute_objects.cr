module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  # A Layout attribute object (Java PDLayoutAttributeObject).
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDLayoutAttributeObject.java
  class PDLayoutAttributeObject < PDStandardAttributeObject
    OWNER_LAYOUT = "Layout"

    PLACEMENT                  = "Placement"
    WRITING_MODE               = "WritingMode"
    BACKGROUND_COLOR           = "BackgroundColor"
    BORDER_COLOR               = "BorderColor"
    BORDER_STYLE               = "BorderStyle"
    BORDER_THICKNESS           = "BorderThickness"
    PADDING                    = "Padding"
    COLOR                      = "Color"
    SPACE_BEFORE               = "SpaceBefore"
    SPACE_AFTER                = "SpaceAfter"
    START_INDENT               = "StartIndent"
    END_INDENT                 = "EndIndent"
    TEXT_INDENT                = "TextIndent"
    TEXT_ALIGN                 = "TextAlign"
    BBOX                       = "BBox"
    WIDTH                      = "Width"
    HEIGHT                     = "Height"
    BLOCK_ALIGN                = "BlockAlign"
    INLINE_ALIGN               = "InlineAlign"
    T_BORDER_STYLE             = "TBorderStyle"
    T_PADDING                  = "TPadding"
    BASELINE_SHIFT             = "BaselineShift"
    LINE_HEIGHT                = "LineHeight"
    TEXT_DECORATION_COLOR      = "TextDecorationColor"
    TEXT_DECORATION_THICKNESS  = "TextDecorationThickness"
    TEXT_DECORATION_TYPE       = "TextDecorationType"
    RUBY_ALIGN                 = "RubyAlign"
    RUBY_POSITION              = "RubyPosition"
    GLYPH_ORIENTATION_VERTICAL = "GlyphOrientationVertical"
    COLUMN_COUNT               = "ColumnCount"
    COLUMN_GAP                 = "ColumnGap"
    COLUMN_WIDTHS              = "ColumnWidths"

    PLACEMENT_BLOCK  = "Block"
    PLACEMENT_INLINE = "Inline"
    PLACEMENT_BEFORE = "Before"
    PLACEMENT_START  = "Start"
    PLACEMENT_END    = "End"

    WRITING_MODE_LRTB = "LrTb"
    WRITING_MODE_RLTB = "RlTb"
    WRITING_MODE_TBRL = "TbRl"

    BORDER_STYLE_NONE   = "None"
    BORDER_STYLE_HIDDEN = "Hidden"
    BORDER_STYLE_DOTTED = "Dotted"
    BORDER_STYLE_DASHED = "Dashed"
    BORDER_STYLE_SOLID  = "Solid"
    BORDER_STYLE_DOUBLE = "Double"
    BORDER_STYLE_GROOVE = "Groove"
    BORDER_STYLE_RIDGE  = "Ridge"
    BORDER_STYLE_INSET  = "Inset"
    BORDER_STYLE_OUTSET = "Outset"

    TEXT_ALIGN_START   = "Start"
    TEXT_ALIGN_CENTER  = "Center"
    TEXT_ALIGN_END     = "End"
    TEXT_ALIGN_JUSTIFY = "Justify"

    WIDTH_AUTO  = "Auto"
    HEIGHT_AUTO = "Auto"

    BLOCK_ALIGN_BEFORE  = "Before"
    BLOCK_ALIGN_MIDDLE  = "Middle"
    BLOCK_ALIGN_AFTER   = "After"
    BLOCK_ALIGN_JUSTIFY = "Justify"

    INLINE_ALIGN_START  = "Start"
    INLINE_ALIGN_CENTER = "Center"
    INLINE_ALIGN_END    = "End"

    LINE_HEIGHT_NORMAL = "Normal"
    LINE_HEIGHT_AUTO   = "Auto"

    TEXT_DECORATION_TYPE_NONE         = "None"
    TEXT_DECORATION_TYPE_UNDERLINE    = "Underline"
    TEXT_DECORATION_TYPE_OVERLINE     = "Overline"
    TEXT_DECORATION_TYPE_LINE_THROUGH = "LineThrough"

    RUBY_ALIGN_START      = "Start"
    RUBY_ALIGN_CENTER     = "Center"
    RUBY_ALIGN_END        = "End"
    RUBY_ALIGN_JUSTIFY    = "Justify"
    RUBY_ALIGN_DISTRIBUTE = "Distribute"

    RUBY_POSITION_BEFORE  = "Before"
    RUBY_POSITION_AFTER   = "After"
    RUBY_POSITION_WARICHU = "Warichu"
    RUBY_POSITION_INLINE  = "Inline"

    GLYPH_ORIENTATION_VERTICAL_AUTO              = "Auto"
    GLYPH_ORIENTATION_VERTICAL_MINUS_180_DEGREES = "-180"
    GLYPH_ORIENTATION_VERTICAL_MINUS_90_DEGREES  = "-90"
    GLYPH_ORIENTATION_VERTICAL_ZERO_DEGREES      = "0"
    GLYPH_ORIENTATION_VERTICAL_90_DEGREES        = "90"
    GLYPH_ORIENTATION_VERTICAL_180_DEGREES       = "180"
    GLYPH_ORIENTATION_VERTICAL_270_DEGREES       = "270"
    GLYPH_ORIENTATION_VERTICAL_360_DEGREES       = "360"

    def initialize
      super
      self.owner = OWNER_LAYOUT
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def placement : String
      get_name(PLACEMENT, PLACEMENT_INLINE)
    end

    def placement=(value : String) : Nil
      set_name(PLACEMENT, value)
    end

    def writing_mode : String
      get_name(WRITING_MODE, WRITING_MODE_LRTB)
    end

    def writing_mode=(value : String) : Nil
      set_name(WRITING_MODE, value)
    end

    def background_color : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      get_color(BACKGROUND_COLOR)
    end

    def background_color=(value : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_color(BACKGROUND_COLOR, value)
    end

    def border_colors : Pdfbox::Pdmodel::Graphics::Color::PDGamma | PDFourColours | Nil
      get_color_or_four_colors(BORDER_COLOR)
    end

    def all_border_colors=(value : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_color(BORDER_COLOR, value)
    end

    def border_colors=(value : PDFourColours) : Nil
      set_four_colors(BORDER_COLOR, value)
    end

    def border_style : String | Array(String)
      get_name_or_array_of_name(BORDER_STYLE, BORDER_STYLE_NONE)
    end

    def all_border_styles=(style : String) : Nil
      set_name(BORDER_STYLE, style)
    end

    def border_styles=(styles : Array(String)) : Nil
      set_array_of_name(BORDER_STYLE, styles)
    end

    def border_thickness : Float32 | Array(Float32) | Nil
      get_number_or_array_of_number(BORDER_THICKNESS, UNSPECIFIED)
    end

    def all_border_thicknesses=(value : Number) : Nil
      set_number(BORDER_THICKNESS, value)
    end

    def border_thicknesses=(values : Array(Float32)) : Nil
      set_array_of_number(BORDER_THICKNESS, values)
    end

    def padding : Float32 | Array(Float32) | Nil
      get_number_or_array_of_number(PADDING, 0.0_f32)
    end

    def all_paddings=(value : Number) : Nil
      set_number(PADDING, value)
    end

    def paddings=(values : Array(Float32)) : Nil
      set_array_of_number(PADDING, values)
    end

    def color : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      get_color(COLOR)
    end

    def color=(value : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_color(COLOR, value)
    end

    def space_before : Float32
      get_number(SPACE_BEFORE, 0.0)
    end

    def space_before=(value : Number) : Nil
      set_number(SPACE_BEFORE, value)
    end

    def space_after : Float32
      get_number(SPACE_AFTER, 0.0)
    end

    def space_after=(value : Number) : Nil
      set_number(SPACE_AFTER, value)
    end

    def start_indent : Float32
      get_number(START_INDENT, 0.0)
    end

    def start_indent=(value : Number) : Nil
      set_number(START_INDENT, value)
    end

    def end_indent : Float32
      get_number(END_INDENT, 0.0)
    end

    def end_indent=(value : Number) : Nil
      set_number(END_INDENT, value)
    end

    def text_indent : Float32
      get_number(TEXT_INDENT, 0.0)
    end

    def text_indent=(value : Number) : Nil
      set_number(TEXT_INDENT, value)
    end

    def text_align : String
      get_name(TEXT_ALIGN, TEXT_ALIGN_START)
    end

    def text_align=(value : String) : Nil
      set_name(TEXT_ALIGN, value)
    end

    def bbox : Pdfbox::Pdmodel::Common::PDRectangle?
      array = cos_object.get_array(Cos::Name.new(BBOX))
      array ? Pdfbox::Pdmodel::Common::PDRectangle.new(array) : nil
    end

    def bbox=(value : Pdfbox::Pdmodel::Common::PDRectangle?) : Nil
      key = Cos::Name.new(BBOX)
      if value
        cos_object[key] = value.cos_object
      else
        cos_object.delete(key)
      end
    end

    def width : Float32 | String
      get_number_or_name(WIDTH, WIDTH_AUTO)
    end

    def set_width_auto : Nil
      set_name(WIDTH, WIDTH_AUTO)
    end

    def width=(value : Number) : Nil
      set_number(WIDTH, value)
    end

    def height : Float32 | String
      get_number_or_name(HEIGHT, HEIGHT_AUTO)
    end

    def set_height_auto : Nil
      set_name(HEIGHT, HEIGHT_AUTO)
    end

    def height=(value : Number) : Nil
      set_number(HEIGHT, value)
    end

    def block_align : String
      get_name(BLOCK_ALIGN, BLOCK_ALIGN_BEFORE)
    end

    def block_align=(value : String) : Nil
      set_name(BLOCK_ALIGN, value)
    end

    def inline_align : String
      get_name(INLINE_ALIGN, INLINE_ALIGN_START)
    end

    def inline_align=(value : String) : Nil
      set_name(INLINE_ALIGN, value)
    end

    def t_border_style : String | Array(String)
      get_name_or_array_of_name(T_BORDER_STYLE, BORDER_STYLE_NONE)
    end

    def all_t_border_styles=(style : String) : Nil
      set_name(T_BORDER_STYLE, style)
    end

    def t_border_styles=(styles : Array(String)) : Nil
      set_array_of_name(T_BORDER_STYLE, styles)
    end

    def t_padding : Float32 | Array(Float32) | Nil
      get_number_or_array_of_number(T_PADDING, 0.0_f32)
    end

    def all_t_paddings=(value : Number) : Nil
      set_number(T_PADDING, value)
    end

    def t_paddings=(values : Array(Float32)) : Nil
      set_array_of_number(T_PADDING, values)
    end

    def baseline_shift : Float32
      get_number(BASELINE_SHIFT, 0.0)
    end

    def baseline_shift=(value : Number) : Nil
      set_number(BASELINE_SHIFT, value)
    end

    def line_height : Float32 | String
      get_number_or_name(LINE_HEIGHT, LINE_HEIGHT_NORMAL)
    end

    def set_line_height_normal : Nil
      set_name(LINE_HEIGHT, LINE_HEIGHT_NORMAL)
    end

    def set_line_height_auto : Nil
      set_name(LINE_HEIGHT, LINE_HEIGHT_AUTO)
    end

    def line_height=(value : Number) : Nil
      set_number(LINE_HEIGHT, value)
    end

    def text_decoration_color : Pdfbox::Pdmodel::Graphics::Color::PDGamma?
      get_color(TEXT_DECORATION_COLOR)
    end

    def text_decoration_color=(value : Pdfbox::Pdmodel::Graphics::Color::PDGamma?) : Nil
      set_color(TEXT_DECORATION_COLOR, value)
    end

    def text_decoration_thickness : Float32
      get_number(TEXT_DECORATION_THICKNESS)
    end

    def text_decoration_thickness=(value : Number) : Nil
      set_number(TEXT_DECORATION_THICKNESS, value)
    end

    def text_decoration_type : String
      get_name(TEXT_DECORATION_TYPE, TEXT_DECORATION_TYPE_NONE)
    end

    def text_decoration_type=(value : String) : Nil
      set_name(TEXT_DECORATION_TYPE, value)
    end

    def ruby_align : String
      get_name(RUBY_ALIGN, RUBY_ALIGN_DISTRIBUTE)
    end

    def ruby_align=(value : String) : Nil
      set_name(RUBY_ALIGN, value)
    end

    def ruby_position : String
      get_name(RUBY_POSITION, RUBY_POSITION_BEFORE)
    end

    def ruby_position=(value : String) : Nil
      set_name(RUBY_POSITION, value)
    end

    def glyph_orientation_vertical : String
      get_name(GLYPH_ORIENTATION_VERTICAL, GLYPH_ORIENTATION_VERTICAL_AUTO)
    end

    def glyph_orientation_vertical=(value : String) : Nil
      set_name(GLYPH_ORIENTATION_VERTICAL, value)
    end

    def column_count : Int32
      get_integer(COLUMN_COUNT, 1)
    end

    def column_count=(value : Int32) : Nil
      set_integer(COLUMN_COUNT, value)
    end

    def column_gap : Float32 | Array(Float32) | Nil
      get_number_or_array_of_number(COLUMN_GAP, UNSPECIFIED)
    end

    def column_gap=(value : Number) : Nil
      set_number(COLUMN_GAP, value)
    end

    def column_gaps=(values : Array(Float32)) : Nil
      set_array_of_number(COLUMN_GAP, values)
    end

    def column_widths : Float32 | Array(Float32) | Nil
      get_number_or_array_of_number(COLUMN_WIDTHS, UNSPECIFIED)
    end

    def all_column_widths=(value : Number) : Nil
      set_number(COLUMN_WIDTHS, value)
    end

    def column_widths=(values : Array(Float32)) : Nil
      set_array_of_number(COLUMN_WIDTHS, values)
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

    ROLE    = "Role"
    CHECKED = "checked"
    DESC    = "Desc"

    ROLE_RB = "rb"
    ROLE_CB = "cb"
    ROLE_PB = "pb"
    ROLE_TV = "tv"

    CHECKED_STATE_ON      = "on"
    CHECKED_STATE_OFF     = "off"
    CHECKED_STATE_NEUTRAL = "neutral"

    def initialize
      super
      self.owner = OWNER_PRINT_FIELD
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    # The role (/Role), or nil (Java getRole).
    def role : String?
      get_name(ROLE)
    end

    def role=(role : String) : Nil
      set_name(ROLE, role)
    end

    # The checked state (/checked), defaulting to "off" (Java getCheckedState).
    def checked_state : String
      get_name(CHECKED, CHECKED_STATE_OFF)
    end

    def checked_state=(checked_state : String) : Nil
      set_name(CHECKED, checked_state)
    end

    # The alternate name (/Desc), or nil (Java getAlternateName).
    def alternate_name : String?
      get_string(DESC)
    end

    def alternate_name=(alternate_name : String) : Nil
      set_string(DESC, alternate_name)
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
