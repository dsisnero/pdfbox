# FontBox module for PDFBox Crystal
#
# This module contains font processing functionality,
# corresponding to the fontbox module in Apache PDFBox.
module Fontbox
  # Raised when a font file is corrupted or cannot be parsed
  class DamagedFontException < Exception; end
end

require "./fontbox/afm"
require "./fontbox/cmap"
require "./fontbox/cff"
require "./fontbox/encoding"
require "./fontbox/pfb"
require "./fontbox/type1"
require "./fontbox/ttf"
require "./fontbox/font_box_font"
require "./fontbox/util"
