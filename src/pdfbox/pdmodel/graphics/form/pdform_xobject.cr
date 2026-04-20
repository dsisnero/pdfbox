module Pdfbox::Pdmodel::Graphics::Form
  class PDFormXObject
    include Pdfbox::Pdmodel::Common::COSObjectable

    @stream : Pdfbox::Cos::Stream
    @cache : Pdfbox::Pdmodel::ResourceCache?

    def initialize(@stream : Pdfbox::Cos::Stream, @cache : Pdfbox::Pdmodel::ResourceCache? = nil)
      @stream.set_name(Pdfbox::Cos::Name::TYPE, "XObject")
      @stream.set_name(Pdfbox::Cos::Name::SUBTYPE, "Form")
    end

    def initialize(document : Pdfbox::Pdmodel::Document)
      initialize(Pdfbox::Cos::Stream.new)
    end

    def cos_object : Pdfbox::Cos::Base
      @stream
    end

    def form_type : Int32
      @stream.get_int(Pdfbox::Cos::Name.new("FormType"), 1_i64).to_i32
    end

    def form_type=(value : Int) : Int32
      int_value = value.to_i32
      @stream.set_int(Pdfbox::Cos::Name.new("FormType"), int_value)
      int_value
    end

    def group : PDTransparencyGroupAttributes?
      @stream.get_dictionary(Pdfbox::Cos::Name.new("Group")).try do |dictionary|
        PDTransparencyGroupAttributes.new(dictionary)
      end
    end

    def group=(value : PDTransparencyGroupAttributes) : PDTransparencyGroupAttributes
      @stream[Pdfbox::Cos::Name.new("Group")] = value.cos_object
      value
    end

    def content_stream : Pdfbox::Pdmodel::Common::PDStream
      Pdfbox::Pdmodel::Common::PDStream.new(@stream)
    end

    def resources : Pdfbox::Pdmodel::PDResources?
      @stream.get_dictionary(Pdfbox::Cos::Name.new("Resources")).try do |dictionary|
        Pdfbox::Pdmodel::PDResources.new(dictionary, @cache)
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

    def matrix : Pdfbox::Util::Matrix
      base = @stream[Pdfbox::Cos::Name.new("Matrix")]?
      return Pdfbox::Util::Matrix.new unless base

      Pdfbox::Util::Matrix.create_matrix(base)
    end

    def matrix=(value : Pdfbox::Util::Matrix) : Pdfbox::Util::Matrix
      array = Pdfbox::Cos::Array.new
      array.add(Pdfbox::Cos::Float.new(value.get_value(0, 0)))
      array.add(Pdfbox::Cos::Float.new(value.get_value(0, 1)))
      array.add(Pdfbox::Cos::Float.new(value.get_value(1, 0)))
      array.add(Pdfbox::Cos::Float.new(value.get_value(1, 1)))
      array.add(Pdfbox::Cos::Float.new(value.get_value(2, 0)))
      array.add(Pdfbox::Cos::Float.new(value.get_value(2, 1)))
      @stream[Pdfbox::Cos::Name.new("Matrix")] = array
      value
    end
  end
end
