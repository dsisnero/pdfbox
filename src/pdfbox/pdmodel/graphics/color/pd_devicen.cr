require "./pd_special_color_space"
require "./pd_devicen_attributes"
require "../../common/function/pdfunction"

module Pdfbox::Pdmodel::Graphics::Color
  # DeviceN colour spaces may contain an arbitrary number of colour components.
  # Corresponds to PDDeviceN in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceN.java
  class PDDeviceN < PDSpecialColorSpace
    COLORANT_NAMES     = 1
    ALTERNATE_CS       = 2
    TINT_TRANSFORM     = 3
    DEVICEN_ATTRIBUTES = 4

    @array : Cos::Array
    @alternate_color_space : PDColorSpace?
    @tint_transform : Pdfbox::Pdmodel::Common::Function::PDFunction?
    @attributes : PDDeviceNAttributes?
    @initial_color : PDColor?
    @num_colorants : Int32 = 0
    @colorant_to_component : Array(Int32) = [] of Int32
    @process_color_space : PDColorSpace? = nil
    @spot_color_spaces : Array(PDSeparation?) = [] of PDSeparation?

    def initialize
      @array = Cos::Array.new
      @array.add(Cos::Name.new("DeviceN"))
      @array.add(Cos::Null::INSTANCE)
      @array.add(Cos::Null::INSTANCE)
      @array.add(Cos::Null::INSTANCE)
      @alternate_color_space = nil
      @tint_transform = nil
      @attributes = nil
      @initial_color = nil
    end

    def initialize(device_n : Cos::Array)
      @array = device_n
      @alternate_color_space = nil
      @tint_transform = nil
      @attributes = nil
      @initial_color = nil

      alternate_base = deref(@array[ALTERNATE_CS])
      @alternate_color_space = alternate_base ? PDColorSpace.create(alternate_base) : nil

      tint = deref(@array[TINT_TRANSFORM])
      @tint_transform = tint ? Pdfbox::Pdmodel::Common::Function::PDFunction.create(tint) : nil

      if @array.size > DEVICEN_ATTRIBUTES
        attr_base = deref(@array[DEVICEN_ATTRIBUTES])
        @attributes = PDDeviceNAttributes.new(attr_base) if attr_base.is_a?(Cos::Dictionary)
      end

      init_color_conversion_cache
    end

    def cos_object : Cos::Base
      @array
    end

    def name : String
      "DeviceN"
    end

    def number_of_components : Int32
      colorant_names.size
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new(Array(Float32).new(number_of_components, 1.0_f32), self)
    end

    # Java toRGB: use the attributes (custom blending) if present, otherwise the
    # tint transform.
    def to_rgb(components : Array(Float32)) : Array(Float32)
      if @attributes
        to_rgb_with_attributes(components)
      else
        to_rgb_with_tint_transform(components)
      end
    end

    # Java isNChannel.
    def n_channel? : Bool
      @attributes.try(&.n_channel?) || false
    end

    # Java getColorantNames: the /Names array as a list of names.
    def colorant_names : Array(String)
      names_array = deref(@array[COLORANT_NAMES]).as?(Cos::Array)
      return [] of String unless names_array
      names_array.items.compact_map do |item|
        item = item.object if item.is_a?(Cos::Object)
        item.as?(Cos::Name).try(&.value)
      end
    end

    def colorant_names=(names : Array(String)) : Nil
      array = Cos::Array.new
      names.each { |name| array.add(Cos::Name.new(name)) }
      @array[COLORANT_NAMES] = array
    end

    def attributes : PDDeviceNAttributes?
      @attributes
    end

    def attributes=(value : PDDeviceNAttributes?) : Nil
      @attributes = value
      if value
        while @array.size <= DEVICEN_ATTRIBUTES
          @array.add(Cos::Null::INSTANCE)
        end
        @array[DEVICEN_ATTRIBUTES] = value.cos_dictionary
      elsif @array.size > DEVICEN_ATTRIBUTES
        @array.remove(DEVICEN_ATTRIBUTES)
      end
    end

    def alternate_color_space : PDColorSpace?
      @alternate_color_space
    end

    def alternate_color_space=(color_space : PDColorSpace?) : Nil
      @alternate_color_space = color_space
      @array[ALTERNATE_CS] = color_space ? color_space.cos_object : Cos::Null::INSTANCE
    end

    def tint_transform : Pdfbox::Pdmodel::Common::Function::PDFunction?
      @tint_transform
    end

    def tint_transform=(tint : Pdfbox::Pdmodel::Common::Function::PDFunction?) : Nil
      @tint_transform = tint
      @array[TINT_TRANSFORM] = tint ? tint.cos_object : Cos::Null::INSTANCE
    end

    # Java initColorConversionCache.
    private def init_color_conversion_cache : Nil
      attributes = @attributes
      return unless attributes

      names = colorant_names
      @num_colorants = names.size
      @colorant_to_component = Array(Int32).new(names.size, -1)
      @spot_color_spaces = Array(PDSeparation?).new(names.size, nil)

      process = attributes.process
      if process
        components = process.components
        names.each_with_index do |name, index|
          @colorant_to_component[index] = components.index(name) || -1
        end
        @process_color_space = process.color_space
      end

      spot_colorants = attributes.colorants
      names.each_with_index do |name, index|
        spot = spot_colorants[name]?
        next unless spot
        @spot_color_spaces[index] = spot
        @colorant_to_component[index] = -1 unless n_channel?
      end
    end

    private def to_rgb_with_attributes(value : Array(Float32)) : Array(Float32)
      rgb_value = [1.0_f32, 1.0_f32, 1.0_f32]

      @num_colorants.times do |index|
        is_process_colorant = @colorant_to_component[index] >= 0
        component_color_space =
          if is_process_colorant
            @process_color_space
          elsif @spot_color_spaces[index].nil?
            return to_rgb_with_tint_transform(value)
          else
            @spot_color_spaces[index]
          end
        return to_rgb_with_tint_transform(value) unless component_color_space

        component_samples = Array(Float32).new(component_color_space.number_of_components, 0.0_f32)
        if is_process_colorant
          component_samples[@colorant_to_component[index]] = value[index]
        else
          component_samples[0] = value[index]
        end

        rgb_component = component_color_space.to_rgb(component_samples)
        rgb_value[0] *= rgb_component[0]
        rgb_value[1] *= rgb_component[1]
        rgb_value[2] *= rgb_component[2]
      end

      rgb_value
    end

    private def to_rgb_with_tint_transform(value : Array(Float32)) : Array(Float32)
      alternate = @alternate_color_space
      tint = @tint_transform
      return [0.0_f32, 0.0_f32, 0.0_f32] unless alternate && tint

      alternate.to_rgb(tint.eval(value))
    end

    private def deref(base : Cos::Base) : Cos::Base?
      base.is_a?(Cos::Object) ? base.object : base
    end
  end
end
