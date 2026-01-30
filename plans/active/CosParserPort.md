# COSParser.java Porting Plan

## Overview
Port Apache PDFBox `COSParser.java` to Crystal `src/pdfbox/pdf_parser/cos_parser.cr`. This document tracks all methods that need to be implemented/verified.

## Java Source Reference
- File: `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/COSParser.java`
- Lines: 676 total (including comments)

## Methods to Port

### Constructors
- [x] `COSParser(RandomAccessRead source) throws IOException` (Simple constructor implemented)
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias) throws IOException`
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias, StreamCacheCreateFunction streamCacheCreateFunction) throws IOException`

### Public Methods
- [ ] `void setEOFLookupRange(int byteCount)`
- [ ] `boolean isLenient()`
- [ ] `COSBase dereferenceCOSObject(COSObject obj) throws IOException`
- [ ] `RandomAccessReadView createRandomAccessReadView(long startPosition, long streamLength) throws IOException`

### Protected Methods
- [ ] `COSDictionary retrieveTrailer() throws IOException`
- [x] `void setLenient(boolean lenient)` (via BaseParser.set_lenient)
- [ ] `COSBase parseObjectStreamObject(long objstmObjNr, COSObjectKey key) throws IOException`
- [x] `COSArray parseCOSArray() throws IOException` (Logic verified, matches Java)
- [x] `COSDictionary parseCOSDictionary(boolean isDirect) throws IOException` (Logic verified, matches Java)
- [x] `COSBase parseDirObject() throws IOException` (Logic verified, matches Java)
- [~] `COSStream parseCOSStream(COSDictionary dic) throws IOException` (Partially implemented, needs verification)
- [ ] `BruteForceParser getBruteForceParser() throws IOException`
- [ ] `void checkPages(COSDictionary root) throws IOException`
- [ ] `boolean isString(char[] string) throws IOException`
- [ ] `void readObjectMarker() throws IOException`
- [ ] `long readObjectNumber() throws IOException`
- [ ] `int readGenerationNumber() throws IOException`
- [x] `String readLine() throws IOException` (Logic verified, matches Java)
- [x] `boolean parsePDFHeader() throws IOException` (Implemented as `parse_pdf_header`)
- [x] `boolean parseFDFHeader() throws IOException` (Implemented as `parse_fdf_header`)
- [ ] `PDEncryption getEncryption() throws IOException`
- [ ] `AccessPermission getAccessPermission() throws IOException`
- [ ] `void prepareDecryption() throws IOException`
- [ ] `SecurityHandler<ProtectionPolicy> getSecurityHandler()`
- [x] `COSName parseCOSName() throws IOException` (Logic verified, matches Java)
- [x] `COSString parseCOSLiteralString() throws IOException` (Implemented as parse_cos_literal_string)
- [x] `COSString parseCOSHexString() throws IOException` (Implemented via parse_string)
- [x] `COSObjectKey getObjectKey(long num, int gen)` (Implemented as get_object_key)

### Private Methods (Important)
- [ ] `void init(StreamCacheCreateFunction streamCacheCreateFunction)`
- [ ] `Long getObjectOffset(COSObjectKey objKey, boolean requireExistingNotCompressedObj) throws IOException`
- [ ] `COSBase parseFileObject(Long objOffset, COSObjectKey objKey) throws IOException`
- [x] `COSNumber getLength(COSBase lengthBaseObj) throws IOException` (Implemented as get_length)
- [x] `boolean parseCOSDictionaryNameValuePair(COSDictionary obj) throws IOException` (Logic verified)
- [x] `COSNumber parseCOSNumber() throws IOException` (Implemented via parse_number)
- [x] `COSBase parseCOSDictionaryValue() throws IOException` (Logic verified)
- [x] `boolean readUntilEndOfCOSDictionary() throws IOException` (Logic verified)
- [x] `COSBase getObjectFromPool(COSObjectKey key) throws IOException` (Implemented as get_object_from_pool)
- [x] `long readUntilEndStream(EndstreamFilterStream out) throws IOException` (Implemented as read_until_end_stream)
- [x] `boolean validateStreamLength(long streamLength) throws IOException` (Implemented)
- [ ] `int lastIndexOf(char[] pattern, byte[] buf, int endOff)`

### Constants and Fields
- [ ] Static constants: `PDF_HEADER`, `FDF_HEADER`, `MAX_RECURSION_DEPTH`, etc.
- [ ] Instance fields: `document`, `xrefTable`, `decompressedObjects`, `securityHandler`, etc.

## Crystal Implementation Status
File: `src/pdfbox/pdf_parser/cos_parser.cr`

