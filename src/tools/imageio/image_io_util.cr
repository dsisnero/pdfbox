module Tools::Imageio
  # Partial port of org.apache.pdfbox.tools.imageio.ImageIOUtil.
  module ImageIOUtil
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
  end
end
