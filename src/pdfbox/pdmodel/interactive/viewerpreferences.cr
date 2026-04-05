module Pdfbox::Pdmodel::Interactive
  class PDViewerPreferences
    enum NON_FULL_SCREEN_PAGE_MODE # ameba:disable Naming/TypeNames
      UseNone
      UseOutlines
      UseThumbs
      UseOC
    end

    enum READING_DIRECTION # ameba:disable Naming/TypeNames
      L2R
      R2L
    end

    enum BOUNDARY
      MediaBox
      CropBox
      BleedBox
      TrimBox
      ArtBox
    end

    enum DUPLEX
      Simplex
      DuplexFlipShortEdge
      DuplexFlipLongEdge
    end

    enum PRINT_SCALING # ameba:disable Naming/TypeNames
      None
      AppDefault
    end

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize(@dictionary : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def hide_toolbar? : Bool
      boolean_value("HideToolbar")
    end

    def hide_toolbar=(value : Bool) : Bool
      set_boolean("HideToolbar", value)
    end

    def hide_menubar? : Bool
      boolean_value("HideMenubar")
    end

    def hide_menubar=(value : Bool) : Bool
      set_boolean("HideMenubar", value)
    end

    def hide_window_ui? : Bool
      boolean_value("HideWindowUI")
    end

    def hide_window_ui=(value : Bool) : Bool
      set_boolean("HideWindowUI", value)
    end

    def fit_window? : Bool
      boolean_value("FitWindow")
    end

    def fit_window=(value : Bool) : Bool
      set_boolean("FitWindow", value)
    end

    def center_window? : Bool
      boolean_value("CenterWindow")
    end

    def center_window=(value : Bool) : Bool
      set_boolean("CenterWindow", value)
    end

    def display_doc_title? : Bool
      boolean_value("DisplayDocTitle")
    end

    def display_doc_title=(value : Bool) : Bool
      set_boolean("DisplayDocTitle", value)
    end

    def non_full_screen_page_mode : NON_FULL_SCREEN_PAGE_MODE
      enum_value("NonFullScreenPageMode", NON_FULL_SCREEN_PAGE_MODE::UseNone)
    end

    def non_full_screen_page_mode=(value : NON_FULL_SCREEN_PAGE_MODE) : NON_FULL_SCREEN_PAGE_MODE
      set_enum("NonFullScreenPageMode", value)
    end

    def reading_direction : READING_DIRECTION
      enum_value("Direction", READING_DIRECTION::L2R)
    end

    def reading_direction=(value : READING_DIRECTION) : READING_DIRECTION
      set_enum("Direction", value)
    end

    def view_area : BOUNDARY
      enum_value("ViewArea", BOUNDARY::CropBox)
    end

    def view_area=(value : BOUNDARY) : BOUNDARY
      set_enum("ViewArea", value)
    end

    def view_clip : BOUNDARY
      enum_value("ViewClip", BOUNDARY::CropBox)
    end

    def view_clip=(value : BOUNDARY) : BOUNDARY
      set_enum("ViewClip", value)
    end

    def print_area : BOUNDARY
      enum_value("PrintArea", BOUNDARY::CropBox)
    end

    def print_area=(value : BOUNDARY) : BOUNDARY
      set_enum("PrintArea", value)
    end

    def print_clip : BOUNDARY
      enum_value("PrintClip", BOUNDARY::CropBox)
    end

    def print_clip=(value : BOUNDARY) : BOUNDARY
      set_enum("PrintClip", value)
    end

    def duplex : DUPLEX?
      enum_value?("Duplex", DUPLEX)
    end

    def duplex=(value : DUPLEX?) : DUPLEX?
      key = Pdfbox::Cos::Name.new("Duplex")
      if value
        @dictionary.set_name(key, value.to_s)
      else
        @dictionary.delete(key)
      end
      value
    end

    def print_scaling : PRINT_SCALING
      enum_value("PrintScaling", PRINT_SCALING::AppDefault)
    end

    def print_scaling=(value : PRINT_SCALING) : PRINT_SCALING
      set_enum("PrintScaling", value)
    end

    private def boolean_value(key : String) : Bool
      value = @dictionary[Pdfbox::Cos::Name.new(key)]?
      value.is_a?(Pdfbox::Cos::Boolean) ? value.value : false
    end

    private def set_boolean(key : String, value : Bool) : Bool
      @dictionary.set_boolean(Pdfbox::Cos::Name.new(key), value)
      value
    end

    private def enum_value(key : String, default : T) : T forall T
      raw = @dictionary.get_name_as_string(Pdfbox::Cos::Name.new(key))
      return default unless raw
      T.parse?(raw) || default
    end

    private def enum_value?(key : String, enum_type : T.class) : T? forall T
      _ = enum_type
      raw = @dictionary.get_name_as_string(Pdfbox::Cos::Name.new(key))
      raw ? T.parse?(raw) : nil
    end

    private def set_enum(key : String, value : T) : T forall T
      @dictionary.set_name(Pdfbox::Cos::Name.new(key), value.to_s)
      value
    end
  end
end
