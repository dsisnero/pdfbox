# Inline image object which uses a special syntax to express the data for a
# small image directly within the content stream.
# Port of Apache PDFBox PDInlineImage (model-level surface).
module Pdfbox::Pdmodel::Graphics::Image
  class PDInlineImage < PDImage
    @parameters : Pdfbox::Cos::Dictionary
    @resources : Pdfbox::Pdmodel::PDResources?
    @raw_data : Bytes
    @decoded_data : Bytes

    def initialize(@parameters : Pdfbox::Cos::Dictionary, @raw_data : Bytes, @resources : Pdfbox::Pdmodel::PDResources? = nil)
      @decoded_data = @raw_data
      filters = self.filters
      unless filters.empty?
        decoded = @raw_data
        filters.each do |filter_name|
          # CCITT/DCT/JPX inline images are not decoded here (no DecodeParms/
          # dimensions); the raw data is kept as-is so the model surface works.

          filter = Filter::FilterFactory::INSTANCE.filter(Pdfbox::Cos::Name.new(filter_name))
          decoded = filter.decode(decoded) unless filter.is_a?(Filter::CCITTFaxFilter) || filter.is_a?(Filter::DCTFilter)
        rescue ::IO::Error
          next
        end
        @decoded_data = decoded
      end
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @parameters
    end

    def bits_per_component : Int32
      if stencil?
        1
      else
        bpc = @parameters.get_int(Pdfbox::Cos::Name.new("BPC"), -1_i64)
        bpc = @parameters.get_int(Pdfbox::Cos::Name.new("BitsPerComponent"), -1_i64) if bpc < 0
        bpc.to_i32
      end
    end

    def bits_per_component=(bits_per_component : Int32) : Nil
      @parameters.set_int("BPC", bits_per_component)
    end

    def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?
      cs = @parameters[Pdfbox::Cos::Name.new("CS")]?
      cs = @parameters[Pdfbox::Cos::Name.new("ColorSpace")] unless cs
      if cs
        create_color_space(cs)
      elsif stencil?
        # stencil mask color space must be gray, it is often missing
        Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE
      else
        # an image without a color space is always broken
        raise ::IO::Error.new("could not determine inline image color space")
      end
    end

    def color_space=(color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?) : Nil
      @parameters[Pdfbox::Cos::Name.new("CS")] = color_space.try(&.cos_object) || Pdfbox::Cos::Null.instance
    end

    def height : Int32
      h = @parameters.get_int(Pdfbox::Cos::Name.new("H"), -1_i64)
      h = @parameters.get_int(Pdfbox::Cos::Name.new("Height"), -1_i64) if h < 0
      h.to_i32
    end

    def height=(height : Int32) : Nil
      @parameters.set_int("H", height)
    end

    def width : Int32
      w = @parameters.get_int(Pdfbox::Cos::Name.new("W"), -1_i64)
      w = @parameters.get_int(Pdfbox::Cos::Name.new("Width"), -1_i64) if w < 0
      w.to_i32
    end

    def width=(width : Int32) : Nil
      @parameters.set_int("W", width)
    end

    def interpolate? : Bool
      interpolate = @parameters[Pdfbox::Cos::Name.new("I")]?
      interpolate = @parameters[Pdfbox::Cos::Name.new("Interpolate")] unless interpolate
      interpolate.is_a?(Pdfbox::Cos::Boolean) && interpolate.value
    end

    def interpolate=(value : Bool) : Nil
      @parameters.set_boolean("I", value)
    end

    # Returns a list of filters applied to this stream, never nil.
    def filters : Array(String)
      filters = @parameters[Pdfbox::Cos::Name.new("F")]?
      filters = @parameters[Pdfbox::Cos::Name.new("Filter")] unless filters
      case filters
      when Pdfbox::Cos::Name
        [filters.value]
      when Pdfbox::Cos::Array
        filters.to_cos_name_string_list.compact
      else
        [] of String
      end
    end

    def filters=(filters : Array(String)) : Nil
      @parameters[Pdfbox::Cos::Name.new("F")] = Pdfbox::Cos::Array.of_cos_names(filters)
    end

    def decode=(decode : Pdfbox::Cos::Array?) : Nil
      @parameters[Pdfbox::Cos::Name.new("D")] = decode || Pdfbox::Cos::Null.instance
    end

    def decode : Pdfbox::Cos::Array?
      d = @parameters[Pdfbox::Cos::Name.new("D")]?
      d = @parameters[Pdfbox::Cos::Name.new("Decode")] unless d
      if d.is_a?(Pdfbox::Cos::Array)
        d
      end
    end

    def stencil? : Bool
      im = @parameters[Pdfbox::Cos::Name.new("IM")]?
      im = @parameters[Pdfbox::Cos::Name.new("ImageMask")] unless im
      im.is_a?(Pdfbox::Cos::Boolean) && im.value
    end

    def stencil=(is_stencil : Bool) : Nil
      @parameters.set_boolean("IM", is_stencil)
    end

    # Returns the decoded image data as an input stream.
    def create_input_stream : ::IO
      ::IO::Memory.new(@decoded_data)
    end

    def create_input_stream(stop_filters : Array(String)) : ::IO
      stop_filters # unused: inline images keep their raw data

      create_input_stream
    end

    def data : Bytes
      @decoded_data
    end

    def empty? : Bool
      @decoded_data.empty?
    end

    def suffix : String
      filter_list = filters

      if filter_list.empty?
        return "png"
      end
      if filter_list.includes?("DCTDecode") || filter_list.includes?("DCT")
        return "jpg"
      end
      if filter_list.includes?("CCITTFaxDecode") || filter_list.includes?("CCF")
        return "tiff"
      end
      "png"
    end

    private def to_long_name(cs : Pdfbox::Cos::Base) : Pdfbox::Cos::Base
      if cs.is_a?(Pdfbox::Cos::Name)
        case cs.value
        when "RGB"  then return Pdfbox::Cos::Name.new("DeviceRGB")
        when "CMYK" then return Pdfbox::Cos::Name.new("DeviceCMYK")
        when "G"    then return Pdfbox::Cos::Name.new("DeviceGray")
        end
      end
      cs
    end

    private def create_color_space(cs : Pdfbox::Cos::Base) : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace
      if cs.is_a?(Pdfbox::Cos::Name)
        if result = Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(to_long_name(cs))
          return result
        end
        raise ::IO::Error.new("Illegal type of inline image color space: #{cs}")
      end

      if cs.is_a?(Pdfbox::Cos::Array) && cs.size > 1
        cs_type = cs[0]
        cs_type = cs_type.object if cs_type.is_a?(Pdfbox::Cos::Object)
        if cs_type.is_a?(Pdfbox::Cos::Name) && (cs_type.value == "I" || cs_type.value == "Indexed")
          dst_array = Pdfbox::Cos::Array.new
          cs.items.each { |item| dst_array.add(item) }
          dst_array[0] = Pdfbox::Cos::Name.new("Indexed")
          dst_array[1] = to_long_name(cs[1])
          if result = Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(dst_array)
            return result
          end
          raise ::IO::Error.new("Illegal type of inline image color space: #{cs_type}")
        end

        raise ::IO::Error.new("Illegal type of inline image color space: #{cs_type}")
      end

      raise ::IO::Error.new("Illegal type of object for inline image color space: #{cs}")
    end
  end
end
