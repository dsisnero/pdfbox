require "./type1_font"

class Pdfbox::Pdmodel::Font::PDMMType1Font < Pdfbox::Pdmodel::Font::PDType1Font
  # Creates an MMType1 font from a font dictionary.
  # Corresponds to org.apache.pdfbox.pdmodel.font.PDMMType1Font, which simply
  # extends PDType1Font and delegates to its constructor.
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)
  end
end
