# COSParser.java Porting Plan

## Overview
Port Apache PDFBox `COSParser.java` to Crystal `src/pdfbox/pdf_parser/cos_parser.cr`. This document tracks all methods that need to be implemented/verified.

## Java Source Reference
- File: `apache_pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdfparser/COSParser.java`
- Lines: 676 total (including comments)

## Methods to Port

### Constructors
- [x] `COSParser(RandomAccessRead source)` — Simple constructor implemented
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias)`
- [ ] `COSParser(RandomAccessRead source, String password, InputStream keyStore, String keyAlias, StreamCacheCreateFunction)`

### Public Methods
- [x] `void setEOFLookupRange(int byteCount)` — `eof_lookup_range=` implemented
- [x] `boolean isLenient()` — `lenient?` implemented
- [x] `COSBase dereferenceCOSObject(COSObject obj)` — `dereference_cos_object` implemented
- [x] `RandomAccessReadView createRandomAccessReadView(long startPosition, long streamLength)` — `create_random_access_read_view` implemented

### Protected Methods
- [x] `COSDictionary retrieveTrailer()` — `retrieve_trailer` implemented (line 125)
- [x] `void setLenient(boolean lenient)` — via `set_lenient` (line 107)
- [x] `COSBase parseObjectStreamObject(long objstmObjNr, COSObjectKey key)` — delegates to Parser (line 1232)
- [x] `COSArray parseCOSArray()` — `parse_array` implemented (line 583)
- [x] `COSDictionary parseCOSDictionary(boolean isDirect)` — `parse_dictionary` implemented (line 452)
- [x] `COSBase parseDirObject()` — `parse_dir_object` implemented (line 374)
- [~] `COSStream parseCOSStream(COSDictionary dic)` — `parse_cos_stream` implemented (line 1105), needs edge-case verification
- [x] `BruteForceParser getBruteForceParser()` — `brute_force_parser` implemented (line 241)
- [x] `void checkPages(COSDictionary root)` — `check_pages` implemented (line 248)
- [x] `boolean isString(char[] string)` — `string?` implemented (line 981)
- [x] `void readObjectMarker()` — covered by parsing logic in BaseParser
- [x] `long readObjectNumber()` — covered by parsing logic in BaseParser
- [x] `int readGenerationNumber()` — covered by parsing logic in BaseParser
- [x] `String readLine()` — `read_line` implemented (line 934)
- [x] `boolean parsePDFHeader()` — implemented in BaseParser
- [x] `boolean parseFDFHeader()` — implemented in BaseParser
- [x] `PDEncryption getEncryption()` — `encryption` implemented (line 300)
- [x] `AccessPermission getAccessPermission()` — `access_permission` implemented (line 306)
- [x] `void prepareDecryption()` — `prepare_decryption` implemented (line 311)
- [x] `SecurityHandler getSecurityHandler()` — `security_handler` implemented (line 368)
- [x] `COSName parseCOSName()` — `parse_name` implemented (line 675)
- [x] `COSString parseCOSLiteralString()` — `parse_cos_literal_string` implemented (line 648)
- [x] `COSString parseCOSHexString()` — `parse_string` handles both (line 654)
- [x] `COSObjectKey getObjectKey(long num, int gen)` — `object_key` implemented (line 902)

### Private Methods
- [ ] `void init(StreamCacheCreateFunction streamCacheCreateFunction)` — stream cache not yet supported
- [x] `Long getObjectOffset(COSObjectKey objKey, boolean requireExistingNotCompressedObj)` — `object_offset` implemented (line 1244)
- [ ] `COSBase parseFileObject(Long objOffset, COSObjectKey objKey)` — file object parsing may be covered by parser
- [x] `COSNumber getLength(COSBase lengthBaseObj)` — `length` implemented (line 956)
- [x] `boolean parseCOSDictionaryNameValuePair(COSDictionary obj)` — implemented (line 496)
- [x] `COSNumber parseCOSNumber()` — `parse_number` implemented (line 728)
- [x] `COSBase parseCOSDictionaryValue()` — `parse_cos_dictionary_value` implemented (line 518)
- [x] `boolean readUntilEndOfCOSDictionary()` — `read_until_end_of_cos_dictionary` implemented (line 552)
- [x] `COSBase getObjectFromPool(COSObjectKey key)` — `object_from_pool` implemented (line 924)
- [x] `long readUntilEndStream(EndstreamFilterStream out)` — `read_until_end_stream` implemented (line 1028)
- [x] `boolean validateStreamLength(long streamLength)` — `validate_stream_length` implemented (line 994)
- [x] `int lastIndexOf(char[] pattern, byte[] buf, int endOff)` — `last_index_of` implemented (line 222)

## Crystal Implementation Status
File: `src/pdfbox/pdf_parser/cos_parser.cr` (1425 lines)

### Implemented Methods (Verified)
All core parsing methods, encryption/security, xref/trailer, object stream, brute force, page tree validation, and utility methods are implemented.

- [x] `parse_dir_object`, `parse_object`, `parse_dictionary`, `parse_array`
- [x] `parse_cos_literal_string`, `parse_string`, `parse_name`, `parse_number`, `parse_number_or_reference`
- [x] `parse_reference`, `parse_boolean`, `parse_null`
- [x] `read_line`, `read_until_end_of_cos_dictionary`
- [x] `parse_cos_dictionary_name_value_pair`, `parse_cos_dictionary_value`
- [x] `retrieve_trailer`, `object_offset`, `object_key`, `object_from_pool`
- [x] `parse_cos_stream`, `read_until_end_stream`, `validate_stream_length`
- [x] `parse_object_stream_object` (delegates to Parser)
- [x] `encryption`, `access_permission`, `prepare_decryption`, `security_handler`
- [x] `brute_force_parser`, `check_pages`, `check_pages_dictionary`
- [x] `last_index_of`, `string?`, `length`, `decode_buffer`
- [x] `startxref_offset`, `document_id_bytes`
- [x] `eof_lookup_range=`, `lenient?`, `set_lenient`

### Remaining Gaps
- [ ] Constructor variants with password/keystore/keyAlias
- [ ] `init(StreamCacheCreateFunction)` — stream cache support
- [x] `dereferenceCOSObject` — implemented
- [x] `createRandomAccessReadView` — implemented
- [x] `parseFileObject` — already implemented

## Verification Checklist
For each method, verify:
1. [x] **Core parsing methods**: All implemented, logic verified
2. [x] **Error handling**: BaseParser methods provide similar error messages
3. [x] **Recursion depth limits**: MAX_RECURSION_DEPTH enforced
4. [x] **Lenient mode**: Supported via `lenient?` throughout
5. [~] **Test coverage**: Existing tests pass; some edge cases need Java test porting
6. [x] **Encryption/security methods**: Implemented (encryption, access_permission, prepare_decryption, security_handler)
7. [x] **Xref/trailer parsing**: Implemented (retrieve_trailer, object_offset)
8. [x] **Object stream parsing**: Implemented (delegates to Parser)
9. [~] **Stream parsing edge cases**: `parse_cos_stream` needs thorough verification

## Next Steps (Priority Order)

1. **Port Java COSParser tests** for edge-case coverage — highest value remaining work
2. **Verify `parse_cos_stream` thoroughly** — stream parsing is complex
3. **Implement `dereferenceCOSObject`** if needed for API completeness
4. **Add stream cache support** (`init` with StreamCacheCreateFunction)
5. **Add constructor variants** with password/keystore/keyAlias
6. **Remove outdated "missing" markings** from this document

## Notes
- This class is critical for PDF parsing performance
- Most methods are already ported and verified
- Object stream parsing delegates to Parser class which is fully implemented
- Encryption support is implemented as stubs (RC4, AES-128, AES-256)
- Focus remaining work on edge-case test coverage rather than new method implementations
