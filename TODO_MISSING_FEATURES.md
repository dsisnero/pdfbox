# Missing Features for Pending Tests

## High Priority Features

### 1. PDFRenderer (PDF Rendering)
- **Tests affected**: testPDFBox988
- **Description**: Need to implement PDFRenderer for rendering PDF pages to images
- **Files needed**: src/pdfbox/rendering/pdf_renderer.cr
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/PDFRenderer.java

### 2. PDType0Font with CID Support
- **Tests affected**: testPDFBox3747, testPDFBox3826, testDeleteFont, PDFBOX5920Type0
- **Description**: Need to implement PDType0Font.load() with proper CID font creation
- **Files needed**: src/pdfbox/pdmodel/font/type0_font.cr (enhance load methods)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDType0Font.java

### 3. Font Embedding (TrueType)
- **Tests affected**: testPDFBox3826, testPDFBOX4115, testEmbeddedFont, testEmbeddedFont2
- **Description**: Need to implement TrueType font embedding with subsetting
- **Files needed**: src/pdfbox/pdmodel/font/true_type_font.cr (enhance embedding)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDTrueTypeFont.java

### 4. TrueType Collection (TTC) Support
- **Tests affected**: testPDFox4318, testFullEmbeddingTTC
- **Description**: Need to implement TrueTypeCollection class for TTC files
- **Files needed**: src/fontbox/ttf/true_type_collection.cr
- **Java reference**: vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/ttf/TrueTypeCollection.java

### 5. Font File Handling
- **Tests affected**: testPDFBox3826, testPDFox5048
- **Description**: Need to implement font file detection and URI resolution
- **Files needed**: src/fontbox/util/autodetect/font_file_finder.cr
- **Java reference**: vendor/pdfbox/fontbox/src/main/java/org/apache/fontbox/util/autodetect/FontFileFinder.java

### 6. PDType1Font Embedding (PFB)
- **Tests affected**: testPDFBOX4115
- **Description**: Need to implement PDType1Font constructor with PFB file embedding
- **Files needed**: src/pdfbox/pdmodel/font/type1_font.cr (enhance constructors)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDType1Font.java

## Medium Priority Features

### 7. Identity-H/V Encoding
- **Tests affected**: testToUnicodeWritingIdentityH, testToUnicodeWritingIdentityV
- **Description**: Need to implement Identity-H and Identity-V CMap encodings
- **Files needed**: src/pdfbox/pdmodel/font/encoding/identity_encoding.cr
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/encoding/IdentityEncoding.java

### 8. Font Deletion from Resources
- **Tests affected**: testDeleteFont
- **Description**: Need to implement font deletion from document resources
- **Files needed**: src/pdfbox/pdmodel/resources.cr (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java

### 9. ToUnicode with Differences
- **Tests affected**: testToUnicodeWritingWithDifferences
- **Description**: Need to implement ToUnicode CMap with encoding differences
- **Files needed**: src/pdfbox/pdmodel/font/to_unicode_writer.cr (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/ToUnicodeWriter.java

### 10. Zero Font Matrix Handling
- **Tests affected**: testFontMatrixZero, testFontMatrixZeroSize, testFontMatrixZeroSize2, testFontMatrixZeroSize3
- **Description**: Need to handle edge cases with zero or invalid font matrices
- **Files needed**: src/pdfbox/pdmodel/font/pdfont.cr (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDFont.java

## Low Priority Features

### 11. Script-Specific Font Embedding
- **Tests affected**: testBengali, testDevanagari, testDevanagari2, testGujarati
- **Description**: Need to support font embedding for Indic scripts
- **Files needed**: src/pdfbox/pdmodel/font/ (enhance embedding)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/

### 12. CIDFontType2 Embedding
- **Tests affected**: testCIDFontType2, testCIDFontType2Subset, testCIDFontType2VerticalSubsetMonospace, testCIDFontType2VerticalSubsetProportional
- **Description**: Need to implement CIDFontType2 embedding
- **Files needed**: src/pdfbox/pdmodel/font/cid_font_type2.cr (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/PDCIDFontType2.java

### 13. Encryption Support
- **Tests affected**: testCompressEncryptedDoc
- **Description**: Need to implement encryption in writer
- **Files needed**: src/pdfbox/pdmodel/encryption/ (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/

### 14. COS Writer Object Graph Parity
- **Tests affected**: testPDFBox6036
- **Description**: Need to ensure COS writer matches Java implementation
- **Files needed**: src/pdfbox/pdfwriter.cr (enhance)
- **Java reference**: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfwriter/COSWriter.java

## Implementation Notes

1. **PDType0Font.load()** currently expects PDDocument but should also accept Document
2. **Font embedding** requires TrueType font parsing and subsetting
3. **PDFRenderer** requires PDF content stream rendering to image
4. **TTC support** requires TrueTypeCollection class for multi-font files
5. **Identity encoding** requires CMap encoding support
