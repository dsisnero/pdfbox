module Pdfbox::Pdmodel::Graphics::Shading
  # Free-form Gouraud-shaded triangle mesh (PDF 32000-1 8.7.4.5.5), ShadingType 4.
  # Port of Apache PDFBox PDShadingType4 (model surface).
  class PDShadingType4 < PDTriangleBasedShadingType
    def shading_type : Int32
      SHADING_TYPE4
    end

    # The bits per flag (/BitsPerFlag), or -1 (Java getBitsPerFlag).
    def bits_per_flag : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("BitsPerFlag"), -1_i64).to_i32
    end

    def bits_per_flag=(bits_per_flag : Int32) : Nil
      @dict.set_int(Pdfbox::Cos::Name.new("BitsPerFlag"), bits_per_flag)
    end
  end
end
