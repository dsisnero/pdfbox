# Indexed color space (PDF 32000-1 8.6.6.3): a 1-component color space whose
# component is an index into a lookup table of base-color-space values.
# Port of Apache PDFBox PDIndexed (model surface).
module Pdfbox::Pdmodel::Graphics::Color
  class PDIndexed < PDColorSpace
    @array : Cos::Array
    @base_color_space : PDColorSpace
    @lookup_data : Bytes
    @actual_max_index : Int32

    def initialize(indexed_array : Cos::Array)
      @array = indexed_array

      base_object = indexed_array[1]?
      raise ::IO::Error.new("Could not read base color space") unless base_object
      if base_object.is_a?(Cos::Object)
        base_object = base_object.object
        raise ::IO::Error.new("Could not read base color space") unless base_object
      end
      created = PDColorSpace.create(base_object)
      raise ::IO::Error.new("Could not read base color space") unless created
      @base_color_space = created

      @lookup_data = Bytes.empty
      read_lookup_data

      max_index = Math.min(high_value, 255)
      num_components = @base_color_space.number_of_components

      # Some tables are too short.
      if num_components == 0 || @lookup_data.size // num_components < max_index + 1
        max_index = num_components == 0 ? 0 : (@lookup_data.size // num_components) - 1
      end
      max_index = 0 if max_index < 0
      @actual_max_index = max_index
    end

    def name : String
      "Indexed"
    end

    def number_of_components : Int32
      1
    end

    def base_color_space : PDColorSpace
      @base_color_space
    end

    # The /Hival entry (array element 2).
    def high_value : Int32
      value = @array[2]?
      value = value.object if value.is_a?(Cos::Object)
      case value
      when Cos::Integer then value.value.to_i32
      when Cos::Float   then value.value.to_i32
      else                   0
      end
    end

    def lookup_data : Bytes
      @lookup_data
    end

    def default_decode(bits_per_component : Int32) : Array(Float32)
      [0.0_f32, (2.0 ** bits_per_component).to_f32 - 1.0_f32]
    end

    def initial_color : PDColor
      PDColor.new([0.0_f32], self)
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      raise ::ArgumentError.new("Indexed color spaces must have one color value") if components.size != 1

      index = components[0].round.to_i
      index = Math.max(index, 0)
      index = Math.min(index, @actual_max_index)

      num_components = @base_color_space.number_of_components
      base = Array(Float32).new(num_components, 0.0_f32)
      offset = index * num_components
      num_components.times do |component|
        base[component] = (@lookup_data[offset + component] & 0xff) / 255.0_f32
      end
      @base_color_space.to_rgb(base)
    end

    def cos_object : Cos::Base
      @array
    end

    private def read_lookup_data : Nil
      lookup = @array[3]?
      lookup = lookup.object if lookup.is_a?(Cos::Object)
      @lookup_data = case lookup
                     when Cos::String
                       lookup.bytes
                     when Cos::Stream
                       Pdfbox::Pdmodel::Common::PDStream.new(lookup).to_byte_array
                     when Nil
                       Bytes.empty
                     else
                       raise ::IO::Error.new("Error: Unknown type for lookup table #{lookup.class}")
                     end
    end
  end
end
