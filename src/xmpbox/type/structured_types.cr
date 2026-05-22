require "./abstract_structured_type"
require "./abstract_simple_property"
require "./text_type"
require "./integer_type"
require "./boolean_type"
require "./real_type"
require "./date_type"
require "./array_property"

module Xmpbox
  module Type
    class ResourceEventType < AbstractStructuredType
      INSTANCE_ID    = "instanceID"
      SOFTWARE_AGENT = "softwareAgent"
      WHEN           = "when"
      ACTION         = "action"
      CHANGED        = "changed"
      PARAMETERS     = "parameters"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/ResourceEvent#", prefered_prefix: "stEvt"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def instance_id : String?
        property_value_as_string(INSTANCE_ID)
      end

      def instance_id=(value : String) : Nil
        add_simple_property(INSTANCE_ID, value)
      end

      def software_agent : String?
        property_value_as_string(SOFTWARE_AGENT)
      end

      def software_agent=(value : String) : Nil
        add_simple_property(SOFTWARE_AGENT, value)
      end

      def when : Time?
        date_property_as_calendar(WHEN)
      end

      def when=(value : Time) : Nil
        add_simple_property(WHEN, value)
      end

      def action : String?
        property_value_as_string(ACTION)
      end

      def action=(value : String) : Nil
        add_simple_property(ACTION, value)
      end

      def changed : String?
        property_value_as_string(CHANGED)
      end

      def changed=(value : String) : Nil
        add_simple_property(CHANGED, value)
      end

      def parameters : String?
        property_value_as_string(PARAMETERS)
      end

      def parameters=(value : String) : Nil
        add_simple_property(PARAMETERS, value)
      end
    end

    class ResourceRefType < AbstractStructuredType
      DOCUMENT_ID      = "documentID"
      FILE_PATH        = "filePath"
      INSTANCE_ID      = "instanceID"
      LAST_MODIFY_DATE = "lastModifyDate"
      MANAGE_TO        = "manageTo"
      MANAGE_UI        = "manageUI"
      MANAGER          = "manager"
      MANAGER_VARIANT  = "managerVariant"
      PART_MAPPING     = "partMapping"
      RENDITION_PARAMS = "renditionParams"
      VERSION_ID       = "versionID"
      MASK_MARKERS     = "maskMarkers"
      RENDITION_CLASS  = "renditionClass"
      FROM_PART        = "fromPart"
      TO_PART          = "toPart"
      ALTERNATE_PATHS  = "alternatePaths"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/ResourceRef#", prefered_prefix: "stRef"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def document_id : String?
        property_value_as_string(DOCUMENT_ID)
      end

      def document_id=(v : String)
        add_simple_property(DOCUMENT_ID, v)
      end

      def file_path : String?
        property_value_as_string(FILE_PATH)
      end

      def file_path=(v : String)
        add_simple_property(FILE_PATH, v)
      end

      def instance_id : String?
        property_value_as_string(INSTANCE_ID)
      end

      def instance_id=(v : String)
        add_simple_property(INSTANCE_ID, v)
      end

      def manage_to : String?
        property_value_as_string(MANAGE_TO)
      end

      def manage_to=(v : String)
        add_simple_property(MANAGE_TO, v)
      end

      def manage_ui : String?
        property_value_as_string(MANAGE_UI)
      end

      def manage_ui=(v : String)
        add_simple_property(MANAGE_UI, v)
      end

      def manager : String?
        property_value_as_string(MANAGER)
      end

      def manager=(v : String)
        add_simple_property(MANAGER, v)
      end

      def manager_variant : String?
        property_value_as_string(MANAGER_VARIANT)
      end

      def manager_variant=(v : String)
        add_simple_property(MANAGER_VARIANT, v)
      end

      def part_mapping : String?
        property_value_as_string(PART_MAPPING)
      end

      def part_mapping=(v : String)
        add_simple_property(PART_MAPPING, v)
      end

      def rendition_params : String?
        property_value_as_string(RENDITION_PARAMS)
      end

      def rendition_params=(v : String)
        add_simple_property(RENDITION_PARAMS, v)
      end

      def version_id : String?
        property_value_as_string(VERSION_ID)
      end

      def version_id=(v : String)
        add_simple_property(VERSION_ID, v)
      end

      def mask_markers : String?
        property_value_as_string(MASK_MARKERS)
      end

      def mask_markers=(v : String)
        add_simple_property(MASK_MARKERS, v)
      end

      def rendition_class : String?
        property_value_as_string(RENDITION_CLASS)
      end

      def rendition_class=(v : String)
        add_simple_property(RENDITION_CLASS, v)
      end

      def from_part : String?
        property_value_as_string(FROM_PART)
      end

      def from_part=(v : String)
        add_simple_property(FROM_PART, v)
      end

      def to_part : String?
        property_value_as_string(TO_PART)
      end

      def to_part=(v : String)
        add_simple_property(TO_PART, v)
      end

      def last_modify_date : Time?
        date_property_as_calendar(LAST_MODIFY_DATE)
      end

      def last_modify_date=(value : Time) : Nil
        add_simple_property(LAST_MODIFY_DATE, value)
      end

      def add_alternate_path(value : String) : Nil
        seq = first_equivalent_property(ALTERNATE_PATHS, ArrayProperty)
        unless seq
          seq = metadata.type_mapping.create_array_property(nil, prefered_prefix, ALTERNATE_PATHS, Cardinality::Seq)
          add_property(seq)
        end
        tm = metadata.type_mapping
        tt = tm.instanciate_simple_property(nil, "rdf", "li", value, Types::Text)
        seq.as(ArrayProperty).add_property(tt)
      end

      def alternate_paths_property : ArrayProperty?
        first_equivalent_property(ALTERNATE_PATHS, ArrayProperty).as?(ArrayProperty)
      end

      def alternate_paths : Array(String)?
        seq = first_equivalent_property(ALTERNATE_PATHS, ArrayProperty)
        return nil unless seq
        seq.as(ArrayProperty).elements_as_string
      end
    end

    class ThumbnailType < AbstractStructuredType
      FORMAT = "format"
      HEIGHT = "height"
      WIDTH  = "width"
      IMAGE  = "image"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/g/img/", prefered_prefix: "xmpGImg"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def height : Int32?
        abs = first_equivalent_property(HEIGHT, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def height=(val : Int32) : Nil
        add_simple_property(HEIGHT, val)
      end

      def width : Int32?
        abs = first_equivalent_property(WIDTH, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def width=(val : Int32) : Nil
        add_simple_property(WIDTH, val)
      end

      def image : String?
        abs = first_equivalent_property(IMAGE, TextType)
        abs.try(&.as(TextType).string_value)
      end

      def image=(val : String) : Nil
        add_simple_property(IMAGE, val)
      end

      def format : String?
        property_value_as_string(FORMAT)
      end

      def format=(val : String) : Nil
        add_simple_property(FORMAT, val)
      end
    end

    class FontType < AbstractStructuredType
      FONT_NAME      = "fontName"
      FONT_FAMILY    = "fontFamily"
      FONT_FACE      = "fontFace"
      FONT_TYPE      = "fontType"
      VERSION_STR    = "versionString"
      COMPOSITE      = "composite"
      CHILD_FONTS    = "childFontFiles"
      FONT_FILE_NAME = "fontFileName"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Font#", prefered_prefix: "stFnt"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def font_name : String?
        property_value_as_string(FONT_NAME)
      end

      def font_name=(v : String)
        add_simple_property(FONT_NAME, v)
      end

      def font_family : String?
        property_value_as_string(FONT_FAMILY)
      end

      def font_family=(v : String)
        add_simple_property(FONT_FAMILY, v)
      end

      def font_face : String?
        property_value_as_string(FONT_FACE)
      end

      def font_face=(v : String)
        add_simple_property(FONT_FACE, v)
      end

      def font_type : String?
        property_value_as_string(FONT_TYPE)
      end

      def font_type=(v : String)
        add_simple_property(FONT_TYPE, v)
      end

      def version_string : String?
        property_value_as_string(VERSION_STR)
      end

      def version_string=(v : String)
        add_simple_property(VERSION_STR, v)
      end

      def composite : String?
        property_value_as_string(COMPOSITE)
      end

      def composite=(v : String)
        add_simple_property(COMPOSITE, v)
      end

      def child_font_files : String?
        property_value_as_string(CHILD_FONTS)
      end

      def child_font_files=(v : String)
        add_simple_property(CHILD_FONTS, v)
      end

      def font_file_name : String?
        property_value_as_string(FONT_FILE_NAME)
      end

      def font_file_name=(v : String)
        add_simple_property(FONT_FILE_NAME, v)
      end
    end

    class VersionType < AbstractStructuredType
      VERSION_COMMENT = "versionComment"
      EVENT           = "Event"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Version#", prefered_prefix: "stVer"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def version_comment : String?
        property_value_as_string(VERSION_COMMENT)
      end

      def version_comment=(v : String)
        add_simple_property(VERSION_COMMENT, v)
      end
    end

    class ColorantType < AbstractStructuredType
      A           = "A"
      B           = "B"
      L           = "L"
      BLACK       = "black"
      CYAN        = "cyan"
      MAGENTA     = "magenta"
      YELLOW      = "yellow"
      BLUE        = "blue"
      GREEN       = "green"
      RED         = "red"
      MODE        = "mode"
      SWATCH_NAME = "swatchName"
      TYPE        = "type"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/g/", prefered_prefix: "xmpG"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def a : Int32?
        abs = first_equivalent_property(A, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def a=(val : Int32) : Nil
        add_simple_property(A, val)
      end

      def b : Int32?
        abs = first_equivalent_property(B, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def b=(val : Int32) : Nil
        add_simple_property(B, val)
      end

      def l : Float64?
        abs = first_equivalent_property(L, RealType)
        abs.try(&.as(RealType).value)
      end

      def l=(val : Float64) : Nil
        add_simple_property(L, val)
      end

      def black : Float64?
        abs = first_equivalent_property(BLACK, RealType)
        abs.try(&.as(RealType).value)
      end

      def black=(val : Float64) : Nil
        add_simple_property(BLACK, val)
      end

      def cyan : Float64?
        abs = first_equivalent_property(CYAN, RealType)
        abs.try(&.as(RealType).value)
      end

      def cyan=(val : Float64) : Nil
        add_simple_property(CYAN, val)
      end

      def magenta : Float64?
        abs = first_equivalent_property(MAGENTA, RealType)
        abs.try(&.as(RealType).value)
      end

      def magenta=(val : Float64) : Nil
        add_simple_property(MAGENTA, val)
      end

      def yellow : Float64?
        abs = first_equivalent_property(YELLOW, RealType)
        abs.try(&.as(RealType).value)
      end

      def yellow=(val : Float64) : Nil
        add_simple_property(YELLOW, val)
      end

      def blue : Int32?
        abs = first_equivalent_property(BLUE, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def blue=(val : Int32) : Nil
        add_simple_property(BLUE, val)
      end

      def green : Int32?
        abs = first_equivalent_property(GREEN, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def green=(val : Int32) : Nil
        add_simple_property(GREEN, val)
      end

      def red : Int32?
        abs = first_equivalent_property(RED, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def red=(val : Int32) : Nil
        add_simple_property(RED, val)
      end

      def mode : String?
        property_value_as_string(MODE)
      end

      def mode=(val : String) : Nil
        add_simple_property(MODE, val)
      end

      def swatch_name : String?
        property_value_as_string(SWATCH_NAME)
      end

      def swatch_name=(val : String) : Nil
        add_simple_property(SWATCH_NAME, val)
      end

      def type : String?
        property_value_as_string(TYPE)
      end

      def type=(val : String) : Nil
        add_simple_property(TYPE, val)
      end
    end

    class LayerType < AbstractStructuredType
      LAYER_NAME = "LayerName"
      LAYER_TEXT = "LayerText"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/photoshop/1.0/", prefered_prefix: "photoshop"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
        self.attribute = Attribute.new(XmpConstants::RDF_NAMESPACE, "parseType", "Resource")
      end

      def layer_name : String?
        abs = first_equivalent_property(LAYER_NAME, TextType)
        abs.try(&.as(TextType).string_value)
      end

      def layer_name=(image : String) : Nil
        add_property(create_text_type(LAYER_NAME, image))
      end

      def layer_text : String?
        abs = first_equivalent_property(LAYER_TEXT, TextType)
        abs.try(&.as(TextType).string_value)
      end

      def layer_text=(image : String) : Nil
        add_property(create_text_type(LAYER_TEXT, image))
      end
    end

    class JobType < AbstractStructuredType
      ID   = "id"
      NAME = "name"
      URL  = "url"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Job#", prefered_prefix: "stJob"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def id : String?
        property_value_as_string(ID)
      end

      def id=(val : String) : Nil
        add_simple_property(ID, val)
      end

      def name : String?
        property_value_as_string(NAME)
      end

      def name=(val : String) : Nil
        add_simple_property(NAME, val)
      end

      def url : String?
        property_value_as_string(URL)
      end

      def url=(val : String) : Nil
        add_simple_property(URL, val)
      end
    end

    class OECFType < AbstractStructuredType
      COLUMNS = "Columns"
      NAMES   = "Names"
      ROWS    = "Rows"
      VALUES  = "Values"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def columns : Int32?
        abs = first_equivalent_property(COLUMNS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def columns=(val : Int32) : Nil
        add_simple_property(COLUMNS, val)
      end

      def names : Array(String)?
        seq = first_equivalent_property(NAMES, ArrayProperty)
        seq.try(&.as(ArrayProperty).elements_as_string)
      end

      def rows : Int32?
        abs = first_equivalent_property(ROWS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def rows=(val : Int32) : Nil
        add_simple_property(ROWS, val)
      end

      def values : Array(String)?
        seq = first_equivalent_property(VALUES, ArrayProperty)
        seq.try(&.as(ArrayProperty).elements_as_string)
      end
    end

    class CFAPatternType < AbstractStructuredType
      COLUMNS = "Columns"
      ROWS    = "Rows"
      VALUES  = "Values"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def columns : Int32?
        abs = first_equivalent_property(COLUMNS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def columns=(val : Int32) : Nil
        add_simple_property(COLUMNS, val)
      end

      def rows : Int32?
        abs = first_equivalent_property(ROWS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def rows=(val : Int32) : Nil
        add_simple_property(ROWS, val)
      end

      def values : Array(String)?
        seq = first_equivalent_property(VALUES, ArrayProperty)
        seq.try(&.as(ArrayProperty).elements_as_string)
      end
    end

    class DeviceSettingsType < AbstractStructuredType
      COLUMNS  = "Columns"
      ROWS     = "Rows"
      SETTINGS = "Settings"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def columns : Int32?
        abs = first_equivalent_property(COLUMNS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def columns=(val : Int32) : Nil
        add_simple_property(COLUMNS, val)
      end

      def rows : Int32?
        abs = first_equivalent_property(ROWS, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def rows=(val : Int32) : Nil
        add_simple_property(ROWS, val)
      end

      def settings : Array(String)?
        seq = first_equivalent_property(SETTINGS, ArrayProperty)
        seq.try(&.as(ArrayProperty).elements_as_string)
      end
    end

    class FlashType < AbstractStructuredType
      FIRED        = "Fired"
      FUNCTION     = "Function"
      RED_EYE_MODE = "RedEyeMode"
      MODE         = "Mode"
      RETURN       = "Return"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/exif/1.0/", prefered_prefix: "exif"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def fired : Bool?
        abs = first_equivalent_property(FIRED, BooleanType)
        abs.try(&.as(BooleanType).value)
      end

      def fired=(val : Bool) : Nil
        add_simple_property(FIRED, val)
      end

      def function : Bool?
        abs = first_equivalent_property(FUNCTION, BooleanType)
        abs.try(&.as(BooleanType).value)
      end

      def function=(val : Bool) : Nil
        add_simple_property(FUNCTION, val)
      end

      def red_eye_mode : Bool?
        abs = first_equivalent_property(RED_EYE_MODE, BooleanType)
        abs.try(&.as(BooleanType).value)
      end

      def red_eye_mode=(val : Bool) : Nil
        add_simple_property(RED_EYE_MODE, val)
      end

      def mode : Int32?
        abs = first_equivalent_property(MODE, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def mode=(val : Int32) : Nil
        add_simple_property(MODE, val)
      end

      def return_ : Int32?
        abs = first_equivalent_property(RETURN, IntegerType)
        abs.try(&.as(IntegerType).value)
      end

      def return_=(val : Int32) : Nil
        add_simple_property(RETURN, val)
      end
    end

    class DimensionsType < AbstractStructuredType
      H    = "h"
      W    = "w"
      UNIT = "unit"

      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Dimensions#", prefered_prefix: "stDim"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def h : Float64?
        abs = first_equivalent_property(H, RealType)
        abs.try(&.as(RealType).value)
      end

      def h=(val : Float64) : Nil
        add_simple_property(H, val)
      end

      def w : Float64?
        abs = first_equivalent_property(W, RealType)
        abs.try(&.as(RealType).value)
      end

      def w=(val : Float64) : Nil
        add_simple_property(W, val)
      end

      def unit : String?
        property_value_as_string(UNIT)
      end

      def unit=(val : String) : Nil
        add_simple_property(UNIT, val)
      end
    end

    class PDFASchemaType < AbstractStructuredType
      SCHEMA        = "schema"
      NAMESPACE_URI = "namespaceURI"
      PREFIX        = "prefix"
      PROPERTY      = "property"
      VALUE_TYPE    = "valueType"

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/schema#", prefered_prefix: "pdfaSchema"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def namespace_uri_value : String?
        property_value_as_string(NAMESPACE_URI)
      end

      def prefix_value : String?
        property_value_as_string(PREFIX)
      end

      def schema_property : ArrayProperty?
        first_equivalent_property(PROPERTY, ArrayProperty).as?(ArrayProperty)
      end

      def value_type_property : ArrayProperty?
        first_equivalent_property(VALUE_TYPE, ArrayProperty).as?(ArrayProperty)
      end
    end

    class PDFAFieldType < AbstractStructuredType
      NAME        = "name"
      VALUE_TYPE  = "valueType"
      DESCRIPTION = "description"

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/field#", prefered_prefix: "pdfaField"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def name_value : String?
        property_value_as_string(NAME)
      end

      def value_type : String?
        property_value_as_string(VALUE_TYPE)
      end

      def description : String?
        property_value_as_string(DESCRIPTION)
      end
    end

    class PDFAPropertyType < AbstractStructuredType
      NAME        = "name"
      VALUE_TYPE  = "valueType"
      CATEGORY    = "category"
      DESCRIPTION = "description"

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/property#", prefered_prefix: "pdfaProperty"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def name_value : String?
        property_value_as_string(NAME)
      end

      def value_type : String?
        property_value_as_string(VALUE_TYPE)
      end

      def category : String?
        property_value_as_string(CATEGORY)
      end

      def description : String?
        property_value_as_string(DESCRIPTION)
      end
    end

    class PDFATypeType < AbstractStructuredType
      TYPE        = "type"
      NS_URI      = "namespaceURI"
      PREFIX      = "prefix"
      DESCRIPTION = "description"
      FIELD       = "field"

      def self.structured_type_info
        {namespace: "http://www.aiim.org/pdfa/ns/type#", prefered_prefix: "pdfaType"}
      end

      def initialize(metadata : XMPMetadata, namespace_uri = nil, field_prefix = nil, property_name = nil)
        super(metadata, namespace_uri, field_prefix, property_name)
        add_namespace(namespace.as(String), prefered_prefix.as(String))
      end

      def type_value : String?
        property_value_as_string(TYPE)
      end

      def namespace_uri_value : String?
        property_value_as_string(NS_URI)
      end

      def prefix_value : String?
        property_value_as_string(PREFIX)
      end

      def description : String?
        property_value_as_string(DESCRIPTION)
      end

      def field_property : ArrayProperty?
        first_equivalent_property(FIELD, ArrayProperty).as?(ArrayProperty)
      end
    end
  end
end
