require "./abstract_structured_type"
require "./abstract_simple_property"
require "./text_type"
require "./integer_type"
require "./date_type"

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

      def initialize(metadata : XMPMetadata)
        super(metadata)
        add_namespace(namespace, prefered_prefix)
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

      def initialize(metadata : XMPMetadata)
        super(metadata)
        add_namespace(namespace, prefered_prefix)
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

      def initialize(metadata : XMPMetadata)
        super(metadata)
        self.attribute = Attribute.new(XmpConstants::RDF_NAMESPACE, "parseType", "Resource")
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
        abs = first_equivalent_property(FORMAT, ChoiceType)
        abs.try(&.as(TextType).string_value)
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

      def initialize(metadata : XMPMetadata)
        super(metadata)
        add_namespace(namespace, prefered_prefix)
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

      def initialize(metadata : XMPMetadata)
        super(metadata)
        add_namespace(namespace, prefered_prefix)
      end

      def version_comment : String?
        property_value_as_string(VERSION_COMMENT)
      end

      def version_comment=(v : String)
        add_simple_property(VERSION_COMMENT, v)
      end
    end
  end
end
