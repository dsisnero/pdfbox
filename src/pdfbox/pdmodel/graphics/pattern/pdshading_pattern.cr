require "./pdabstract_pattern"
require "../shading"
require "../state/pd_extended_graphics_state"

module Pdfbox::Pdmodel::Graphics::Pattern
  # A shading pattern dictionary. Corresponds to PDShadingPattern in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/pattern/PDShadingPattern.java
  class PDShadingPattern < PDAbstractPattern
    @extended_graphics_state : Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState? = nil
    @shading : Pdfbox::Pdmodel::Graphics::Shading::PDShading? = nil

    def initialize
      super
      @pattern_dictionary.set_int(Cos::Name.new("PatternType"), TYPE_SHADING_PATTERN)
    end

    def initialize(dictionary : Cos::Dictionary)
      super(dictionary)
    end

    def pattern_type : Int32
      TYPE_SHADING_PATTERN
    end

    # Java getExtendedGraphicsState.
    def extended_graphics_state : Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState?
      unless @extended_graphics_state
        base = @pattern_dictionary.get_dictionary(Cos::Name.new("ExtGState"))
        @extended_graphics_state =
          base ? Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState.new(base) : nil
      end
      @extended_graphics_state
    end

    # Java setExtendedGraphicsState.
    def extended_graphics_state=(value : Pdfbox::Pdmodel::Graphics::State::PDExtendedGraphicsState) : Nil
      @extended_graphics_state = value
      @pattern_dictionary[Cos::Name.new("ExtGState")] = value.cos_object
    end

    # Java getShading.
    def shading : Pdfbox::Pdmodel::Graphics::Shading::PDShading?
      unless @shading
        base = @pattern_dictionary.get_dictionary(Cos::Name.new("Shading"))
        @shading = base ? Pdfbox::Pdmodel::Graphics::Shading::PDShading.create(base) : nil
      end
      @shading
    end

    # Java setShading.
    def shading=(value : Pdfbox::Pdmodel::Graphics::Shading::PDShading) : Nil
      @shading = value
      @pattern_dictionary[Cos::Name.new("Shading")] = value.cos_object
    end
  end
end
