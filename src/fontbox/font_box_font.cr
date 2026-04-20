# Common interface for all FontBox fonts
module Fontbox
  abstract class FontBoxFont
    # The PostScript name of the font
    abstract def name : String

    # Returns the font's bounding box in PostScript units
    abstract def font_bbox : Util::BoundingBox

    # Returns the FontMatrix in PostScript units
    abstract def font_matrix : Array(Float32)

    # Returns the path for the character with the given name
    abstract def path(name : String) : Util::Path

    # Returns the advance width for the character with the given name
    abstract def width(name : String) : Float32

    # Returns true if the font contains the given glyph
    abstract def has_glyph?(name : String) : Bool
  end
end
