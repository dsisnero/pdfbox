module Pdfbox::Pdmodel::Graphics::Pattern
  class PDTilingPattern
    include Pdfbox::Pdmodel::Common::COSObjectable

    PAINT_COLORED                         = 1
    PAINT_UNCOLORED                       = 2
    TILING_CONSTANT_SPACING               = 1
    TILING_NO_DISTORTION                  = 2
    TILING_CONSTANT_SPACING_FASTER_TILING = 3

    @stream : Pdfbox::Cos::Stream
    @resource_cache : Pdfbox::Pdmodel::ResourceCache?

    def initialize
      @stream = Pdfbox::Cos::Stream.new
      @resource_cache = nil
      @stream.set_name(Pdfbox::Cos::Name::TYPE, "Pattern")
      @stream.set_int(Pdfbox::Cos::Name.new("PatternType"), 1)
      self.resources = Pdfbox::Pdmodel::PDResources.new
    end

    def initialize(@stream : Pdfbox::Cos::Stream, @resource_cache : Pdfbox::Pdmodel::ResourceCache? = nil)
    end

    def cos_object : Pdfbox::Cos::Base
      @stream
    end

    def pattern_type : Int32
      @stream.get_int(Pdfbox::Cos::Name.new("PatternType"), 1_i64).to_i32
    end

    def paint_type : Int32
      @stream.get_int(Pdfbox::Cos::Name.new("PaintType"), 0_i64).to_i32
    end

    def paint_type=(value : Int) : Int32
      int_value = value.to_i32
      @stream.set_int(Pdfbox::Cos::Name.new("PaintType"), int_value)
      int_value
    end

    def tiling_type : Int32
      @stream.get_int(Pdfbox::Cos::Name.new("TilingType"), 0_i64).to_i32
    end

    def tiling_type=(value : Int) : Int32
      int_value = value.to_i32
      @stream.set_int(Pdfbox::Cos::Name.new("TilingType"), int_value)
      int_value
    end

    def x_step : Float64
      @stream.get_float(Pdfbox::Cos::Name.new("XStep"), 0.0_f64)
    end

    def x_step=(value : Number) : Float64
      float_value = value.to_f64
      @stream.set_float(Pdfbox::Cos::Name.new("XStep"), float_value)
      float_value
    end

    def y_step : Float64
      @stream.get_float(Pdfbox::Cos::Name.new("YStep"), 0.0_f64)
    end

    def y_step=(value : Number) : Float64
      float_value = value.to_f64
      @stream.set_float(Pdfbox::Cos::Name.new("YStep"), float_value)
      float_value
    end

    def content_stream : Pdfbox::Pdmodel::Common::PDStream
      Pdfbox::Pdmodel::Common::PDStream.new(@stream)
    end

    def resources : Pdfbox::Pdmodel::PDResources?
      @stream.get_dictionary(Pdfbox::Cos::Name.new("Resources")).try do |dictionary|
        Pdfbox::Pdmodel::PDResources.new(dictionary, @resource_cache)
      end
    end

    def resources=(value : Pdfbox::Pdmodel::PDResources) : Pdfbox::Pdmodel::PDResources
      @stream[Pdfbox::Cos::Name.new("Resources")] = value.cos_object
      value
    end

    def bbox : Pdfbox::Pdmodel::Common::PDRectangle?
      @stream.get_array(Pdfbox::Cos::Name.new("BBox")).try do |array|
        Pdfbox::Pdmodel::Common::PDRectangle.new(array)
      end
    end

    def bbox=(value : Pdfbox::Pdmodel::Common::PDRectangle?) : Pdfbox::Pdmodel::Common::PDRectangle?
      if value
        @stream[Pdfbox::Cos::Name.new("BBox")] = value.cos_object
      else
        @stream.delete(Pdfbox::Cos::Name.new("BBox"))
      end
      value
    end
  end
end
