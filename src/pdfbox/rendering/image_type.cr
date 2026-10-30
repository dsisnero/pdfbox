# Image type for rendering.
#
# Port of org.apache.pdfbox.rendering.ImageType. Java maps each member to an AWT
# `BufferedImage` type; the port produces `CrImage::RGBA` for the two types it
# can rasterize faithfully (RGB and ARGB) and rejects the AWT-only GRAY/BINARY
# rasters (documented divergence in `PDFRenderer#render_image`).
module Pdfbox::Rendering
  enum ImageType
    # Black or white (Java `TYPE_BYTE_BINARY`).
    BINARY
    # Shades of gray (Java `TYPE_BYTE_GRAY`).
    GRAY
    # Red, green, blue (Java `TYPE_INT_RGB`).
    RGB
    # Alpha, red, green, blue (Java `TYPE_INT_ARGB`).
    ARGB

    # Whether Java clears the image to opaque white for this type. Only the
    # types without an alpha channel get a white page; ARGB stays transparent
    # (Java `PDFRenderer#renderImage`).
    def opaque_background? : Bool
      self != ARGB
    end
  end
end
