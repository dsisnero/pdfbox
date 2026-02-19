# Filter module for PDF stream filters and predictor helpers.
module Pdfbox::Filter
end

require "./filter/filter"
require "./filter/identity_filter"
require "./filter/flate_filter"
require "./filter/ascii85_filter"
require "./filter/predictor"
require "./filter/run_length_decode_filter"
require "./filter/lzw_filter"
require "./filter/filter_factory"
