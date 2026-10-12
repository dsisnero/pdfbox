require "crimage"

module Tools::Imageio
  # Partial port of org.apache.pdfbox.tools.imageio.ImageIOUtil.
  module ImageIOUtil
    # Writer format names recognized by this port (mirrors the ImageIO writers
    # available for the supported CrImage formats).
    WRITER_FORMAT_NAMES = %w[bmp gif ico jpeg jpg png tif tiff]

    def self.format_name_from_filename(filename : String) : String
      index = filename.rindex('.')
      return filename unless index
      filename[(index + 1)..]
    end

    # Java logic: PNG uses max compression (0), all other formats use 1.
    def self.default_compression_quality(format_name : String) : Float32
      format_name.compare("png", case_insensitive: true) == 0 ? 0_f32 : 1_f32
    end

    # Java logic checks lowercased format starts with "tif".
    def self.tif_format?(format_name : String) : Bool
      format_name.downcase.starts_with?("tif")
    end

    def self.supported_format?(format_name : String) : Bool
      WRITER_FORMAT_NAMES.includes?(format_name)
    end

    # Port of ImageIOUtil#writeImage(BufferedImage, String filename, int dpi).
    # The filename suffix selects the image format. Returns true if the image
    # file was produced, false if no writer exists for the format.
    def self.write_image(image : CrImage::Image, filename : String, dpi : Int32) : Bool
      write_image(image, filename, dpi, default_compression_quality(format_name_from_filename(filename)))
    end

    # Port of ImageIOUtil#writeImage(BufferedImage, String filename, int dpi, float compressionQuality).
    def self.write_image(image : CrImage::Image, filename : String, dpi : Int32,
                         compression_quality : Float32) : Bool
      format_name = format_name_from_filename(filename)
      return false unless supported_format?(format_name)
      File.open(filename, "wb") do |io|
        write_image(image, format_name, io, dpi, compression_quality)
      end
    end

    # Port of ImageIOUtil#writeImage(BufferedImage, String formatName, OutputStream output, int dpi, float compressionQuality).
    # Compression is fixed for PNG, GIF, BMP and WBMP; dependent on the
    # compressionQuality parameter for JPG; and dependent on bit count for TIFF.
    def self.write_image(image : CrImage::Image, format_name : String, io : ::IO, dpi : Int32,
                         compression_quality : Float32 = 1_f32) : Bool
      case format_name.downcase
      when "png"
        CrImage::PNG.write(io, image)
      when "jpg", "jpeg"
        quality = (compression_quality * 100).round.to_i.clamp(0, 100)
        CrImage::JPEG.write(io, image, quality)
      when "bmp"
        CrImage::BMP.write(io, image)
      when "gif"
        CrImage::GIF.write(io, image)
      when "ico"
        CrImage::ICO.write(io, image)
      when "tif", "tiff"
        CrImage::TIFF.write(io, image)
      else
        return false
      end
      true
    end
  end
end
