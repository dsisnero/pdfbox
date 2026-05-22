module Pdfbox::Pdmodel::Interactive::Annotation::Handlers
  class PDSoundAppearanceHandler < PDAbstractAppearanceHandler
    def initialize(@annotation : Annotation::PDAnnotation)
      super
    end

    def initialize(@annotation : Annotation::PDAnnotation, @document : Pdmodel::PDDocument)
      super
    end

    def generate_normal_appearance : Nil
      # TODO to be implemented
    end

    def generate_rollover_appearance : Nil
      # TODO to be implemented
    end

    def generate_down_appearance : Nil
      # TODO to be implemented
    end
  end
end
