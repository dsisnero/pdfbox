module Pdfbox::Pdmodel::Graphics::Shading
  # Lattice-form Gouraud-shaded triangle mesh, ShadingType 5.
  # Port of Apache PDFBox PDShadingType5 (model surface).
  class PDShadingType5 < PDTriangleBasedShadingType
    def shading_type : Int32
      SHADING_TYPE5
    end

    # The vertices per row (/VerticesPerRow), or -1 (Java getVerticesPerRow).
    def vertices_per_row : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("VerticesPerRow"), -1_i64).to_i32
    end

    def vertices_per_row=(vertices_per_row : Int32) : Nil
      @dict.set_int(Pdfbox::Cos::Name.new("VerticesPerRow"), vertices_per_row)
    end
  end
end
