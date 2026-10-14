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
      check_array(icc_array)
      @array = icc_array
      stream_base = @array[1]
      stream_base = stream_base.object if stream_base.is_a?(Cos::Object)
      @stream = Pdfbox::Pdmodel::Common::PDStream.new(stream_base.as(Cos::Stream))
      @number_of_components = read_number_of_components
    end

    # Validates the ICCBased color space array (Java PDICCBased#checkArray).
    private def check_array(icc_array : Cos::Array) : Nil
      if icc_array.size < 2
        raise ::IO::Error.new("ICCBased colorspace array must have two elements")
      end
      second = icc_array[1]
      second = second.object if second.is_a?(Cos::Object)
      unless second.is_a?(Cos::Stream)
        raise ::IO::Error.new("ICCBased colorspace array must have a stream as second element")
      end
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

    # Java PDICCBased#getDefaultDecode delegates to the alternate color space
    # (the AWT ICC path is not available in Crystal).
    def default_decode(bits_per_component : Int32) : Array(Float32)
      alternate_color_space.default_decode(bits_per_component)
    end

    # Returns the alternate color space for non-conforming readers.
    # Java PDICCBased#getAlternateColorSpace.
    def alternate_color_space : PDColorSpace
      alternate = @stream.cos_object.get_dictionary_object(Cos::Name.new("Alternate"))
      alternate_array : Cos::Array
      if alternate.nil?
        alternate_array = Cos::Array.new
        case number_of_components
        when 1
          alternate_array.add(Cos::Name.new("DeviceGray"))
        when 3
          alternate_array.add(Cos::Name.new("DeviceRGB"))
        when 4
          alternate_array.add(Cos::Name.new("DeviceCMYK"))
        else
          raise ::IO::Error.new("Unknown color space number of components: #{number_of_components}")
        end
      elsif alternate.is_a?(Cos::Array)
        alternate_array = alternate
      elsif alternate.is_a?(Cos::Name)
        alternate_array = Cos::Array.new
        alternate_array.add(alternate)
      else
        raise ::IO::Error.new("Error: expected COSArray or COSName and not #{alternate.class}")
      end
      PDColorSpace.create(alternate_array) ||
        raise ::IO::Error.new("Error: could not create alternate color space")
    end

    # Sets the list of alternate color spaces. Java PDICCBased#setAlternateColorSpaces.
    def alternate_color_spaces=(list : Enumerable(PDColorSpace)?) : Nil
      key = Cos::Name.new("Alternate")
      if list
        array = Cos::Array.new
        list.each { |color_space| array.add(color_space.cos_object) }
        @stream.cos_object.set_item(key, array)
      else
        @stream.cos_object.delete(key)
      end
    end

    # Returns the range for a component, never nil (defaults to 0..1).
    # Java PDICCBased#getRangeForComponent.
    def range_for_component(n : Int32) : Pdfbox::Pdmodel::Common::PDRange
      range_array = @stream.cos_object.get_dictionary_object(Cos::Name::RANGE).as?(Cos::Array)
      if range_array.nil? || range_array.size < number_of_components * 2
        return Pdfbox::Pdmodel::Common::PDRange.new
      end
      Pdfbox::Pdmodel::Common::PDRange.new(range_array, n)
    end

    # Sets the range for a component. Java PDICCBased#setRangeForComponent.
    def set_range_for_component(range : Pdfbox::Pdmodel::Common::PDRange, n : Int32) : Nil
      range_array = @stream.cos_object.get_dictionary_object(Cos::Name::RANGE).as?(Cos::Array)
      unless range_array
        range_array = Cos::Array.new
        @stream.cos_object.set_item(Cos::Name::RANGE, range_array)
      end
      # extend range array with default values if needed
      while range_array.size < (n + 1) * 2
        range_array.add(Cos::Float::ZERO)
        range_array.add(Cos::Float::ONE)
      end
      range_array[n * 2] = Cos::Float.new(range.min)
      range_array[n * 2 + 1] = Cos::Float.new(range.max)
    end

    # The metadata stream (/Metadata), or nil. Java PDICCBased#getMetadata.
    def metadata : Cos::Stream?
      @stream.cos_object.get_dictionary_object(Cos::Name::METADATA).as?(Cos::Stream)
    end

    # Sets the metadata stream. Java PDICCBased#setMetadata.
    def metadata=(metadata : Cos::Stream?) : Nil
      key = Cos::Name::METADATA
      if metadata
        @stream.cos_object.set_item(key, metadata)
      else
        @stream.cos_object.delete(key)
      end
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
