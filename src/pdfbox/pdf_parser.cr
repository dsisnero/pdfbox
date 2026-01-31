# PDF Parser module for PDFBox Crystal
#
# This module contains PDF parsing functionality,
# corresponding to the pdfparser package in Apache PDFBox.

require "./pdf_parser/errors"
require "./pdf_parser/parser"
require "./pdf_parser/xref"
require "./pdf_parser/xref_trailer_resolver"

require "./pdf_parser/pdf_io"
require "./pdf_parser/cos_parser"
require "./pdf_parser/pdf_stream_parser"

module Pdfbox::Pdfparser
end
