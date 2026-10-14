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
      if fringe = FDFAnnotation.attr_value(element, "fringe")
        self.fringe = parse_rectangle(fringe, "Error: wrong amount of numbers in attribute 'fringe'")
      end
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

    def fringe : Common::PDRectangle?
      array = @dictionary.get_array(Cos::Name.new("RD"))
      array ? Common::PDRectangle.new(array) : nil
    end

    def fringe=(value : Common::PDRectangle) : Common::PDRectangle
      @dictionary[Cos::Name.new("RD")] = value.cos_object
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
