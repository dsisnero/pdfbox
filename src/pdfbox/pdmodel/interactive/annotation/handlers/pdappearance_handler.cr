module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  module PDAppearanceHandler
    def generate_appearance_streams : Nil
      generate_normal_appearance
      generate_rollover_appearance
      generate_down_appearance
    end

    abstract def generate_normal_appearance : Nil

    def generate_rollover_appearance : Nil
    end

    def generate_down_appearance : Nil
    end
  end
end
