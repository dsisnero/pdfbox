module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  # The standard structure types (PDF 32000-1, Table 333). Corresponds to
  # StandardStructureTypes in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/StandardStructureTypes.java
  class StandardStructureTypes
    DOCUMENT    = "Document"
    PART        = "Part"
    ART         = "Art"
    SECT        = "Sect"
    DIV         = "Div"
    BLOCK_QUOTE = "BlockQuote"
    CAPTION     = "Caption"
    TOC         = "TOC"
    TOCI        = "TOCI"
    INDEX       = "Index"
    NON_STRUCT  = "NonStruct"
    PRIVATE     = "Private"
    P           = "P"
    H           = "H"
    H1          = "H1"
    H2          = "H2"
    H3          = "H3"
    H4          = "H4"
    H5          = "H5"
    H6          = "H6"
    L           = "L"
    LI          = "LI"
    LBL         = "Lbl"
    L_BODY      = "LBody"
    TABLE       = "Table"
    TR          = "TR"
    TH          = "TH"
    TD          = "TD"
    T_HEAD      = "THead"
    T_BODY      = "TBody"
    T_FOOT      = "TFoot"
    SPAN        = "Span"
    QUOTE       = "Quote"
    NOTE        = "Note"
    REFERENCE   = "Reference"
    BIB_ENTRY   = "BibEntry"
    CODE        = "Code"
    LINK        = "Link"
    ANNOT       = "Annot"
    RUBY        = "Ruby"
    RB          = "RB"
    RT          = "RT"
    RP          = "RP"
    WARICHU     = "Warichu"
    WT          = "WT"
    WP          = "WP"
    Figure      = "Figure"
    FORMULA     = "Formula"
    FORM        = "Form"

    # All standard structure types (Java StandardStructureTypes.types).
    TYPES = [
      DOCUMENT, PART, ART, SECT, DIV, BLOCK_QUOTE, CAPTION, TOC, TOCI, INDEX,
      NON_STRUCT, PRIVATE, P, H, H1, H2, H3, H4, H5, H6, L, LI, LBL, L_BODY,
      TABLE, TR, TH, TD, T_HEAD, T_BODY, T_FOOT, SPAN, QUOTE, NOTE, REFERENCE,
      BIB_ENTRY, CODE, LINK, ANNOT, RUBY, RB, RT, RP, WARICHU, WT, WP, Figure,
      FORMULA, FORM,
    ] of String
  end
end
