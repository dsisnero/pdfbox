module Pdfbox::Pdmodel::Graphics::Shading
  # Axial shading (PDF 32000-1 8.7.4.5.3), ShadingType 2.
  # Port of Apache PDFBox PDShadingType2 (model surface).
  class PDShadingType2 < PDShading
    def shading_type : Int32
      SHADING_TYPE2
    end

    # The optional /Extend values, or nil (Java getExtend).
    def extend_values : Pdfbox::Cos::Array?
      @dict.get_array(Pdfbox::Cos::Name.new("Extend"))
    end

    def extend_values=(new_extend : Pdfbox::Cos::Array?) : Nil
      set_optional_array("Extend", new_extend)
    end

    # The optional /Domain values, or nil (Java getDomain).
    def domain : Pdfbox::Cos::Array?
      @dict.get_array(Pdfbox::Cos::Name.new("Domain"))
    end

    def domain=(new_domain : Pdfbox::Cos::Array?) : Nil
      set_optional_array("Domain", new_domain)
    end

    # The /Coords values, or nil (Java getCoords).
    def coords : Pdfbox::Cos::Array?
      @dict.get_array(Pdfbox::Cos::Name.new("Coords"))
    end

    def coords=(new_coords : Pdfbox::Cos::Array?) : Nil
      set_optional_array("Coords", new_coords)
    end
  end
end
