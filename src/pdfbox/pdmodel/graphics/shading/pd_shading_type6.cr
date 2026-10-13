module Pdfbox::Pdmodel::Graphics::Shading
  # Coons patch mesh (PDF 32000-1 8.7.4.5.7), ShadingType 6.
  # Port of Apache PDFBox PDShadingType6 (model surface).
  class PDShadingType6 < PDMeshBasedShadingType
    def shading_type : Int32
      SHADING_TYPE6
    end
  end
end
