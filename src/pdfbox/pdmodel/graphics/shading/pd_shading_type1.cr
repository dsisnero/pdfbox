module Pdfbox::Pdmodel::Graphics::Shading
  # Function-based shading (PDF 32000-1 8.7.4.5.2), ShadingType 1.
  # Port of Apache PDFBox PDShadingType1 (model surface).
  class PDShadingType1 < PDShading
    def shading_type : Int32
      SHADING_TYPE1
    end

    # The optional /Matrix entry as a Matrix; identity when absent (Java getMatrix).
    def matrix : Pdfbox::Util::Matrix
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("Matrix"))
      value ? Pdfbox::Util::Matrix.create_matrix(value) : Pdfbox::Util::Matrix.identity
    end

    def matrix=(transform : Pdfbox::Util::Matrix) : Nil
      @dict[Pdfbox::Cos::Name.new("Matrix")] = transform.to_cos_array
    end

    # The optional /Domain values, or nil (Java getDomain).
    def domain : Pdfbox::Cos::Array?
      @dict.get_array(Pdfbox::Cos::Name.new("Domain"))
    end

    def domain=(new_domain : Pdfbox::Cos::Array?) : Nil
      set_optional_array("Domain", new_domain)
    end
  end
end
