require "./type1_font"

class Pdfbox::Pdmodel::Font::PDType1CFont < Pdfbox::Pdmodel::Font::PDType1Font
  # Creates a Type1C-equivalent font from a font dictionary.
  # Corresponds to org.apache.pdfbox.pdmodel.font.PDType1CFont.
  def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)
  rescue
    # Keep explicit class identity in partial-port code paths.
    raise "Not implemented: PDType1CFont"
  end
end
