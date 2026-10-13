module Pdfbox::Pdmodel::Graphics::Shading
  # Radial shading (PDF 32000-1 8.7.4.5.4), ShadingType 3.
  # Port of Apache PDFBox PDShadingType3 (model surface).
  class PDShadingType3 < PDShadingType2
    def shading_type : Int32
      SHADING_TYPE3
    end
  end
end
