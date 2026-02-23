# Standard 14 PDF fonts, also known as the "base 14" fonts.
# There are 14 font files, but Acrobat uses additional names for compatibility, e.g. Arial.
# Corresponds to Standard14Fonts in Apache PDFBox.
class Pdfbox::Pdmodel::Font::Standard14Fonts
  # Class representing a standard 14 font name.
  class FontName
    getter name : String

    def initialize(@name : String)
    end

    def to_s : String
      @name
    end

    def ==(other : FontName)
      @name == other.name
    end

    def hash
      @name.hash
    end

    # Define constants for each standard font
    TIMES_ROMAN            = new("Times-Roman")
    TIMES_BOLD             = new("Times-Bold")
    TIMES_ITALIC           = new("Times-Italic")
    TIMES_BOLD_ITALIC      = new("Times-BoldItalic")
    HELVETICA              = new("Helvetica")
    HELVETICA_BOLD         = new("Helvetica-Bold")
    HELVETICA_OBLIQUE      = new("Helvetica-Oblique")
    HELVETICA_BOLD_OBLIQUE = new("Helvetica-BoldOblique")
    COURIER                = new("Courier")
    COURIER_BOLD           = new("Courier-Bold")
    COURIER_OBLIQUE        = new("Courier-Oblique")
    COURIER_BOLD_OBLIQUE   = new("Courier-BoldOblique")
    SYMBOL                 = new("Symbol")
    ZAPF_DINGBATS          = new("ZapfDingbats")
  end

  @@aliases = Hash(String, FontName).new

  # Static initializer
  private def self.init_aliases : Nil
    # the 14 standard fonts
    map_name(FontName::TIMES_ROMAN)
    map_name(FontName::TIMES_BOLD)
    map_name(FontName::TIMES_ITALIC)
    map_name(FontName::TIMES_BOLD_ITALIC)
    map_name(FontName::HELVETICA)
    map_name(FontName::HELVETICA_BOLD)
    map_name(FontName::HELVETICA_OBLIQUE)
    map_name(FontName::HELVETICA_BOLD_OBLIQUE)
    map_name(FontName::COURIER)
    map_name(FontName::COURIER_BOLD)
    map_name(FontName::COURIER_OBLIQUE)
    map_name(FontName::COURIER_BOLD_OBLIQUE)
    map_name(FontName::SYMBOL)
    map_name(FontName::ZAPF_DINGBATS)

    # alternative names from Adobe Supplement to the ISO 32000
    map_name("CourierCourierNew", FontName::COURIER)
    map_name("CourierNew", FontName::COURIER)
    map_name("CourierNew,Italic", FontName::COURIER_OBLIQUE)
    map_name("CourierNew,Bold", FontName::COURIER_BOLD)
    map_name("CourierNew,BoldItalic", FontName::COURIER_BOLD_OBLIQUE)
    map_name("Arial", FontName::HELVETICA)
    map_name("Arial,Italic", FontName::HELVETICA_OBLIQUE)
    map_name("Arial,Bold", FontName::HELVETICA_BOLD)
    map_name("Arial,BoldItalic", FontName::HELVETICA_BOLD_OBLIQUE)
    map_name("TimesNewRoman", FontName::TIMES_ROMAN)
    map_name("TimesNewRoman,Italic", FontName::TIMES_ITALIC)
    map_name("TimesNewRoman,Bold", FontName::TIMES_BOLD)
    map_name("TimesNewRoman,BoldItalic", FontName::TIMES_BOLD_ITALIC)

    # Acrobat treats these fonts as "standard 14" too (at least Acrobat preflight says so)
    map_name("Symbol,Italic", FontName::SYMBOL)
    map_name("Symbol,Bold", FontName::SYMBOL)
    map_name("Symbol,BoldItalic", FontName::SYMBOL)
    map_name("Times", FontName::TIMES_ROMAN)
    map_name("Times,Italic", FontName::TIMES_ITALIC)
    map_name("Times,Bold", FontName::TIMES_BOLD)
    map_name("Times,BoldItalic", FontName::TIMES_BOLD_ITALIC)

    # PDFBOX-3457: PDF.js file bug864847.pdf
    map_name("ArialMT", FontName::HELVETICA)
    map_name("Arial-ItalicMT", FontName::HELVETICA_OBLIQUE)
    map_name("Arial-BoldMT", FontName::HELVETICA_BOLD)
    map_name("Arial-BoldItalicMT", FontName::HELVETICA_BOLD_OBLIQUE)
  end

  # Initialize aliases on first use
  private def self.ensure_aliases_initialized : Nil
    if @@aliases.empty?
      init_aliases
    end
  end

  # Adds a standard font name to the map of known aliases.
  private def self.map_name(base_name : FontName) : Nil
    @@aliases[base_name.to_s] = base_name
  end

  # Adds an alias name for a standard font to the map of known aliases.
  private def self.map_name(alias_name : String, base_name : FontName) : Nil
    @@aliases[alias_name] = base_name
  end

  # Returns the base name of the font which the given font name maps to.
  # @param font_name name of font, either a base name or an alias
  # @return the base name or nil if this is not one of the known names
  def self.get_mapped_font_name(font_name : String) : FontName?
    ensure_aliases_initialized
    @@aliases[font_name]?
  end

  # Returns true if the given font name is one of the known names, including alias.
  def self.contains_name?(font_name : String) : Bool
    ensure_aliases_initialized
    @@aliases.has_key?(font_name)
  end

  # Returns the set of known font names, including aliases.
  def self.names : Set(String)
    ensure_aliases_initialized
    @@aliases.keys.to_set
  end

  # Placeholder for getAFM - returns nil for now
  # In Java, this loads AFM metrics from resources
  def self.get_afm(font_name : String) # TODO: Return FontMetrics type
    nil
  end

  # Private constructor
  private def initialize
  end
end