### Already Implemented Methods (Verified)
- [x] `parse_dir_object` (Logic matches Java `parseDirObject`)
- [x] `parse_object` (alias)
- [x] `parse_dictionary` (Logic matches Java `parseCOSDictionary`)
- [x] `parse_array` (Logic matches Java `parseCOSArray`)
- [x] `parse_cos_literal_string` (Calls BaseParser.read_literal_string_as_string)
- [x] `parse_string` (Handles both literal and hex strings via BaseParser methods)
- [x] `parse_name` (Logic matches Java `parseCOSName` with hex escape handling)
- [x] `parse_number` (Uses BaseParser.read_number which matches Java logic)
- [x] `parse_reference` (Parses indirect object references, similar to Java pattern)
- [x] `parse_boolean` (Uses read_expected_string with FALSE/TRUE arrays)
- [x] `parse_null` (Uses read_expected_string with NULL array)
- [x] `read_line` (Logic matches Java `readLine`)

### Missing Methods (Critical)
- **Constructors with encryption**: Password, keystore, keyAlias support
- **Xref/trailer parsing**: `retrieveTrailer()`, `parseFileObject()`, `getObjectOffset()`
- **Object stream parsing**: `parseObjectStreamObject()`
- **Brute force parser integration**: `getBruteForceParser()`
- **Header parsing**: `parsePDFHeader()`, `parseFDFHeader()` ✅ IMPLEMENTED
- **Encryption/security**: `getEncryption()`, `getAccessPermission()`, `prepareDecryption()`, `getSecurityHandler()`
- **Page tree validation**: `checkPages()`
- **Object marker/number reading**: `readObjectMarker()`, `readObjectNumber()`, `readGenerationNumber()`
- **String validation**: `isString()`
- **Index utilities**: `lastIndexOf()`
- **Initialization**: `init()` with stream cache
- **Complete stream parsing**: `parseCOSStream()` needs full verification and integration

### Partially Implemented
- **Stream parsing**: `parse_cos_stream` exists but needs verification against edge cases
- **Constants**: PDF_HEADER, FDF_HEADER, EOF_MARKER, OBJ_MARKER added; missing OBJECT_NUMBER_THRESHOLD, GENERATION_NUMBER_THRESHOLD, etc.
- **Fields**: Missing `document`, `xrefTable`, `decompressedObjects`, `securityHandler`, etc.

## Verification Checklist
For each method, verify:
1. [x] **Core parsing methods** (parseDirObject, parseCOSArray, parseCOSDictionary, parseCOSName, parseCOSLiteralString, parseCOSHexString, parseCOSNumber, readLine): Method signatures match Java equivalent, logic verified
2. [x] **Error handling**: BaseParser methods provide similar error messages and exceptions
3. [x] **Recursion depth limits**: MAX_RECURSION_DEPTH implemented and enforced
4. [x] **Lenient mode**: Supported via `lenient?` property throughout parsing methods
5. [~] **Test coverage**: Existing tests pass, but need to port Java COSParser tests
6. [ ] **Encryption/security methods**: Not yet implemented
7. [ ] **Xref/trailer parsing**: Not yet implemented
8. [ ] **Object stream parsing**: Not yet implemented
9. [ ] **Stream parsing edge cases**: `parse_cos_stream` needs thorough verification

## Next Steps (Priority Order)

1. **Complete object stream parsing** (`parseObjectStreamObject`) - Critical for compressed PDFs
2. **Add encryption/decryption stubs** - Allow encrypted PDFs to load with placeholder security
3. **Verify `parse_cos_stream` thoroughly** - Stream parsing is complex and error-prone
4. **Add xref/trailer methods to COSParser** - For API completeness (may be covered by Parser class)
5. **Port Java COSParser tests** - Ensure edge case coverage
6. **Add remaining constants and fields** - OBJECT_NUMBER_THRESHOLD, GENERATION_NUMBER_THRESHOLD, etc.
7. **Implement remaining private methods** - `lastIndexOf`, `isString`, `readObjectMarker`, `readObjectNumber`, `readGenerationNumber`

## Immediate Action Items
- ✅ **Beads issues created** for object stream parsing, encryption stubs, header parsing, stream verification, constants
- **Next work**: Start with object stream parsing (most critical missing feature)
- **Quality**: Ensure all existing tests continue to pass after each addition
- **Update**: Keep this document updated as methods are implemented

## Notes
- This class is critical for PDF parsing performance
- Must maintain exact compatibility with Apache PDFBox behavior
- Many methods depend on `BaseParser` already ported
- Encryption support can be stubbed initially
- Focus on parsing logic before adding security features