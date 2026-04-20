# Base class for PDF annotations
module Pdfbox::Pdmodel::Interactive::Annotation
  class PDAnnotation
    FLAG_INVISIBLE       = 1 << 0
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

    def self.create_annotation(base : Cos::Base) : PDAnnotation
      dictionary = dereference(base).as?(Cos::Dictionary)
      raise ::IO::Error.new("Error: Unknown annotation type #{base}") unless dictionary

      annotation_from_subtype(dictionary.get_name_as_string(Cos::Name::SUBTYPE), dictionary)
    end

    def initialize(@dictionary : Cos::Dictionary = Cos::Dictionary.new)
      type = @dictionary[Cos::Name::TYPE]?
      if type.nil?
        @dictionary[Cos::Name::TYPE] = Cos::Name.new("Annot")
      end
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    def ==(other : self) : Bool
      cos_object == other.cos_object
    end

    def ==(other) : Bool
      other.is_a?(PDAnnotation) && cos_object == other.cos_object
    end

    def_hash @dictionary

    protected def subtype=(value : String) : String
      @dictionary.set_name(Cos::Name::SUBTYPE, value)
      value
    end

    def subtype : String?
      @dictionary.get_name_as_string(Cos::Name::SUBTYPE)
    end

    def rectangle : Common::PDRectangle?
      rect_array = @dictionary.get_array(Cos::Name.new("Rect"))
      return unless rect_array
      return unless rect_array.size == 4
      return unless rect_array.items.all? { |item| item.is_a?(Cos::Integer) || item.is_a?(Cos::Float) }

      Common::PDRectangle.new(rect_array)
    end

    def rectangle=(rect : Common::PDRectangle) : Common::PDRectangle
      @dictionary[Cos::Name.new("Rect")] = rect.cos_object
      rect
    end

    def annotation_flags : Int32
      @dictionary.get_int(Cos::Name.new("F"), 0_i64).to_i32
    end

    def annotation_flags=(value : Int) : Int32
      int_value = value.to_i32
      @dictionary.set_int(Cos::Name.new("F"), int_value)
      int_value
    end

    def flags : Int32
      annotation_flags
    end

    def flags=(value : Int32) : Int32
      self.annotation_flags = value
    end

    def appearance_state : Cos::Name?
      dereference(@dictionary[Cos::Name.new("AS")]?).as?(Cos::Name)
    end

    def appearance_state=(value : String) : String
      @dictionary.set_name(Cos::Name.new("AS"), value)
      value
    end

    def appearance : PDAppearanceDictionary?
      @dictionary.get_dictionary(Cos::Name.new("AP")).try { |entry| PDAppearanceDictionary.new(entry) }
    end

    def appearance=(value : PDAppearanceDictionary) : PDAppearanceDictionary
      @dictionary[Cos::Name.new("AP")] = value.cos_object
      value
    end

    def normal_appearance_stream : PDAppearanceStream?
      appearance_dict = appearance
      return unless appearance_dict

      normal = appearance_dict.normal_appearance
      return unless normal

      if normal.sub_dictionary?
        normal.sub_dictionary[appearance_state || Cos::Name.new("Off")]?
      else
        normal.appearance_stream
      end
    end

    def invisible? : Bool
      flag_set?(FLAG_INVISIBLE)
    end

    def invisible=(value : Bool) : Bool
      set_flag(FLAG_INVISIBLE, value)
    end

    def hidden? : Bool
      flag_set?(FLAG_HIDDEN)
    end

    def hidden=(value : Bool) : Bool
      set_flag(FLAG_HIDDEN, value)
    end

    def printed? : Bool
      flag_set?(FLAG_PRINTED)
    end

    def printed=(value : Bool) : Bool
      set_flag(FLAG_PRINTED, value)
    end

    def no_zoom? : Bool
      flag_set?(FLAG_NO_ZOOM)
    end

    def no_zoom=(value : Bool) : Bool
      set_flag(FLAG_NO_ZOOM, value)
    end

    def no_rotate? : Bool
      flag_set?(FLAG_NO_ROTATE)
    end

    def no_rotate=(value : Bool) : Bool
      set_flag(FLAG_NO_ROTATE, value)
    end

    def no_view? : Bool
      flag_set?(FLAG_NO_VIEW)
    end

    def no_view=(value : Bool) : Bool
      set_flag(FLAG_NO_VIEW, value)
    end

    def read_only? : Bool
      flag_set?(FLAG_READ_ONLY)
    end

    def read_only=(value : Bool) : Bool
      set_flag(FLAG_READ_ONLY, value)
    end

    def locked? : Bool
      flag_set?(FLAG_LOCKED)
    end

    def locked=(value : Bool) : Bool
      set_flag(FLAG_LOCKED, value)
    end

    def toggle_no_view? : Bool
      flag_set?(FLAG_TOGGLE_NO_VIEW)
    end

    def toggle_no_view=(value : Bool) : Bool
      set_flag(FLAG_TOGGLE_NO_VIEW, value)
    end

    def locked_contents? : Bool
      flag_set?(FLAG_LOCKED_CONTENTS)
    end

    def locked_contents=(value : Bool) : Bool
      set_flag(FLAG_LOCKED_CONTENTS, value)
    end

    def contents : String?
      @dictionary.get_string(Cos::Name.new("Contents"))
    end

    def contents=(value : String) : String
      @dictionary.set_string(Cos::Name.new("Contents"), value)
      value
    end

    def modified_date : String?
      @dictionary.get_string(Cos::Name.new("M"))
    end

    def modified_date=(value : String) : String
      @dictionary.set_string(Cos::Name.new("M"), value)
      value
    end

    def annotation_name : String?
      @dictionary.get_string(Cos::Name.new("NM"))
    end

    def annotation_name=(value : String) : String
      @dictionary.set_string(Cos::Name.new("NM"), value)
      value
    end

    def struct_parent : Int32
      @dictionary.get_int(Cos::Name.new("StructParent"), 0_i64).to_i32
    end

    def struct_parent=(value : Int) : Int32
      int_value = value.to_i32
      @dictionary.set_int(Cos::Name.new("StructParent"), int_value)
      int_value
    end

    def optional_content : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList?
      @dictionary.get_dictionary(Cos::Name.new("OC")).try do |entry|
        Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.create(entry)
      end
    end

    def optional_content=(value : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList) : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
      @dictionary[Cos::Name.new("OC")] = value.cos_object
      value
    end

    def border : Cos::Array
      current = @dictionary.get_array(Cos::Name.new("Border"))
      if current
        if current.size < 3
          copy = Cos::Array.new(current.items.dup)
          while copy.size < 3
            copy.add(Cos::Integer.new(0))
          end
          copy
        else
          current
        end
      else
        Cos::Array.new([Cos::Integer.new(0), Cos::Integer.new(0), Cos::Integer.new(1)])
      end
    end

    def border=(value : Cos::Array) : Cos::Array
      @dictionary[Cos::Name.new("Border")] = value
      value
    end

    def color=(value : Pdfbox::Pdmodel::Graphics::Color::PDColor) : Pdfbox::Pdmodel::Graphics::Color::PDColor
      @dictionary[Cos::Name.new("C")] = value.to_cos_array
      value
    end

    def color : Pdfbox::Pdmodel::Graphics::Color::PDColor?
      color_for(Cos::Name.new("C"))
    end

    def page : Pdfbox::Pdmodel::Page?
      @dictionary.get_dictionary(Cos::Name.new("P")).try { |entry| Pdfbox::Pdmodel::Page.new(entry) }
    end

    def page=(value : Pdfbox::Pdmodel::Page) : Pdfbox::Pdmodel::Page
      page_dictionary = value.cos_object || raise ArgumentError.new("page must have a COS dictionary")
      @dictionary[Cos::Name.new("P")] = page_dictionary
      value
    end

    def construct_appearances(_document : Pdfbox::Pdmodel::Document? = nil) : Nil
    end

    private def self.dereference(base : Cos::Base?) : Cos::Base?
      case base
      when Cos::Object
        base.object
      else
        base
      end
    end

    private def self.annotation_from_subtype(subtype : String?, dictionary : Cos::Dictionary) : PDAnnotation
      direct_annotation_for(subtype, dictionary) ||
        markup_annotation_for(subtype, dictionary) ||
        geometric_annotation_for(subtype, dictionary) ||
        PDAnnotationUnknown.new(dictionary)
    end

    private def self.direct_annotation_for(subtype : String?, dictionary : Cos::Dictionary) : PDAnnotation?
      case subtype
      when PDAnnotationFileAttachment::SUB_TYPE then PDAnnotationFileAttachment.new(dictionary)
      when PDAnnotationLine::SUB_TYPE           then PDAnnotationLine.new(dictionary)
      when PDAnnotationLink::SUB_TYPE           then PDAnnotationLink.new(dictionary)
      when PDAnnotationPopup::SUB_TYPE          then PDAnnotationPopup.new(dictionary)
      when PDAnnotationWidget::SUB_TYPE         then PDAnnotationWidget.new(dictionary)
      when PDAnnotationFreeText::SUB_TYPE       then PDAnnotationFreeText.new(dictionary)
      when PDAnnotationCaret::SUB_TYPE          then PDAnnotationCaret.new(dictionary)
      when PDAnnotationSound::SUB_TYPE          then PDAnnotationSound.new(dictionary)
      end
    end

    private def self.markup_annotation_for(subtype : String?, dictionary : Cos::Dictionary) : PDAnnotation?
      case subtype
      when PDAnnotationRubberStamp::SUB_TYPE then PDAnnotationRubberStamp.new(dictionary)
      when PDAnnotationPolygon::SUB_TYPE     then PDAnnotationPolygon.new(dictionary)
      when PDAnnotationPolyline::SUB_TYPE    then PDAnnotationPolyline.new(dictionary)
      when PDAnnotationInk::SUB_TYPE         then PDAnnotationInk.new(dictionary)
      when PDAnnotationText::SUB_TYPE        then PDAnnotationText.new(dictionary)
      when PDAnnotationHighlight::SUB_TYPE   then PDAnnotationHighlight.new(dictionary)
      when PDAnnotationUnderline::SUB_TYPE   then PDAnnotationUnderline.new(dictionary)
      when PDAnnotationStrikeout::SUB_TYPE   then PDAnnotationStrikeout.new(dictionary)
      when PDAnnotationSquiggly::SUB_TYPE    then PDAnnotationSquiggly.new(dictionary)
      end
    end

    private def self.geometric_annotation_for(subtype : String?, dictionary : Cos::Dictionary) : PDAnnotation?
      case subtype
      when PDAnnotationCircle::SUB_TYPE then PDAnnotationCircle.new(dictionary)
      when PDAnnotationSquare::SUB_TYPE then PDAnnotationSquare.new(dictionary)
      end
    end

    private def dereference(base : Cos::Base?) : Cos::Base?
      case base
      when Cos::Object
        base.object
      else
        base
      end
    end

    private def flag_set?(flag : Int32) : Bool
      (annotation_flags & flag) != 0
    end

    private def set_flag(flag : Int32, value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("F"), flag, value)
      value
    end

    protected def color_for(name : Cos::Name) : Pdfbox::Pdmodel::Graphics::Color::PDColor?
      color_array = @dictionary.get_array(name)
      return unless color_array

      color_space = case color_array.size
                    when 1
                      Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
                    when 3
                      Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
                    when 4
                      Pdfbox::Pdmodel::Graphics::Color::PDDeviceCMYK::INSTANCE
                    else
                      nil
                    end
      return unless color_space

      Pdfbox::Pdmodel::Graphics::Color::PDColor.new(color_array, color_space)
    end

    protected def boolean_value(name : Cos::Name, default : Bool) : Bool
      cos_object[name]?.as?(Cos::Boolean).try(&.value) || default
    end

    protected def cos_array_of_numbers(values : Enumerable(Number)) : Cos::Array
      array = Cos::Array.new
      values.each do |value|
        array.add(Cos::Float.new(value.to_f64))
      end
      array
    end
  end
end
