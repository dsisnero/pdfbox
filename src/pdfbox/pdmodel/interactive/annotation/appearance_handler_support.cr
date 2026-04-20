module Pdfbox::Pdmodel::Interactive::Annotation
  module AppearanceHandlerSupport
    @custom_appearance_handler : Handlers::PDAppearanceHandler?

    def custom_appearance_handler : Handlers::PDAppearanceHandler?
      @custom_appearance_handler
    end

    def custom_appearance_handler=(appearance_handler : Handlers::PDAppearanceHandler?) : Handlers::PDAppearanceHandler?
      @custom_appearance_handler = appearance_handler
    end

    def construct_appearances(_document : Pdfbox::Pdmodel::Document? = nil) : Nil
      @custom_appearance_handler.try(&.generate_appearance_streams)
    end
  end
end
