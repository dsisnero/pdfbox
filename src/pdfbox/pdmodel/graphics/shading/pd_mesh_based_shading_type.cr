module Pdfbox::Pdmodel::Graphics::Shading
  # Shared model surface for the patch meshes (ShadingType 6/7).
  # Port of Apache PDFBox PDMeshBasedShadingType (model surface; the patch reads and
  # bounds are rendering-only and out of scope in the Crystal port).
  abstract class PDMeshBasedShadingType < PDShadingType4
  end
end
