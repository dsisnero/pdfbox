# Options that may be passed to a Filter to request special handling when
# decoding a stream. Filters may not honor some or all of the specified options;
# callers should check the honored flag if further processing relies on them.
# Java: org.apache.pdfbox.filter.DecodeOptions

module Pdfbox::Filter
  class DecodeOptions
    # Default decode options. The honored flag for this instance is always true.
    DEFAULT = FinalDecodeOptions.new(true)

    @source_region : Pdfbox::Pdmodel::Rectangle?
    @subsampling_x : Int32
    @subsampling_y : Int32
    @subsampling_offset_x : Int32
    @subsampling_offset_y : Int32
    @filter_subsampled : Bool

    def initialize
      @source_region = nil
      @subsampling_x = 1
      @subsampling_y = 1
      @subsampling_offset_x = 0
      @subsampling_offset_y = 0
      @filter_subsampled = false
    end

    def initialize(source_region : Pdfbox::Pdmodel::Rectangle)
      initialize
      @source_region = source_region
    end

    def initialize(x : Int32, y : Int32, width : Int32, height : Int32)
      initialize(Pdfbox::Pdmodel::Rectangle.new(x.to_f64, y.to_f64, (x + width).to_f64, (y + height).to_f64))
    end

    def initialize(subsampling : Int32)
      initialize
      @subsampling_x = subsampling
      @subsampling_y = subsampling
    end

    # The part of the image that should be decoded, or nil if the entire image
    # is needed.
    def source_region : Pdfbox::Pdmodel::Rectangle?
      @source_region
    end

    def source_region=(source_region : Pdfbox::Pdmodel::Rectangle?)
      @source_region = source_region
    end

    # The number of columns to advance in the source for every pixel decoded.
    def subsampling_x : Int32
      @subsampling_x
    end

    def subsampling_x=(ss_x : Int32)
      @subsampling_x = ss_x
    end

    # The number of rows to advance in the source for every pixel decoded.
    def subsampling_y : Int32
      @subsampling_y
    end

    def subsampling_y=(ss_y : Int32)
      @subsampling_y = ss_y
    end

    # The horizontal offset for subsampling.
    def subsampling_offset_x : Int32
      @subsampling_offset_x
    end

    def subsampling_offset_x=(ss_offset_x : Int32)
      @subsampling_offset_x = ss_offset_x
    end

    # The vertical offset for subsampling.
    def subsampling_offset_y : Int32
      @subsampling_offset_y
    end

    def subsampling_offset_y=(ss_offset_y : Int32)
      @subsampling_offset_y = ss_offset_y
    end

    # True if the filter applied the options specified by this instance.
    def filter_subsampled? : Bool
      @filter_subsampled
    end

    # Used internally by filters to signal they have applied subsampling as
    # requested by this options instance.
    def filter_subsampled=(filter_subsampled : Bool)
      @filter_subsampled = filter_subsampled
    end
  end

  # Helper class for reusable instances which may not be modified.
  class FinalDecodeOptions < DecodeOptions
    def initialize(filter_subsampled : Bool)
      super()
      @filter_subsampled = filter_subsampled
    end

    def source_region=(source_region : Pdfbox::Pdmodel::Rectangle?)
      raise Pdfbox::Cos::UnsupportedOperationError.new("This instance may not be modified.")
    end

    def subsampling_x=(ss_x : Int32)
      raise Pdfbox::Cos::UnsupportedOperationError.new("This instance may not be modified.")
    end

    def subsampling_y=(ss_y : Int32)
      raise Pdfbox::Cos::UnsupportedOperationError.new("This instance may not be modified.")
    end

    def subsampling_offset_x=(ss_offset_x : Int32)
      raise Pdfbox::Cos::UnsupportedOperationError.new("This instance may not be modified.")
    end

    def subsampling_offset_y=(ss_offset_y : Int32)
      raise Pdfbox::Cos::UnsupportedOperationError.new("This instance may not be modified.")
    end

    def filter_subsampled=(filter_subsampled : Bool)
      # Silently ignore the request.
    end
  end
end
