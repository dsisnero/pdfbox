# ICCBased color spaces are based on a cross-platform color profile as defined
# by the International Color Consortium (ICC). Corresponds to PDICCBased in
# Apache PDFBox.
module Pdfbox::Pdmodel::Graphics::Color
  class PDICCBased < PDColorSpace
    @array : Cos::Array
    @stream : Pdfbox::Pdmodel::Common::PDStream
    @number_of_components : Int32

    # Creates a new ICC color space with an empty stream.
    def initialize(document : Pdfbox::Pdmodel::PDDocument)
      @array = Cos::Array.new
      @array.add(Cos::Name.new("ICCBased"))
      @stream = Pdfbox::Pdmodel::Common::PDStream.new(document)
      @array.add(@stream.cos_object)
      @number_of_components = 3
    end

    # Creates a new ICC color space from a PDF array.
    def initialize(icc_array : Cos::Array)
      @array = icc_array
      stream_base = @array[1]
      stream_base = stream_base.object if stream_base.is_a?(Cos::Object)
      @stream = Pdfbox::Pdmodel::Common::PDStream.new(stream_base.as(Cos::Stream))
      @number_of_components = read_number_of_components
    end

    def name : String
      "ICCBased"
    end

    def pd_stream : Pdfbox::Pdmodel::Common::PDStream
      @stream
    end

    def number_of_components : Int32
      @number_of_components
    end

    def cos_object : Cos::Base
      @array
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # Full ICC profile conversion is not implemented; components are passed
      # through as RGB.
      components
    end

    private def read_number_of_components : Int32
      n_value = @stream.cos_object[Cos::Name.new("N")]
      n_value = n_value.object if n_value.is_a?(Cos::Object)
      case n_value
      when Cos::Integer
        n_value.value.to_i32
      when Cos::Float
        n_value.value.to_i32
      else
        3
      end
    end
  end
end
