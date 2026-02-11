# TTF (TrueType Font) module for PDFBox Crystal
#
# This module contains TrueType font parsing and rendering utilities,
# corresponding to the ttf module in Apache PDFBox.

module Fontbox::TTF
  # TrueType font parsing and data structures
  # TTF table parsing and glyph rendering
end

# Load TTF files in correct dependency order
require "./ttf/wgl4_names"
require "./ttf/ttf_data_stream"
require "./ttf/random_access_read_data_stream"
require "./ttf/true_type_collection"
