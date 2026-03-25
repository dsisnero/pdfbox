# ZapfDingbats encoding
# Corresponds to ZapfDingbatsEncoding in Apache PDFBox.

class Pdfbox::Pdmodel::Font::Encoding::ZapfDingbatsEncoding < Pdfbox::Pdmodel::Font::Encoding::Encoding
  # Singleton instance of this class.
  INSTANCE = new

  # Table of octal character codes and their corresponding names.
  # TODO: Fill with actual mapping from Java source
  private ZAPF_DINGBATS_ENCODING_TABLE = [] of Tuple(Int32, String)

  # Private constructor.
  private def initialize
    ZAPF_DINGBATS_ENCODING_TABLE.each do |code, name|
      add(code, name)
    end
  end

  # Convert this object to a COS object.
  #
  # @return The cos object that represents this object.
  def cos_object : Cos::Base
    Cos::Name::ZAPF_DINGBATS_ENCODING
  end

  # Returns the name of this encoding.
  def encoding_name : String
    "ZapfDingbatsEncoding"
  end
end
