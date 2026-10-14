require "./pd_special_color_space"
require "../../common/function/pdfunction"

module Pdfbox::Pdmodel::Graphics::Color
  # A Separation colour space (a single colorant with a tint transform into an
  # alternate colour space). Corresponds to PDSeparation in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDSeparation.java
  class PDSeparation < PDSpecialColorSpace
    COLORANT_NAMES = 1
    ALTERNATE_CS   = 2
    TINT_TRANSFORM = 3

    @array : Cos::Array
    @alternate_color_space : PDColorSpace?
    @tint_transform : Pdfbox::Pdmodel::Common::Function::PDFunction?
    @initial_color : PDColor?

    def initialize
      @array = Cos::Array.new
      @array.add(Cos::Name.new("Separation"))
      @array.add(Cos::Name.new(""))
      @array.add(Cos::Null::INSTANCE)
      @array.add(Cos::Null::INSTANCE)
      @alternate_color_space = nil
      @tint_transform = nil
      @initial_color = nil
    end

    def initialize(separation : Cos::Array)
      @array = separation
      @initial_color = nil
      alternate_base = deref(@array[ALTERNATE_CS])
      @alternate_color_space = alternate_base ? PDColorSpace.create(alternate_base) : nil

      tint = deref(@array[TINT_TRANSFORM])
      @tint_transform = tint ? Pdfbox::Pdmodel::Common::Function::PDFunction.create(tint) : nil

      if tint = @tint_transform
        output_parameters = tint.number_of_output_parameters
        alternate = @alternate_color_space
        if output_parameters > 0 && alternate && output_parameters < alternate.number_of_components
          raise ::IO::Error.new(
            "The tint transform function has less output parameters (#{output_parameters}) " \
            "than the alternate colorspace (#{alternate.number_of_components})")
        end
      end
    end

    def cos_object : Cos::Base
      @array
    end

    def name : String
      "Separation"
    end

    def number_of_components : Int32
      1
    end

    def default_decode(bits_per_component : Int32) : Array(Float32)
      [0.0_f32, 1.0_f32]
    end

    def initial_color : PDColor
      @initial_color ||= PDColor.new([1.0_f32], self)
    end

    # Java toRGB: evaluate the tint transform, then convert via the alternate
    # colour space.
    def to_rgb(components : Array(Float32)) : Array(Float32)
      alternate = @alternate_color_space
      tint = @tint_transform
      return [0.0_f32, 0.0_f32, 0.0_f32] unless alternate && tint

      alternate.to_rgb(tint.eval(components))
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

    # The colorant name (/Name at index 1), or nil.
    def colorant_name : String?
      value = deref(@array[COLORANT_NAMES])
      value.is_a?(Cos::Name) ? value.value : nil
    end

    def colorant_name=(name : String) : Nil
      @array[COLORANT_NAMES] = Cos::Name.new(name)
    end

    private def deref(base : Cos::Base) : Cos::Base?
      base.is_a?(Cos::Object) ? base.object : base
    end
  end
end
