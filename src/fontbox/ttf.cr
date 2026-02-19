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
require "./ttf/random_access_read_unbuffered_data_stream"
require "./ttf/ttc_data_stream"
require "./ttf/ttf_table"
require "./ttf/cmap_lookup"
require "./ttf/ttf_tables"
require "./ttf/os2_windows_metrics_table"
require "./ttf/font_headers"
require "./ttf/true_type_font"
require "./ttf/ttf_parser"
require "./ttf/true_type_collection"
require "./ttf/ttf_subsetter"
require "./ttf/gsub/glyph_substitution_data_extractor"
require "./ttf/gsub/glyph_array_splitter"
require "./ttf/gsub/compound_character_tokenizer"
require "./ttf/gsub/glyph_array_splitter_regex_impl"
require "./ttf/gsub/gsub_worker"
require "./ttf/gsub/gsub_worker_factory"
require "./ttf/gsub/gsub_worker_for_bengali"
require "./ttf/gsub/gsub_worker_for_devanagari"
require "./ttf/gsub/gsub_worker_for_gujarati"
require "./ttf/gsub/gsub_worker_for_latin"
require "./ttf/gsub/gsub_worker_for_dflt"
require "./ttf/gsub/gsub_worker_for_tamil"
