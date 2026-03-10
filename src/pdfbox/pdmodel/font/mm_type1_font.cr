require "./type1_font"

class Pdfbox::Pdmodel::Font::PDMMType1Font < Pdfbox::Pdmodel::Font::PDType1Font
  # Creates an MMType1 font from a font dictionary.
  # Corresponds to org.apache.pdfbox.pdmodel.font.PDMMType1Font.
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)
  rescue
    # Keep explicit class identity in partial-port code paths.
    raise "Not implemented: PDMMType1Font"
  end
end
