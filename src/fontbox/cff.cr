# CFF (Compact Font Format) module for PDFBox Crystal
#
# This module contains CFF font parsing and rendering utilities,
# corresponding to the cff module in Apache PDFBox.

module Fontbox::CFF
  # CFF charset interface and implementations
  # CFF encoding and charset tables
  # CFF font parsing and data structures
  # Type1 and Type2 CharString interpreters
end

# Load CFF files in correct dependency order
require "./cff/standard_string"
require "./cff/encoding"
require "./cff/cff_expert_encoding"
require "./cff/cff_standard_encoding"
require "./cff/data_input"
require "./cff/data_input_byte_array"
require "./cff/data_input_random_access_read"
require "./cff/char_string_command"
require "./cff/charset"
require "./cff/cff_font"
require "./cff/cff_type1_font"
require "./cff/cff_cid_font"
require "./cff/cff_parser"
