# Port of Apache PDFBox PDTextState.
# Holds the current state of text parameters when executing a content stream.
module Pdfbox::Pdmodel::Graphics::State
  class PDTextState
    property character_spacing : Float32 = 0.0_f32
    property word_spacing : Float32 = 0.0_f32
    property horizontal_scaling : Float32 = 100.0_f32
    property leading : Float32 = 0.0_f32
    property font : Pdfbox::Pdmodel::Font::PDFont? = nil
    property font_size : Float32 = 0.0_f32
    property rendering_mode : RenderingMode = RenderingMode::Fill
    property rise : Float32 = 0.0_f32
    property knockout : Bool = true # ameba:disable Naming/QueryBoolMethods

    def initialize
    end

    # Creates a copy of this text state.
    def clone : PDTextState
      copy = PDTextState.new
      copy.character_spacing = @character_spacing
      copy.word_spacing = @word_spacing
      copy.horizontal_scaling = @horizontal_scaling
      copy.leading = @leading
      copy.font = @font
      copy.font_size = @font_size
      copy.rendering_mode = @rendering_mode
      copy.rise = @rise
      copy.knockout = @knockout
      copy
    end
  end
end
