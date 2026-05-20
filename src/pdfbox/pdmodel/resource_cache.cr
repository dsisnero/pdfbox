module Pdfbox::Pdmodel
  # Document-wide cache for page resources (fonts, color spaces, etc.).
  # Port of org.apache.pdfbox.pdmodel.ResourceCache interface.
  class ResourceCache
    @fonts = {} of Cos::Object => Font::PDFont
    @color_spaces = {} of Cos::Object => Graphics::Color::PDColorSpace
    @ext_gstates = {} of Cos::Object => Graphics::State::PDExtendedGraphicsState
    @properties = {} of Cos::Object => DocumentInterchange::MarkedContent::PDPropertyList
    @objects = {} of Cos::Object => Cos::Base

    def get_font(indirect : Cos::Object) : Font::PDFont?
      @fonts[indirect]?
    end

    def get_color_space(indirect : Cos::Object) : Graphics::Color::PDColorSpace?
      @color_spaces[indirect]?
    end

    def get_ext_gstate(indirect : Cos::Object) : Graphics::State::PDExtendedGraphicsState?
      @ext_gstates[indirect]?
    end

    def get_properties(indirect : Cos::Object) : DocumentInterchange::MarkedContent::PDPropertyList?
      @properties[indirect]?
    end

    def put(indirect : Cos::Object, font : Font::PDFont) : Nil
      @fonts[indirect] = font
    end

    def put(indirect : Cos::Object, color_space : Graphics::Color::PDColorSpace) : Nil
      @color_spaces[indirect] = color_space
    end

    def put(indirect : Cos::Object, ext_gstate : Graphics::State::PDExtendedGraphicsState) : Nil
      @ext_gstates[indirect] = ext_gstate
    end

    def put(indirect : Cos::Object, property_list : DocumentInterchange::MarkedContent::PDPropertyList) : Nil
      @properties[indirect] = property_list
    end

    def remove_font(indirect : Cos::Object) : Font::PDFont?
      @fonts.delete(indirect)
    end

    def remove_color_space(indirect : Cos::Object) : Graphics::Color::PDColorSpace?
      @color_spaces.delete(indirect)
    end

    def remove_ext_state(indirect : Cos::Object) : Graphics::State::PDExtendedGraphicsState?
      @ext_gstates.delete(indirect)
    end

    def remove_properties(indirect : Cos::Object) : DocumentInterchange::MarkedContent::PDPropertyList?
      @properties.delete(indirect)
    end
  end
end
