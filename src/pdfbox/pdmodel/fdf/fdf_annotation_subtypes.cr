require "xml"
require "./fdf_annotation"

module Pdfbox::Pdmodel::Fdf
  class FDFAnnotationText < FDFAnnotation
    SUBTYPE = "Text"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
    end

    def icon : String?
      @dictionary.get_name_as_string(Cos::Name.new("Name"))
    end
  end

  class FDFAnnotationCaret < FDFAnnotation
    SUBTYPE = "Caret"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      init_fringe(element)

      if symbol = self.class.attr_value(element, "symbol")
        self.symbol = symbol
      end
    end

    # Set/get the caret symbol (/Sy): Java maps "paragraph" to "P", anything
    # else to "None".
    def symbol=(symbol : String) : String
      new_symbol = symbol == "paragraph" ? "P" : "None"
      @dictionary.set_string(Cos::Name.new("Sy"), new_symbol)
      new_symbol
    end

    def symbol : String?
      @dictionary.get_string(Cos::Name.new("Sy"))
    end
  end

  class FDFAnnotationFreeText < FDFAnnotation
    SUBTYPE = "FreeText"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)

      justification = element["justification"]?
      self.justification = justification

      if da = FDFAnnotation.first_element_child(element, "defaultappearance")
        self.default_appearance = da.content
      end
      if ds = FDFAnnotation.first_element_child(element, "defaultstyle")
        self.default_style = ds.content
      end
      if callout = FDFAnnotation.attr_value(element, "callout")
        values = callout.split(',').map(&.strip).map(&.to_f32)
        self.callout = values
      end
      if rotation = FDFAnnotation.attr_value(element, "rotation")
        self.rotation = rotation.to_i
      end
      init_fringe(element)
      if line_ending = FDFAnnotation.attr_value(element, "head")
        self.line_ending_style = line_ending
      end
    end

    def default_appearance : String?
      @dictionary.get_string(Cos::Name.new("DA"))
    end

    def default_appearance=(value : String) : String
      @dictionary.set_string(Cos::Name.new("DA"), value)
      value
    end

    def default_style : String?
      @dictionary.get_string(Cos::Name.new("DS"))
    end

    def default_style=(value : String) : String
      @dictionary.set_string(Cos::Name.new("DS"), value)
      value
    end

    def callout : Array(Float32)?
      array = @dictionary.get_array(Cos::Name.new("CL"))
      return unless array
      values = [] of Float32
      array.items.each do |item|
        case item
        when Cos::Integer
          values << item.value.to_f32
        when Cos::Float
          values << item.value.to_f32
        end
      end
      values
    end

    def callout=(values : Array(Float32)) : Array(Float32)
      array = Cos::Array.new
      values.each do |value|
        array.add(Cos::Float.new(value.to_f64))
      end
      @dictionary[Cos::Name.new("CL")] = array
      values
    end

    def rotation : Int32
      @dictionary.get_int(Cos::Name.new("Rotate"), 0_i64).to_i32
    end

    def rotation=(value : Int32) : Int32
      @dictionary.set_int(Cos::Name.new("Rotate"), value)
      value
    end

    def line_ending_style : String?
      @dictionary.get_name_as_string(Cos::Name.new("LE"))
    end

    def line_ending_style=(value : String) : String
      @dictionary.set_name(Cos::Name.new("LE"), value)
      value
    end

    def justification=(justification : String?) : Nil
      quadding = 0
      if justification == "centered"
        quadding = 1
      elsif justification == "right"
        quadding = 2
      end
      @dictionary.set_int(Cos::Name.new("Q"), quadding)
    end
  end

  class FDFAnnotationFileAttachment < FDFAnnotation
    SUBTYPE = "FileAttachment"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
    end
  end

  class FDFAnnotationHighlight < FDFAnnotationTextMarkup
    SUBTYPE = "Highlight"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super(element)
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end
  end

  class FDFAnnotationInk < FDFAnnotation
    SUBTYPE = "Ink"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      init_ink_list(element)
    end

    # Set the paths making up the freehand "scribble" (Java setInkList). Each
    # entry is an array of alternating x/y coordinates in default user space.
    def ink_list=(ink_list : Enumerable(Array(Float64))) : Nil
      outer = Cos::Array.new
      ink_list.each do |path|
        inner = Cos::Array.new
        path.each { |value| inner.add(Cos::Float.new(value)) }
        outer.add(inner)
      end
      @dictionary.set_item(Cos::Name.new("InkList"), outer)
    end

    # Get the paths making up the freehand "scribble" (Java getInkList).
    def ink_list : Array(Array(Float64))?
      array = @dictionary.get_array(Cos::Name.new("InkList"))
      return unless array
      array.items.map do |entry|
        value = entry.is_a?(Cos::Object) ? entry.object : entry
        value.as(Cos::Array).to_float_array
      end
    end

    private def init_ink_list(element : XML::Node) : Nil
      inklist_node = self.class.first_element_child(element, "inklist")
      gestures = inklist_node.try(&.children.select { |child| child.element? && child.name == "gesture" })
      if gestures.nil? || gestures.empty?
        raise ::IO::Error.new("Error: missing element 'gesture'")
      end
      self.ink_list = gestures.map { |gesture| parse_float_tokens(gesture.content) }
    end
  end

  class FDFAnnotationLine < FDFAnnotation
    SUBTYPE = "Line"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)

      start_coords = self.class.attr_value(element, "start")
      if start_coords.nil?
        raise ::IO::Error.new("Error: missing attribute 'start'")
      end
      end_coords = self.class.attr_value(element, "end")
      if end_coords.nil?
        raise ::IO::Error.new("Error: missing attribute 'end'")
      end
      self.line = parse_rectangle_attributes("#{start_coords},#{end_coords}",
        "Error: wrong amount of line coordinates")

      if leader_length = self.class.attr_value(element, "leaderLength")
        self.leader_length = leader_length.to_f64
      end
      if leader_extend = self.class.attr_value(element, "leaderExtend")
        self.leader_extend = leader_extend.to_f64
      end
      if leader_offset = self.class.attr_value(element, "leaderOffset")
        self.leader_offset = leader_offset.to_f64
      end

      apply_ending_styles(element)
      apply_interior_color(element)

      if element["caption"]? == "yes"
        self.caption = true
        if caption_h = self.class.attr_value(element, "caption-offset-h")
          self.caption_horizontal_offset = caption_h.to_f64
        end
        if caption_v = self.class.attr_value(element, "caption-offset-v")
          self.caption_vertical_offset = caption_v.to_f64
        end
        if caption_style = self.class.attr_value(element, "caption-style")
          self.caption_style = caption_style
        end
      end
    end

    # Set/get the start and end coordinates of the line (Java setLine/getLine).
    def line=(line : Enumerable(Float64)) : Nil
      array = Cos::Array.new
      line.each { |value| array.add(Cos::Float.new(value)) }
      @dictionary.set_item(Cos::Name.new("L"), array)
    end

    def line : Array(Float64)?
      @dictionary.get_array(Cos::Name.new("L")).try(&.to_float_array)
    end

    # Whether the contents are shown as a caption (Java getCaption/setCaption).
    def caption? : Bool
      @dictionary.get_dictionary_object(Cos::Name.new("Cap")).as?(Cos::Boolean).try(&.value) || false
    end

    def caption=(caption : Bool) : Bool
      @dictionary.set_boolean(Cos::Name.new("Cap"), caption)
      caption
    end

    # Leader line length / extension / offset (Java get/setLeaderLength/Extend/Offset).
    def leader_length : Float64
      @dictionary.get_float(Cos::Name.new("LL"), 0.0_f64)
    end

    def leader_length=(value : Float64) : Float64
      @dictionary.set_float(Cos::Name.new("LL"), value)
      value
    end

    def leader_extend : Float64
      @dictionary.get_float(Cos::Name.new("LLE"), 0.0_f64)
    end

    def leader_extend=(value : Float64) : Float64
      @dictionary.set_float(Cos::Name.new("LLE"), value)
      value
    end

    def leader_offset : Float64
      @dictionary.get_float(Cos::Name.new("LLO"), 0.0_f64)
    end

    def leader_offset=(value : Float64) : Float64
      @dictionary.set_float(Cos::Name.new("LLO"), value)
      value
    end

    # Caption positioning ("Inline"/"Top") (Java get/setCaptionStyle).
    def caption_style : String?
      @dictionary.get_string(Cos::Name.new("CP"))
    end

    def caption_style=(value : String?) : String?
      key = Cos::Name.new("CP")
      if value
        @dictionary.set_string(key, value)
      else
        @dictionary.delete(key)
      end
      value
    end

    # Caption horizontal offset (/CO[0]) (Java get/setCaptionHorizontalOffset).
    def caption_horizontal_offset : Float64
      array = @dictionary.get_array(Cos::Name.new("CO"))
      return 0.0_f64 unless array
      array.to_float_array[0]? || 0.0_f64
    end

    def caption_horizontal_offset=(offset : Float64) : Float64
      key = Cos::Name.new("CO")
      array = @dictionary.get_array(key)
      if array
        array[0] = Cos::Float.new(offset)
      else
        array = Cos::Array.new
        array.add(Cos::Float.new(offset))
        array.add(Cos::Float.new(0.0))
        @dictionary.set_item(key, array)
      end
      offset
    end

    # Caption vertical offset (/CO[1]) (Java get/setCaptionVerticalOffset).
    def caption_vertical_offset : Float64
      array = @dictionary.get_array(Cos::Name.new("CO"))
      return 0.0_f64 unless array
      array.to_float_array[1]? || 0.0_f64
    end

    def caption_vertical_offset=(offset : Float64) : Float64
      key = Cos::Name.new("CO")
      array = @dictionary.get_array(key)
      if array
        array[1] = Cos::Float.new(offset)
      else
        array = Cos::Array.new
        array.add(Cos::Float.new(0.0))
        array.add(Cos::Float.new(offset))
        @dictionary.set_item(key, array)
      end
      offset
    end
  end

  class FDFAnnotationLink < FDFAnnotation
    SUBTYPE = "Link"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
    end
  end

  class FDFAnnotationCircle < FDFAnnotation
    SUBTYPE = "Circle"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      apply_interior_color(element)
      init_fringe(element)
    end
  end

  class FDFAnnotationSquare < FDFAnnotation
    SUBTYPE = "Square"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      apply_interior_color(element)
      init_fringe(element)
    end
  end

  class FDFAnnotationPolygon < FDFAnnotation
    SUBTYPE = "Polygon"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      init_vertices(element)
      apply_interior_color(element)
    end

    # Set the coordinates of the vertices (Java setVertices).
    def vertices=(vertices : Enumerable(Float64)) : Nil
      array = Cos::Array.new
      vertices.each { |value| array.add(Cos::Float.new(value)) }
      @dictionary.set_item(Cos::Name.new("Vertices"), array)
    end

    # Get the coordinates of the vertices (Java getVertices).
    def vertices : Array(Float64)?
      @dictionary.get_array(Cos::Name.new("Vertices")).try(&.to_float_array)
    end

    private def init_vertices(element : XML::Node) : Nil
      vertices_node = self.class.first_element_child(element, "vertices")
      text = vertices_node.try(&.content)
      if text.nil? || text.empty?
        raise ::IO::Error.new("Error: missing element 'vertices'")
      end
      self.vertices = parse_float_tokens(text)
    end
  end

  class FDFAnnotationPolyline < FDFAnnotation
    SUBTYPE = "Polyline"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
      init_vertices(element)
      apply_ending_styles(element)
      apply_interior_color(element)
    end

    # Set the coordinates of the vertices (Java setVertices).
    def vertices=(vertices : Enumerable(Float64)) : Nil
      array = Cos::Array.new
      vertices.each { |value| array.add(Cos::Float.new(value)) }
      @dictionary.set_item(Cos::Name.new("Vertices"), array)
    end

    # Get the coordinates of the vertices (Java getVertices).
    def vertices : Array(Float64)?
      @dictionary.get_array(Cos::Name.new("Vertices")).try(&.to_float_array)
    end

    private def init_vertices(element : XML::Node) : Nil
      vertices_node = self.class.first_element_child(element, "vertices")
      text = vertices_node.try(&.content)
      if text.nil? || text.empty?
        raise ::IO::Error.new("Error: missing element 'vertices'")
      end
      self.vertices = parse_float_tokens(text)
    end
  end

  class FDFAnnotationSound < FDFAnnotation
    SUBTYPE = "Sound"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
    end
  end

  class FDFAnnotationSquiggly < FDFAnnotationTextMarkup
    SUBTYPE = "Squiggly"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super(element)
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end
  end

  class FDFAnnotationStamp < FDFAnnotation
    SUBTYPE = "Stamp"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super()
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
      init_from_element(element)
    end
  end

  class FDFAnnotationStrikeOut < FDFAnnotationTextMarkup
    SUBTYPE = "StrikeOut"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super(element)
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end
  end

  class FDFAnnotationUnderline < FDFAnnotationTextMarkup
    SUBTYPE = "Underline"

    def initialize
      super
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end

    def initialize(cos_dict : Cos::Dictionary)
      super(cos_dict)
    end

    def initialize(element : XML::Node)
      super(element)
      @dictionary.set_name(Cos::Name::SUBTYPE, SUBTYPE)
    end
  end
end
