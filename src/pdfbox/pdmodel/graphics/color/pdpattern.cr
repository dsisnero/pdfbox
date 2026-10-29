# Pattern color space
module Pdfbox::Pdmodel::Graphics::Color
  class PDPattern < PDColorSpace
    @resources : Pdfbox::Pdmodel::PDResources?
    @underlying_color_space : PDColorSpace?

    # Creates a pattern colour space for the given resources.
    # Java PDPattern(PDResources).
    def initialize(@resources : Pdfbox::Pdmodel::PDResources? = nil)
    end

    # Creates an uncoloured tiling pattern colour space.
    # Java PDPattern(PDResources, PDColorSpace).
    def initialize(@resources : Pdfbox::Pdmodel::PDResources?,
                   @underlying_color_space : PDColorSpace)
    end

    # The resources of the page this colour space was created for. Java keeps
    # this reference so a pattern name can be resolved (PDPattern#getPattern).
    def resources : Pdfbox::Pdmodel::PDResources?
      @resources
    end

    # Returns the underlying color space for uncolored tiling patterns
    def underlying_color_space : PDColorSpace?
      @underlying_color_space
    end

    # Returns the pattern the given colour refers to.
    # Java PDPattern#getPattern(PDColor): looks the pattern name up in the
    # resources and throws an IOException when it is not there.
    def get_pattern(color : PDColor) : Pdfbox::Pdmodel::Graphics::Pattern::PDAbstractPattern
      name = color.pattern_name
      pattern = name ? @resources.try(&.pattern(name)) : nil
      unless pattern
        raise ::IO::Error.new("pattern #{name.try(&.value) || "null"} was not found")
      end
      pattern
    end

    def cos_object : Cos::Base
      Cos::Name.new("Pattern")
    end

    def name : String
      "Pattern"
    end

    def number_of_components : Int32
      @underlying_color_space.try(&.number_of_components) || 0
    end

    # Java PDPattern#getInitialColor returns EMPTY_PATTERN: a colour with no
    # components and no colour space ("a pattern which leaves no marks on the
    # page"), which differs from the zero-filled colour the base class builds.
    def initial_color : PDColor
      PDColor.new([] of Float32, nil)
    end

    # Java PDPattern#getDefaultDecode always throws.
    def default_decode(bits_per_component : Int32) : Array(Float32)
      raise Cos::UnsupportedOperationError.new("Unsupported operation")
    end

    def to_rgb(components : Array(Float32)) : Array(Float32)
      # Pattern colors cannot be directly converted to RGB
      [0.0_f32, 0.0_f32, 0.0_f32]
    end
  end
end
