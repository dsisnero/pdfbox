module Pdfbox::Printing
  enum Orientation
    AUTO
    LANDSCAPE
    REVERSE_LANDSCAPE
    PORTRAIT

    def self.parse(value : String) : self
      parse?(value.upcase) || raise ArgumentError.new("Unknown orientation: #{value}")
    end
  end

  enum Scaling
    ACTUAL_SIZE
    SHRINK_TO_FIT
    STRETCH_TO_FIT
    SCALE_TO_FIT
  end

  class Paper
    property width : Float64
    property height : Float64
    property imageable_x : Float64
    property imageable_y : Float64
    property imageable_width : Float64
    property imageable_height : Float64

    def initialize(@width : Float64 = 0.0, @height : Float64 = 0.0, @imageable_x : Float64 = 0.0,
                   @imageable_y : Float64 = 0.0, @imageable_width : Float64 = 0.0, @imageable_height : Float64 = 0.0)
    end
  end

  class PageFormat
    property paper : Paper
    property orientation : Orientation

    def initialize(@paper : Paper = Paper.new, @orientation : Orientation = Orientation::PORTRAIT)
    end
  end

  class PDFPrintable
    PAGE_EXISTS        =      0
    NO_SUCH_PAGE       =      1
    RASTERIZE_OFF      =  0_f32
    RASTERIZE_DPI_AUTO = -1_f32

    getter document : Pdfbox::Pdmodel::Document
    getter scaling : Scaling
    getter show_page_border : Bool # ameba:disable Naming/QueryBoolMethods
    getter dpi : Float32
    getter center : Bool                        # ameba:disable Naming/QueryBoolMethods
    property subsampling_allowed : Bool = false # ameba:disable Naming/QueryBoolMethods
    property rendering_hints : Hash(String, String)?

    def initialize(@document : Pdfbox::Pdmodel::Document,
                   @scaling : Scaling = Scaling::SHRINK_TO_FIT,
                   @show_page_border : Bool = false,
                   @dpi : Float32 = RASTERIZE_OFF,
                   @center : Bool = true)
    end

    def get_rendering_hints : Hash(String, String)? # ameba:disable Naming/AccessorMethodName
      @rendering_hints
    end

    def set_rendering_hints(rendering_hints : Hash(String, String)?) : Nil # ameba:disable Naming/AccessorMethodName
      @rendering_hints = rendering_hints
    end

    def is_subsampling_allowed : Bool # ameba:disable Naming/PredicateName
      @subsampling_allowed
    end

    def set_subsampling_allowed(subsampling_allowed : Bool) : Nil # ameba:disable Naming/AccessorMethodName
      @subsampling_allowed = subsampling_allowed
    end

    def print(page_index : Int32, page_format : PageFormat? = nil) : Int32
      _ = page_format
      return NO_SUCH_PAGE if page_index < 0 || page_index >= @document.page_count
      raise Pdfbox::UnsupportedFeatureError.new("PDFPrintable rendering is not yet implemented in this Crystal port.")
    end

    def self.get_rotated_media_box(page : Pdfbox::Pdmodel::Page) : Pdfbox::Pdmodel::Rectangle
      rotate_box(page.media_box || Pdfbox::Pdmodel::PageSizes::LETTER, page.rotation)
    end

    def self.get_rotated_crop_box(page : Pdfbox::Pdmodel::Page) : Pdfbox::Pdmodel::Rectangle
      rotate_box(page.crop_box || page.media_box || Pdfbox::Pdmodel::PageSizes::LETTER, page.rotation)
    end

    private def self.rotate_box(box : Pdfbox::Pdmodel::Rectangle, rotation : Int32) : Pdfbox::Pdmodel::Rectangle
      if rotation == 90 || rotation == 270
        Pdfbox::Pdmodel::Rectangle.new(
          box.lower_left_y,
          box.lower_left_x,
          box.lower_left_y + box.height,
          box.lower_left_x + box.width
        )
      else
        box
      end
    end
  end

  class PDFPageable
    getter document : Pdfbox::Pdmodel::Document
    getter number_of_pages : Int32
    getter show_page_border : Bool # ameba:disable Naming/QueryBoolMethods
    getter dpi : Float32
    getter center : Bool # ameba:disable Naming/QueryBoolMethods
    getter orientation : Orientation
    property subsampling_allowed : Bool = false # ameba:disable Naming/QueryBoolMethods
    property rendering_hints : Hash(String, String)?

    def initialize(@document : Pdfbox::Pdmodel::Document,
                   @orientation : Orientation = Orientation::AUTO,
                   @show_page_border : Bool = false,
                   @dpi : Float32 = 0_f32,
                   @center : Bool = true)
      @number_of_pages = @document.page_count
    end

    def get_number_of_pages : Int32 # ameba:disable Naming/AccessorMethodName
      @number_of_pages
    end

    def get_rendering_hints : Hash(String, String)? # ameba:disable Naming/AccessorMethodName
      @rendering_hints
    end

    def set_rendering_hints(rendering_hints : Hash(String, String)?) : Nil # ameba:disable Naming/AccessorMethodName
      @rendering_hints = rendering_hints
    end

    def is_subsampling_allowed : Bool # ameba:disable Naming/PredicateName
      @subsampling_allowed
    end

    def set_subsampling_allowed(subsampling_allowed : Bool) : Nil # ameba:disable Naming/AccessorMethodName
      @subsampling_allowed = subsampling_allowed
    end

    def get_page_format(page_index : Int32) : PageFormat
      page = @document.get_page(page_index)
      media_box = PDFPrintable.get_rotated_media_box(page)
      crop_box = PDFPrintable.get_rotated_crop_box(page)

      if media_box.width > media_box.height
        paper = Paper.new(
          media_box.height,
          media_box.width,
          crop_box.lower_left_y,
          crop_box.lower_left_x,
          crop_box.height,
          crop_box.width
        )
        is_landscape = true
      else
        paper = Paper.new(
          media_box.width,
          media_box.height,
          crop_box.lower_left_x,
          crop_box.lower_left_y,
          crop_box.width,
          crop_box.height
        )
        is_landscape = false
      end

      page_orientation = case @orientation
                         when Orientation::AUTO
                           is_landscape ? Orientation::LANDSCAPE : Orientation::PORTRAIT
                         else
                           @orientation
                         end

      PageFormat.new(paper, page_orientation)
    end

    def get_printable(page_index : Int32) : PDFPrintable
      raise IndexError.new("#{page_index} >= #{@number_of_pages}") if page_index >= @number_of_pages

      printable = PDFPrintable.new(@document, Scaling::ACTUAL_SIZE, @show_page_border, @dpi, @center)
      printable.set_subsampling_allowed(@subsampling_allowed)
      printable.set_rendering_hints(@rendering_hints)
      printable
    end
  end
end
