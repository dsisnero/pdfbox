require "xml"
require "../../cos"
require "../interactive/annotation/pdborder_style_dictionary"
require "../interactive/annotation/pdborder_effect_dictionary"
require "../common/pdrectangle"

module Pdfbox::Pdmodel::Fdf
  # Base class for FDF annotations (Java FDFAnnotation).
  # Backed by a COS dictionary; parsed from XFDF XML elements.
  abstract class FDFAnnotation
    Log = ::Log.for(self)

    FLAG_INVISIBLE       = 1
    FLAG_HIDDEN          = 1 << 1
    FLAG_PRINTED         = 1 << 2
    FLAG_NO_ZOOM         = 1 << 3
    FLAG_NO_ROTATE       = 1 << 4
    FLAG_NO_VIEW         = 1 << 5
    FLAG_READ_ONLY       = 1 << 6
    FLAG_LOCKED          = 1 << 7
    FLAG_TOGGLE_NO_VIEW  = 1 << 8
    FLAG_LOCKED_CONTENTS = 1 << 9

    @dictionary : Cos::Dictionary

    protected def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name::TYPE] = Cos::Name.new("Annot")
    end

    protected def initialize(@dictionary : Cos::Dictionary)
    end

    # Creates the correct FDFAnnotation for a COS dictionary, matching
    # FDFAnnotation.create(). Returns nil for unknown/unsupported subtypes.
    def self.create(cos_dict : Cos::Dictionary) : FDFAnnotation?
      return unless cos_dict

      subtype = cos_dict.get_name_as_string(Cos::Name::SUBTYPE)
      case subtype
      when FDFAnnotationText::SUBTYPE           then FDFAnnotationText.new(cos_dict)
      when FDFAnnotationCaret::SUBTYPE          then FDFAnnotationCaret.new(cos_dict)
      when FDFAnnotationFreeText::SUBTYPE       then FDFAnnotationFreeText.new(cos_dict)
      when FDFAnnotationFileAttachment::SUBTYPE then FDFAnnotationFileAttachment.new(cos_dict)
      when FDFAnnotationHighlight::SUBTYPE      then FDFAnnotationHighlight.new(cos_dict)
      when FDFAnnotationInk::SUBTYPE            then FDFAnnotationInk.new(cos_dict)
      when FDFAnnotationLine::SUBTYPE           then FDFAnnotationLine.new(cos_dict)
      when FDFAnnotationLink::SUBTYPE           then FDFAnnotationLink.new(cos_dict)
      when FDFAnnotationCircle::SUBTYPE         then FDFAnnotationCircle.new(cos_dict)
      when FDFAnnotationSquare::SUBTYPE         then FDFAnnotationSquare.new(cos_dict)
      when FDFAnnotationPolygon::SUBTYPE        then FDFAnnotationPolygon.new(cos_dict)
      when FDFAnnotationPolyline::SUBTYPE       then FDFAnnotationPolyline.new(cos_dict)
      when FDFAnnotationSound::SUBTYPE          then FDFAnnotationSound.new(cos_dict)
      when FDFAnnotationSquiggly::SUBTYPE       then FDFAnnotationSquiggly.new(cos_dict)
      when FDFAnnotationStamp::SUBTYPE          then FDFAnnotationStamp.new(cos_dict)
      when FDFAnnotationStrikeOut::SUBTYPE      then FDFAnnotationStrikeOut.new(cos_dict)
      when FDFAnnotationUnderline::SUBTYPE      then FDFAnnotationUnderline.new(cos_dict)
      else
        Log.warn { "Unknown or unsupported annotation type '#{subtype}'" }
        nil
      end
    end

    # Creates an FDFAnnotation from an XFDF element (element name defines type).
    def self.from_element(element : XML::Node) : FDFAnnotation?
      case element.name
      when "text"           then FDFAnnotationText.new(element)
      when "caret"          then FDFAnnotationCaret.new(element)
      when "freetext"       then FDFAnnotationFreeText.new(element)
      when "fileattachment" then FDFAnnotationFileAttachment.new(element)
      when "highlight"      then FDFAnnotationHighlight.new(element)
      when "ink"            then FDFAnnotationInk.new(element)
      when "line"           then FDFAnnotationLine.new(element)
      when "link"           then FDFAnnotationLink.new(element)
      when "circle"         then FDFAnnotationCircle.new(element)
      when "square"         then FDFAnnotationSquare.new(element)
      when "polygon"        then FDFAnnotationPolygon.new(element)
      when "polyline"       then FDFAnnotationPolyline.new(element)
      when "sound"          then FDFAnnotationSound.new(element)
      when "squiggly"       then FDFAnnotationSquiggly.new(element)
      when "stamp"          then FDFAnnotationStamp.new(element)
      when "strikeout"      then FDFAnnotationStrikeOut.new(element)
      when "underline"      then FDFAnnotationUnderline.new(element)
      else
        Log.warn { "Unknown or unsupported annotation type '#{element.name}'" }
        nil
      end
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # ---- XFDF element parsing (Java FDFAnnotation(Element)) ----

    protected def init_from_element(element : XML::Node) : Nil
      page = element["page"]?
      if page.nil? || page.empty?
        raise ::IO::Error.new("Error: missing required attribute 'page'")
      end
      self.page = page.to_i

      color = element["color"]?
      if color && color.size == 7 && color.starts_with?('#')
        color_value = color[1, 6].to_i(16)
        set_color(color_value)
      end

      self.date = element["date"]?

      if flags = element["flags"]?
        flags.split(',').each do |flag_token|
          case flag_token
          when "invisible"    then self.invisible = true
          when "hidden"       then self.hidden = true
          when "print"        then self.printed = true
          when "nozoom"       then self.no_zoom = true
          when "norotate"     then self.no_rotate = true
          when "noview"       then self.no_view = true
          when "readonly"     then self.read_only = true
          when "locked"       then self.locked = true
          when "togglenoview" then self.toggle_no_view = true
          end
        end
      end

      self.name = element["name"]?

      rect = element["rect"]?
      if rect.nil?
        raise ::IO::Error.new("Error: missing attribute 'rect'")
      end
      self.rectangle = parse_rectangle(rect, "Error: wrong amount of numbers in attribute 'rect'")

      self.title = element["title"]?

      if creation_date = element["creationdate"]?
        self.creation_date = creation_date
      end

      if opacity = self.class.attr_value(element, "opacity")
        self.opacity = opacity.to_f32
      end

      self.subject = element["subject"]?

      intent = self.class.attr_value(element, "intent") || self.class.attr_value(element, "IT")
      self.intent = intent if intent

      if contents_node = self.class.first_element_child(element, "contents")
        self.contents = contents_node.content
      end

      if rich_node = self.class.first_element_child(element, "contents-richtext")
        self.rich_contents = rich_contents_to_string(rich_node)
        self.contents = rich_node.content.strip
      end

      border_style = Interactive::Annotation::PDBorderStyleDictionary.new
      if width = self.class.attr_value(element, "width")
        border_style.width = width.to_f32
      end
      if border_style.width > 0
        if style = self.class.attr_value(element, "style")
          case style
          when "dash"
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_DASHED
          when "bevelled"
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_BEVELED
          when "inset"
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_INSET
          when "underline"
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
          when "cloudy"
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
            border_effect = Interactive::Annotation::PDBorderEffectDictionary.new
            border_effect.style = Interactive::Annotation::PDBorderEffectDictionary::STYLE_CLOUDY
            if intensity = self.class.attr_value(element, "intensity")
              border_effect.intensity = intensity.to_f32
            end
            self.border_effect = border_effect
          else
            border_style.style = Interactive::Annotation::PDBorderStyleDictionary::STYLE_SOLID
          end
        end
        if dashes = self.class.attr_value(element, "dashes")
          dash_values = dashes.split(',').map(&.strip)
          dash_pattern = Cos::Array.new
          dash_values.each do |dash_value|
            if int_value = dash_value.to_i64?
              dash_pattern.add(Cos::Integer.new(int_value))
            elsif float_value = dash_value.to_f64?
              dash_pattern.add(Cos::Float.new(float_value))
            end
          end
          border_style.dash_style = dash_pattern
        end
      end
      self.border_style = border_style
    end

    # ---- Getters/setters mirroring Java FDFAnnotation ----

    def page : Int32?
      value = @dictionary[Cos::Name.new("Page")]?
      case value
      when Cos::Integer
        value.value.to_i32
      when Cos::Float
        value.value.to_i32
      end
    end

    def page=(page : Int32) : Int32
      @dictionary.set_int(Cos::Name.new("Page"), page)
      page
    end

    def date : String?
      @dictionary.get_string(Cos::Name.new("M"))
    end

    def date=(date : String?) : String?
      set_string_entry(Cos::Name.new("M"), date)
      date
    end

    def invisible? : Bool
      flag_set?(FLAG_INVISIBLE)
    end

    def invisible=(invisible : Bool) : Bool
      set_flag(FLAG_INVISIBLE, invisible)
    end

    def hidden? : Bool
      flag_set?(FLAG_HIDDEN)
    end

    def hidden=(hidden : Bool) : Bool
      set_flag(FLAG_HIDDEN, hidden)
    end

    def printed? : Bool
      flag_set?(FLAG_PRINTED)
    end

    def printed=(printed : Bool) : Bool
      set_flag(FLAG_PRINTED, printed)
    end

    def no_zoom? : Bool
      flag_set?(FLAG_NO_ZOOM)
    end

    def no_zoom=(no_zoom : Bool) : Bool
      set_flag(FLAG_NO_ZOOM, no_zoom)
    end

    def no_rotate? : Bool
      flag_set?(FLAG_NO_ROTATE)
    end

    def no_rotate=(no_rotate : Bool) : Bool
      set_flag(FLAG_NO_ROTATE, no_rotate)
    end

    def no_view? : Bool
      flag_set?(FLAG_NO_VIEW)
    end

    def no_view=(no_view : Bool) : Bool
      set_flag(FLAG_NO_VIEW, no_view)
    end

    def read_only? : Bool
      flag_set?(FLAG_READ_ONLY)
    end

    def read_only=(read_only : Bool) : Bool
      set_flag(FLAG_READ_ONLY, read_only)
    end

    def locked? : Bool
      flag_set?(FLAG_LOCKED)
    end

    def locked=(locked : Bool) : Bool
      set_flag(FLAG_LOCKED, locked)
    end

    def toggle_no_view? : Bool
      flag_set?(FLAG_TOGGLE_NO_VIEW)
    end

    def toggle_no_view=(toggle_no_view : Bool) : Bool
      set_flag(FLAG_TOGGLE_NO_VIEW, toggle_no_view)
    end

    def locked_contents? : Bool
      flag_set?(FLAG_LOCKED_CONTENTS)
    end

    def locked_contents=(locked_contents : Bool) : Bool
      set_flag(FLAG_LOCKED_CONTENTS, locked_contents)
    end

    def name : String?
      @dictionary.get_string(Cos::Name.new("NM"))
    end

    def name=(name : String?) : String?
      set_string_entry(Cos::Name.new("NM"), name)
      name
    end

    def rectangle : Common::PDRectangle?
      rect_array = @dictionary.get_array(Cos::Name.new("Rect"))
      rect_array ? Common::PDRectangle.new(rect_array) : nil
    end

    def rectangle=(rectangle : Common::PDRectangle) : Common::PDRectangle
      @dictionary[Cos::Name.new("Rect")] = rectangle.cos_object
      rectangle
    end

    def contents : String?
      @dictionary.get_string(Cos::Name.new("Contents"))
    end

    def contents=(contents : String?) : String?
      set_string_entry(Cos::Name.new("Contents"), contents)
      contents
    end

    def title : String?
      @dictionary.get_string(Cos::Name.new("T"))
    end

    def title=(title : String?) : String?
      set_string_entry(Cos::Name.new("T"), title)
      title
    end

    def creation_date : String?
      @dictionary.get_string(Cos::Name::CREATION_DATE)
    end

    def creation_date=(creation_date : String?) : String?
      set_string_entry(Cos::Name::CREATION_DATE, creation_date)
      creation_date
    end

    def opacity : Float32
      @dictionary.get_float(Cos::Name.new("CA"), 1.0_f64).to_f32
    end

    def opacity=(opacity : Float32) : Float32
      @dictionary.set_float(Cos::Name.new("CA"), opacity.to_f64)
      opacity
    end

    def subject : String?
      @dictionary.get_string(Cos::Name.new("Subj"))
    end

    def subject=(subject : String?) : String?
      set_string_entry(Cos::Name.new("Subj"), subject)
      subject
    end

    def intent : String?
      @dictionary.get_name_as_string(Cos::Name.new("IT"))
    end

    def intent=(intent : String) : String
      @dictionary.set_name(Cos::Name.new("IT"), intent)
      intent
    end

    def rich_contents : String?
      value = @dictionary[Cos::Name.new("RC")]?
      case value
      when Cos::String
        value.value
      when Cos::Stream
        value.create_input_stream.gets_to_end
      else
        ""
      end
    end

    def rich_contents=(rc : String) : String
      @dictionary[Cos::Name.new("RC")] = Cos::String.new(rc)
      rc
    end

    def border_style : Interactive::Annotation::PDBorderStyleDictionary?
      bs = @dictionary.get_dictionary(Cos::Name.new("BS"))
      bs ? Interactive::Annotation::PDBorderStyleDictionary.new(bs) : nil
    end

    def border_style=(bs : Interactive::Annotation::PDBorderStyleDictionary) : Interactive::Annotation::PDBorderStyleDictionary
      @dictionary[Cos::Name.new("BS")] = bs.cos_object
      bs
    end

    def border_effect : Interactive::Annotation::PDBorderEffectDictionary?
      be = @dictionary.get_dictionary(Cos::Name.new("BE"))
      be ? Interactive::Annotation::PDBorderEffectDictionary.new(be) : nil
    end

    def border_effect=(be : Interactive::Annotation::PDBorderEffectDictionary) : Interactive::Annotation::PDBorderEffectDictionary
      @dictionary[Cos::Name.new("BE")] = be.cos_object
      be
    end

    # ---- helpers ----

    # Set or remove a string dictionary entry (nil removes it).
    private def set_string_entry(name : Cos::Name, value : String?) : Nil
      if value
        @dictionary.set_string(name, value)
      else
        @dictionary.delete(name)
      end
    end

    protected def set_color(color_value : Int32) : Nil
      r = ((color_value >> 16) & 0xFF).to_f32 / 255.0
      g = ((color_value >> 8) & 0xFF).to_f32 / 255.0
      b = (color_value & 0xFF).to_f32 / 255.0
      array = Cos::Array.new
      array.add(Cos::Float.new(r.to_f64))
      array.add(Cos::Float.new(g.to_f64))
      array.add(Cos::Float.new(b.to_f64))
      @dictionary[Cos::Name::C] = array
    end

    protected def color_rgb : Array(Float32)?
      array = @dictionary.get_array(Cos::Name::C)
      return unless array
      values = array.to_float_array.map(&.to_f32)
      values.size >= 3 ? values[0, 3] : nil
    end

    protected def parse_rectangle(rect : String, error_message : String) : Common::PDRectangle
      rect_values = rect.split(',')
      if rect_values.size != 4
        raise ::IO::Error.new(error_message)
      end
      Common::PDRectangle.new(
        rect_values[0].to_f32,
        rect_values[1].to_f32,
        rect_values[2].to_f32,
        rect_values[3].to_f32
      )
    end

    private def flag_set?(flag : Int32) : Bool
      flags = @dictionary.get_int(Cos::Name::F, 0_i64).to_i32
      (flags & flag) != 0
    end

    private def set_flag(flag : Int32, value : Bool) : Bool
      flags = @dictionary.get_int(Cos::Name::F, 0_i64).to_i32
      if value
        flags |= flag
      else
        flags &= ~flag
      end
      @dictionary.set_int(Cos::Name::F, flags)
      value
    end

    # Java FDFAnnotation#parseFloats applied to a string split on commas and/or
    # semicolons (used by ink gestures and polygon/polyline vertices). Java
    # String.split drops trailing empty fields.
    protected def parse_float_tokens(text : String) : Array(Float64)
      tokens = text.split(/[,;]/)
      while (last = tokens.last?) && last.empty?
        tokens.pop
      end
      tokens.map(&.to_f64)
    end

    protected def self.first_element_child(node : XML::Node, name : String) : XML::Node?
      node.children.find { |child| child.element? && child.name == name }
    end

    # Returns a non-empty attribute value, or nil when missing/blank.
    protected def self.attr_value(node : XML::Node, name : String) : String?
      value = node[name]?
      value unless value.nil? || value.empty?
    end

    # Reconstructs the rich contents HTML string (Java richContentsToString).
    protected def rich_contents_to_string(node : XML::Node) : String
      String.build do |str|
        node.children.each do |child|
          if child.element?
            str << element_to_string(child)
          elsif child.type == XML::Node::Type::TEXT_NODE
            cdata = child.content
            if cdata
              cdata = cdata.gsub("&", "&amp;").gsub("<", "&lt;")
            end
            str << cdata
          end
        end
      end
    end

    private def element_to_string(element : XML::Node) : String
      String.build do |str|
        str << '<' << element.name
        # Java DOM getAttributes() returns locally-declared attributes; the
        # raw serialization preserves exactly those (excluding inherited xmlns).
        open_tag = element.to_s
        close_idx = open_tag.index('>') || open_tag.size
        open_tag = open_tag[1, close_idx - 1]
        raw_attrs = parse_raw_attributes(open_tag)
        regular_attrs = [] of String
        xmlns_attrs = [] of String
        raw_attrs.each do |attr|
          if attr.starts_with?("xmlns=") || attr.starts_with?("xmlns:")
            xmlns_attrs << attr
          else
            regular_attrs << attr
          end
        end
        (regular_attrs + xmlns_attrs).each do |attr|
          str << ' ' << attr
        end
        str << '>'
        element.children.each do |child|
          if child.element?
            str << element_to_string(child)
          elsif child.type == XML::Node::Type::TEXT_NODE
            cdata = child.content
            if cdata
              cdata = cdata.gsub("&", "&amp;").gsub("<", "&lt;")
            end
            str << cdata
          end
        end
        str << "</" << element.name << '>'
      end
    end

    private def parse_raw_attributes(open_tag : String) : Array(String)
      attrs = [] of String
      index = 0
      # Skip the element name (first token)
      while index < open_tag.size && !open_tag[index].ascii_whitespace?
        index += 1
      end
      while index < open_tag.size
        # Skip element name (first token) or whitespace
        while index < open_tag.size && open_tag[index].ascii_whitespace?
          index += 1
        end
        break if index >= open_tag.size
        # Attribute name until '=' or whitespace
        name_start = index
        while index < open_tag.size && open_tag[index] != '=' && !open_tag[index].ascii_whitespace?
          index += 1
        end
        name = open_tag[name_start, index - name_start]
        # Skip whitespace before '='
        while index < open_tag.size && open_tag[index].ascii_whitespace?
          index += 1
        end
        if index < open_tag.size && open_tag[index] == '='
          index += 1
          while index < open_tag.size && open_tag[index].ascii_whitespace?
            index += 1
          end
          # Quoted value
          if index < open_tag.size && (open_tag[index] == '"' || open_tag[index] == '\'')
            quote = open_tag[index]
            index += 1
            value_start = index
            while index < open_tag.size && open_tag[index] != quote
              index += 1
            end
            value = open_tag[value_start, index - value_start]
            index += 1 if index < open_tag.size
            attrs << "#{name}=\"#{value}\""
          else
            value_start = index
            while index < open_tag.size && !open_tag[index].ascii_whitespace?
              index += 1
            end
            attrs << "#{name}=\"#{open_tag[value_start, index - value_start]}\""
          end
        else
          attrs << name
        end
      end
      attrs
    end
  end

  # Base class for FDF annotations with text-markup attributes (Java
  # FDFAnnotationTextMarkup). Highlight/Squiggly/StrikeOut/Underline share the
  # /QuadPoints coords surface.
  abstract class FDFAnnotationTextMarkup < FDFAnnotation
    protected def initialize
      super
    end

    protected def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    protected def initialize(element : XML::Node)
      super()
      init_from_element(element)

      coords_attr = element["coords"]?
      if coords_attr.nil? || coords_attr.empty?
        raise ::IO::Error.new("Error: missing attribute 'coords'")
      end
      # Java String.split(",") discards trailing empty fields (the fixture coords
      # end with a comma).
      coords_values = coords_attr.split(',')
      while (last = coords_values.last?) && last.empty?
        coords_values.pop
      end
      if coords_values.size < 8
        raise ::IO::Error.new("Error: too little numbers in attribute 'coords'")
      end
      self.coords = coords_values.map(&.to_f64)
    end

    # Set the coordinates of individual words or group of words (Java setCoords).
    # The coordinates for each quadrilateral are given as x1 y1 x2 y2 x3 y3 x4 y4.
    def coords=(coords : Enumerable(Float64)) : Nil
      array = Cos::Array.new
      coords.each { |value| array.add(Cos::Float.new(value)) }
      @dictionary.set_item(Cos::Name.new("QuadPoints"), array)
    end

    # Get the coordinates of individual words or group of words (Java getCoords).
    def coords : Array(Float64)?
      quad_points = @dictionary.get_array(Cos::Name.new("QuadPoints"))
      quad_points.try(&.to_float_array)
    end
  end
end
