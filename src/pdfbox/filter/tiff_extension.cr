# TIFF extension constants used by the CCITT fax codecs.
# Java: org.apache.pdfbox.filter.TIFFExtension
module Pdfbox::Filter
  module TIFFExtension
    # Compression types
    COMPRESSION_CCITT_MODIFIED_HUFFMAN_RLE = 2
    COMPRESSION_CCITT_T4                   = 3
    COMPRESSION_CCITT_T6                   = 4

    # Group 3 options
    GROUP3OPT_2DENCODING   = 1
    GROUP3OPT_UNCOMPRESSED = 2
    GROUP3OPT_FILLBITS     = 4
    GROUP3OPT_BYTEALIGNED  = 8

    # Group 4 options
    GROUP4OPT_UNCOMPRESSED = 2
    GROUP4OPT_BYTEALIGNED  = 4

    # Fill order
    FILL_LEFT_TO_RIGHT = 1
  end
end
