module Pdfbox::ContentStream
  # Operator name constants for PDF content streams
  # Similar to Apache PDFBox OperatorName
  module OperatorName
    # Inline image operators
    BEGIN_INLINE_IMAGE      = "BI"
    BEGIN_INLINE_IMAGE_DATA = "ID"
    END_INLINE_IMAGE        = "EI"

    # Marked content
    BEGIN_MARKED_CONTENT_SEQ        = "BDC"
    BEGIN_MARKED_CONTENT            = "BMC"
    END_MARKED_CONTENT              = "EMC"
    MARKED_CONTENT_POINT_WITH_PROPS = "DP"
    MARKED_CONTENT_POINT            = "MP"
    DRAW_OBJECT                     = "Do"

    # Graphics state
    CONCAT                    = "cm"
    RESTORE                   = "Q"
    SAVE                      = "q"
    SET_FLATNESS              = "i"
    SET_GRAPHICS_STATE_PARAMS = "gs"
    SET_LINE_CAPSTYLE         = "J"
    SET_LINE_DASHPATTERN      = "d"
    SET_LINE_JOINSTYLE        = "j"
    SET_LINE_MITERLIMIT       = "M"
    SET_LINE_WIDTH            = "w"
    SET_MATRIX                = "Tm"
    SET_RENDERINGINTENT       = "ri"

    # Graphics drawing
    APPEND_RECT                      = "re"
    CLIP_EVEN_ODD                    = "W*"
    CLIP_NON_ZERO                    = "W"
    CLOSE_AND_STROKE                 = "s"
    CLOSE_FILL_EVEN_ODD_AND_STROKE   = "b*"
    CLOSE_FILL_NON_ZERO_AND_STROKE   = "b"
    CLOSE_PATH                       = "h"
    CURVE_TO                         = "c"
    CURVE_TO_REPLICATE_FINAL_POINT   = "y"
    CURVE_TO_REPLICATE_INITIAL_POINT = "v"
    ENDPATH                          = "n"
    FILL_EVEN_ODD_AND_STROKE         = "B*"
    FILL_EVEN_ODD                    = "f*"
    FILL_NON_ZERO_AND_STROKE         = "B"
    FILL_NON_ZERO                    = "f"
    LEGACY_FILL_NON_ZERO             = "F"
    LINE_TO                          = "l"
    MOVE_TO                          = "m"
    SHADING_FILL                     = "sh"
    STROKE_PATH                      = "S"

    # Text
    BEGIN_TEXT                  = "BT"
    END_TEXT                    = "ET"
    MOVE_TEXT                   = "Td"
    MOVE_TEXT_SET_LEADING       = "TD"
    NEXT_LINE                   = "T*"
    SET_CHAR_SPACING            = "Tc"
    SET_FONT_AND_SIZE           = "Tf"
    SET_TEXT_HORIZONTAL_SCALING = "Tz"
    SET_TEXT_LEADING            = "TL"
    SET_TEXT_RENDERINGMODE      = "Tr"
    SET_TEXT_RISE               = "Ts"
    SET_WORD_SPACING            = "Tw"
    SHOW_TEXT                   = "Tj"
    SHOW_TEXT_ADJUSTED          = "TJ"
    SHOW_TEXT_LINE              = "'"
    SHOW_TEXT_LINE_AND_SPACE    = "\""

    # Type3 font
    TYPE3_D0 = "d0"
    TYPE3_D1 = "d1"

    # Compatibility section
    BEGIN_COMPATIBILITY_SECTION = "BX"
    END_COMPATIBILITY_SECTION   = "EX"

    # Color operators
    NON_STROKING_COLOR      = "sc"
    NON_STROKING_COLOR_N    = "scn"
    NON_STROKING_RGB        = "rg"
    NON_STROKING_GRAY       = "g"
    NON_STROKING_CMYK       = "k"
    NON_STROKING_COLORSPACE = "cs"
    STROKING_COLOR          = "SC"
    STROKING_COLOR_N        = "SCN"
    STROKING_COLOR_RGB      = "RG"
    STROKING_COLOR_GRAY     = "G"
    STROKING_COLOR_CMYK     = "K"
    STROKING_COLORSPACE     = "CS"
  end
end
