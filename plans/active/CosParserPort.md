# COSParser.java Porting Plan

## Overview
Port Apache PDFBox `COSParser.java` to Crystal `src/pdfbox/pdf_parser/cos_parser.cr`. This document tracks all methods that need to be implemented/verified.

## Java Source Reference
- File: `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/COSParser.java`
- Lines: 676 total (including comments)

## Methods to Port

### Constructors
- [ ] `COSParser(RandomAccessRead source) throws IOException`
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias) throws IOException`
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias, StreamCacheCreateFunction streamCacheCreateFunction) throws IOException`

### Public Methods
- [ ] `void setEOFLookupRange(int byteCount)`
- [ ] `boolean isLenient()`
- [ ] `COSBase dereferenceCOSObject(COSObject obj) throws IOException`
- [ ] `RandomAccessReadView createRandomAccessReadView(long startPosition, long streamLength) throws IOException`

### Protected Methods
- [ ] `COSDictionary retrieveTrailer() throws IOException`
- [ ] `void setLenient(boolean lenient)`
- [ ] `COSBase parseObjectStreamObject(long objstmObjNr, COSObjectKey key) throws IOException`
- [x] `COSArray parseCOSArray() throws IOException`
- [x] `COSDictionary parseCOSDictionary(boolean isDirect) throws IOException`
- [x] `COSBase parseDirObject() throws IOException`
- [ ] `COSStream parseCOSStream(COSDictionary dic) throws IOException`
- [ ] `BruteForceParser getBruteForceParser() throws IOException`
- [ ] `void checkPages(COSDictionary root) throws IOException`
- [ ] `boolean isString(char[] string) throws IOException`
- [ ] `void readObjectMarker() throws IOException`
- [ ] `long readObjectNumber() throws IOException`
- [ ] `int readGenerationNumber() throws IOException`
- [ ] `String readLine() throws IOException`
- [ ] `boolean parsePDFHeader() throws IOException`
- [ ] `boolean parseFDFHeader() throws IOException`
- [ ] `PDEncryption getEncryption() throws IOException`
- [ ] `AccessPermission getAccessPermission() throws IOException`
- [ ] `void prepareDecryption() throws IOException`
- [ ] `SecurityHandler<ProtectionPolicy> getSecurityHandler()`
- [ ] `COSName parseCOSName() throws IOException`
- [x] `COSString parseCOSLiteralString() throws IOException`
- [x] `COSString parseCOSHexString() throws IOException`
- [ ] `COSObjectKey getObjectKey(long num, int gen)`

### Private Methods (Important)
- [ ] `void init(StreamCacheCreateFunction streamCacheCreateFunction)`
- [ ] `Long getObjectOffset(COSObjectKey objKey, boolean requireExistingNotCompressedObj) throws IOException`
- [ ] `COSBase parseFileObject(Long objOffset, COSObjectKey objKey) throws IOException`
- [ ] `COSNumber getLength(COSBase lengthBaseObj) throws IOException`
- [ ] `boolean parseCOSDictionaryNameValuePair(COSDictionary obj) throws IOException`
- [x] `COSNumber parseCOSNumber() throws IOException`
- [ ] `COSBase parseCOSDictionaryValue() throws IOException`
- [ ] `boolean readUntilEndOfCOSDictionary() throws IOException`
- [ ] `COSBase getObjectFromPool(COSObjectKey key) throws IOException`
- [ ] `long readUntilEndStream(EndstreamFilterStream out) throws IOException`
- [ ] `boolean validateStreamLength(long streamLength) throws IOException`
- [ ] `int lastIndexOf(char[] pattern, byte[] buf, int endOff)`

### Constants and Fields
- [ ] Static constants: `PDF_HEADER`, `FDF_HEADER`, `MAX_RECURSION_DEPTH`, etc.
- [ ] Instance fields: `document`, `xrefTable`, `decompressedObjects`, `securityHandler`, etc.

## Crystal Implementation Status
File: `src/pdfbox/pdf_parser/cos_parser.cr`

### Already Implemented Methods (Need Verification)
- [x] `parse_dir_object` (similar to Java `parseDirObject`)
- [x] `parse_object` (alias)
- [x] `parse_dictionary` (similar to Java `parseCOSDictionary`)
- [x] `parse_array` (similar to Java `parseCOSArray`)
- [x] `parse_cos_literal_string` (similar to Java `parseCOSLiteralString`)
- [x] `parse_string` (handles both literal and hex strings)
- [~] `parse_name` (similar to Java `parseCOSName`)
- [x] `parse_number`
- [x] `parse_reference`
- [x] `parse_boolean`
- [x] `parse_null`
- [x] `read_line` (similar to Java `readLine`)

### Missing Methods
- Most constructors and initialization logic
- Encryption/decryption related methods
- Xref/trailer parsing methods
- Object stream parsing
- Brute force parser integration
- Length validation and stream parsing logic
- Header parsing (PDF/FDF)

## Verification Checklist
For each method, verify:
1. [ ] Method signature matches Java equivalent
2. [ ] Logic follows Java implementation exactly
3. [ ] Error handling matches Java (exceptions, messages)
4. [ ] Edge cases handled identically
5. [ ] Recursion depth limits implemented
6. [ ] Lenient mode support where applicable
7. [ ] Test coverage matches Java test suite

## Next Steps
1. Create beads issues for each major method group
2. Start with core parsing methods (`parseDirObject`, `parseCOSArray`, `parseCOSDictionary`)
3. Add encryption/decryption stubs
4. Implement xref/trailer parsing
5. Add object stream support
6. Integrate with existing Parser class
7. Run existing tests to ensure no regressions

## Notes
- This class is critical for PDF parsing performance
- Must maintain exact compatibility with Apache PDFBox behavior
- Many methods depend on `BaseParser` already ported
- Encryption support can be stubbed initially
- Focus on parsing logic before adding security features