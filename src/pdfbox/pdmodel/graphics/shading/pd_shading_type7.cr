module Pdfbox::Pdmodel::Graphics::Shading
  # Tensor-product patch mesh (PDF 32000-1 8.7.4.5.8), ShadingType 7.
  # Port of Apache PDFBox PDShadingType7 (model surface).
  class PDShadingType7 < PDMeshBasedShadingType
    def shading_type : Int32
      SHADING_TYPE7
    end
  end
end
