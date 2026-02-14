# PDF Encryption Porting Status

This document tracks the porting status of encryption-related classes from Apache PDFBox (Java) to Crystal.

## PDEncryption.java → encryption.cr (PDEncryption class)

### Original Java Methods vs Crystal Method Names

| Original Java Method | Crystal Method Name | Notes (Idiom Changes) | Test Status | Implementation Status |
|----------------------|---------------------|------------------------|-------------|------------------------|
| `public PDEncryption()` | `def initialize(dictionary : Pdfbox::Cos::Dictionary? = nil)` | Constructor matches Java | ❌ Not tested | ✅ Implemented |
| `public PDEncryption(COSDictionary dictionary)` | `def initialize(dictionary : Pdfbox::Cos::Dictionary? = nil)` | Combined with default constructor | ❌ Not tested | ✅ Implemented |
| `public SecurityHandler<ProtectionPolicy> getSecurityHandler() throws IOException` | `def security_handler : SecurityHandler` | Snake case, raises IO::Error instead of throws | ❌ Not tested | ⚠️ Stub implemented |
| `public void setSecurityHandler(SecurityHandler<ProtectionPolicy> securityHandler)` | `property security_handler : SecurityHandler?` | Crystal property, not setter | ❌ Not tested | ✅ Property exists |
| `public boolean hasSecurityHandler()` | `def has_security_handler? : Bool` | Snake case with `?` suffix | ❌ Not tested | ✅ Implemented |
| `public COSDictionary getCOSObject()` | `def dictionary : Pdfbox::Cos::Dictionary` | Renamed to `dictionary` (Crystal idiom) | ❌ Not tested | ✅ Implemented |
| `public void setFilter(String filter)` | `def filter=(filter : String) : String` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public final String getFilter()` | `def filter : String` | Snake case getter | ✅ Tested in specs | ✅ Implemented |
| `public String getSubFilter()` | `def sub_filter : String?` | Snake case, returns nil-able | ✅ Tested in specs | ✅ Implemented |
| `public void setSubFilter(String subfilter)` | `def sub_filter=(subfilter : String) : String` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public void setVersion(int version)` | `def version=(version : Int32) : Int32` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public int getVersion()` | `def version : Int32` | Snake case getter | ✅ Tested in specs | ✅ Implemented |
| `public void setLength(int length)` | `def length=(length : Int32) : Int32` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public int getLength()` | `def length : Int32` | Snake case getter | ✅ Tested in specs | ✅ Implemented |
| `public void setRevision(int revision)` | `def revision=(revision : Int32) : Int32` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public int getRevision()` | `def revision : Int32` | Snake case getter | ✅ Tested in specs | ✅ Implemented |
| `public void setOwnerKey(byte[] o) throws IOException` | `def owner_key=(o : Bytes) : Bytes` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public byte[] getOwnerKey() throws IOException` | `def owner_key : Bytes?` | Snake case, returns `Bytes?` | ✅ Tested in specs | ✅ Implemented |
| `public void setUserKey(byte[] u) throws IOException` | `def user_key=(u : Bytes) : Bytes` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public byte[] getUserKey() throws IOException` | `def user_key : Bytes?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setOwnerEncryptionKey(byte[] oe) throws IOException` | `def owner_encryption_key=(oe : Bytes) : Bytes` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public byte[] getOwnerEncryptionKey() throws IOException` | `def owner_encryption_key : Bytes?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setUserEncryptionKey(byte[] ue) throws IOException` | `def user_encryption_key=(ue : Bytes) : Bytes` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public byte[] getUserEncryptionKey() throws IOException` | `def user_encryption_key : Bytes?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setPermissions(int permissions)` | `def permissions=(permissions : Int32) : Int32` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public int getPermissions()` | `def permissions : Int32` | Snake case getter | ✅ Tested in specs | ✅ Implemented |
| `public boolean isEncryptMetaData()` | `def encrypt_metadata? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public void setRecipients(byte[][] recipients) throws IOException` | `def recipients=(recipients : Array(Bytes)) : Array(Bytes)` | Property setter (Crystal idiom) | ❌ Not tested | ⚠️ Stub |
| `public int getRecipientsLength()` | `def recipients_length : Int32` | Snake case | ❌ Not tested | ⚠️ Stub |
| `public COSString getRecipientStringAt(int i)` | `def recipient_string_at(i : Int32) : Pdfbox::Cos::String?` | Snake case | ❌ Not tested | ⚠️ Stub |
| `public PDCryptFilterDictionary getStdCryptFilterDictionary()` | `def std_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?` | Snake case | ❌ Not tested | ⚠️ Stub |
| `public PDCryptFilterDictionary getDefaultCryptFilterDictionary()` | `def default_crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?` | Snake case | ❌ Not tested | ⚠️ Stub |
| `public PDCryptFilterDictionary getCryptFilterDictionary(COSName cryptFilterName)` | `def crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary?` | Snake case | ❌ Not tested | ⚠️ Stub |
| `public void setCryptFilterDictionary(COSName cryptFilterName, PDCryptFilterDictionary cryptFilterDictionary)` | `def assign_crypt_filter_dictionary(crypt_filter_name : Pdfbox::Cos::Name, crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Nil` | Snake case, renamed to avoid conflict with property setter | ❌ Not tested | ⚠️ Stub |
| `public void setStdCryptFilterDictionary(PDCryptFilterDictionary cryptFilterDictionary)` | `def std_crypt_filter_dictionary=(crypt_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary` | Property setter (Crystal idiom) | ❌ Not tested | ⚠️ Stub |
| `public void setDefaultCryptFilterDictionary(PDCryptFilterDictionary defaultFilterDictionary)` | `def default_crypt_filter_dictionary=(default_filter_dictionary : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary) : Pdfbox::Pdmodel::Encryption::PDCryptFilterDictionary` | Property setter (Crystal idiom) | ❌ Not tested | ⚠️ Stub |
| `public COSName getStreamFilterName()` | `def stream_filter_name : Pdfbox::Cos::Name?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setStreamFilterName(COSName streamFilterName)` | `def stream_filter_name=(stream_filter_name : Pdfbox::Cos::Name) : Pdfbox::Cos::Name` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public COSName getStringFilterName()` | `def string_filter_name : Pdfbox::Cos::Name?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setStringFilterName(COSName stringFilterName)` | `def string_filter_name=(string_filter_name : Pdfbox::Cos::Name) : Pdfbox::Cos::Name` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public void setPerms(byte[] perms) throws IOException` | `def perms=(perms : Bytes) : Bytes` | Property setter (Crystal idiom) | ✅ Tested in specs | ✅ Implemented |
| `public byte[] getPerms() throws IOException` | `def perms : Bytes?` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void removeV45filters()` | `def remove_v45_filters : Nil` | Snake case | ❌ Not tested | ⚠️ Stub |

### Constants
| Original Java Constant | Crystal Constant | Value |
|------------------------|-----------------|-------|
| `VERSION0_UNDOCUMENTED_UNSUPPORTED` | `VERSION0_UNDOCUMENTED_UNSUPPORTED` | `0` |
| `VERSION1_40_BIT_ALGORITHM` | `VERSION1_40_BIT_ALGORITHM` | `1` |
| `VERSION2_VARIABLE_LENGTH_ALGORITHM` | `VERSION2_VARIABLE_LENGTH_ALGORITHM` | `2` |
| `VERSION3_UNPUBLISHED_ALGORITHM` | `VERSION3_UNPUBLISHED_ALGORITHM` | `3` |
| `VERSION4_SECURITY_HANDLER` | `VERSION4_SECURITY_HANDLER` | `4` |
| `DEFAULT_NAME` | `DEFAULT_NAME` | `"Standard"` |
| `DEFAULT_LENGTH` | `DEFAULT_LENGTH` | `40` |
| `DEFAULT_VERSION` | `DEFAULT_VERSION` | `VERSION0_UNDOCUMENTED_UNSUPPORTED` |

## AccessPermission.java → encryption.cr (AccessPermission class)

### Original Java Methods vs Crystal Method Names

| Original Java Method | Crystal Method Name | Notes (Idiom Changes) | Test Status | Implementation Status |
|----------------------|---------------------|------------------------|-------------|------------------------|
| `public AccessPermission()` | `def initialize(@owner_permission : Bool = true)` | Default parameter | ✅ Tested in specs | ✅ Implemented |
| `public AccessPermission(int permissions)` | `def initialize(permissions : Int32)` | Not yet implemented | ❌ Not tested | ❌ Missing |
| `public boolean isOwnerPermission()` | `def owner_permission? : Bool` | Snake case with `?` suffix | ❌ Not tested | ✅ Implemented |
| `public boolean isReadOnly()` | `def read_only? : Bool` | Snake case with `?` suffix | ❌ Not tested | ✅ Implemented |
| `public void setReadOnly()` | `def set_read_only : Nil` | Snake case | ❌ Not tested | ✅ Implemented |
| `public boolean canAssembleDocument()` | `def can_assemble_document? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canExtractContent()` | `def can_extract_content? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canExtractForAccessibility()` | `def can_extract_for_accessibility? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canFillInForm()` | `def can_fill_in_form? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canModify()` | `def can_modify? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canModifyAnnotations()` | `def can_modify_annotations? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canPrint()` | `def can_print? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public boolean canPrintFaithful()` | `def can_print_faithful? : Bool` | Snake case with `?` suffix | ✅ Tested in specs | ✅ Implemented |
| `public void setCanAssembleDocument(boolean canAssembleDocument)` | `def set_can_assemble_document(value : Bool) : Nil` | Snake case (Java-style kept for tests) | ✅ Tested in specs | ✅ Implemented |
| `public void setCanExtractContent(boolean canExtractContent)` | `def set_can_extract_content(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanExtractForAccessibility(boolean canExtractForAccessibility)` | `def set_can_extract_for_accessibility(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanFillInForm(boolean canFillInForm)` | `def set_can_fill_in_form(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanModify(boolean canModify)` | `def set_can_modify(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanModifyAnnotations(boolean canModifyAnnotations)` | `def set_can_modify_annotations(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanPrint(boolean canPrint)` | `def set_can_print(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void setCanPrintFaithful(boolean canPrintFaithful)` | `def set_can_print_faithful(value : Bool) : Nil` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public int getPermissionBytes()` | `def permission_bytes : Int32` | Snake case | ❌ Not tested | ❌ Missing |
| `public boolean hasAnyRevision3PermissionSet()` | `def has_any_revision3_permission_set? : Bool` | Snake case with `?` suffix | ❌ Not tested | ❌ Missing |

**Note:** Java-style setters (`set_can_*`) are kept for test compatibility but violate Crystal naming conventions. Ameba warning suppressed with documentation instead of disable directive.

## StandardSecurityHandler.java → encryption.cr (StandardSecurityHandler class)

### Original Java Methods vs Crystal Method Names

| Original Java Method | Crystal Method Name | Notes (Idiom Changes) | Test Status | Implementation Status |
|----------------------|---------------------|------------------------|-------------|------------------------|
| `public StandardSecurityHandler()` | `def initialize(@policy : StandardProtectionPolicy = StandardProtectionPolicy.new)` | Default parameter | ❌ Not tested | ✅ Partial |
| `public StandardSecurityHandler(StandardProtectionPolicy standardProtectionPolicy)` | `def initialize(@policy : StandardProtectionPolicy = StandardProtectionPolicy.new)` | Combined with default | ❌ Not tested | ✅ Partial |
| `public void prepareForDecryption(PDEncryption encryption, COSArray documentIDArray, DecryptionMaterial decryptionMaterial)` | `def prepare_for_decryption(encryption : PDEncryption, document_id : Bytes?, material : DecryptionMaterial) : Nil` | Snake case, `Bytes?` instead of `COSArray` | ✅ Tested in specs | ⚠️ Stub |
| `public AccessPermission getCurrentAccessPermission()` | `def current_access_permission : AccessPermission` | Snake case | ✅ Tested in specs | ✅ Implemented |
| `public void prepareDocumentForEncryption(PDDocument document)` | `def prepare_document_for_encryption(document : Pdfbox::Pdmodel::Document) : Nil` | Snake case | ❌ Not tested | ❌ Missing |
| `public boolean isOwnerPassword(byte[] ownerPassword, byte[] user, byte[] owner, int permissions, byte[] id, int encRevision, int keyLengthInBytes, boolean encryptMetadata)` | `def is_owner_password?(owner_password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool` | Snake case with `?` suffix | ❌ Not tested | ❌ Missing |
| `public boolean isUserPassword(byte[] password, byte[] user, byte[] owner, int permissions, byte[] id, int encRevision, int keyLengthInBytes, boolean encryptMetadata)` | `def is_user_password?(password : Bytes, user : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bool` | Snake case with `?` suffix | ❌ Not tested | ❌ Missing |
| `public byte[] getUserPassword(byte[] ownerPassword, byte[] owner, int encRevision, int length)` | `def user_password(owner_password : Bytes, owner : Bytes, enc_revision : Int32, length : Int32) : Bytes` | Snake case | ❌ Not tested | ❌ Missing |
| `public byte[] computeEncryptedKey(byte[] password, byte[] o, byte[] u, byte[] oe, byte[] ue, int permissions, byte[] id, int encRevision, int keyLengthInBytes, boolean encryptMetadata, boolean isOwnerPassword)` | `def compute_encrypted_key(password : Bytes, o : Bytes, u : Bytes, oe : Bytes?, ue : Bytes?, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool, is_owner_password : Bool) : Bytes` | Snake case | ❌ Not tested | ❌ Missing |
| `public byte[] computeUserPassword(byte[] password, byte[] owner, int permissions, byte[] id, int encRevision, int keyLengthInBytes, boolean encryptMetadata)` | `def compute_user_password(password : Bytes, owner : Bytes, permissions : Int32, id : Bytes, enc_revision : Int32, key_length_in_bytes : Int32, encrypt_metadata : Bool) : Bytes` | Snake case | ❌ Not tested | ❌ Missing |
| `public byte[] computeOwnerPassword(byte[] ownerPassword, byte[] userPassword, int encRevision, int length)` | `def compute_owner_password(owner_password : Bytes, user_password : Bytes, enc_revision : Int32, length : Int32) : Bytes` | Snake case | ❌ Not tested | ❌ Missing |

### Constants
| Original Java Constant | Crystal Constant | Value |
|------------------------|-----------------|-------|
| `FILTER` | `FILTER` | `"Standard"` |
| `PROTECTION_POLICY_CLASS` | ❌ Missing | `StandardProtectionPolicy.class` |
| `REVISION_2` through `REVISION_6` | ❌ Missing | `2` through `6` |
| `ENCRYPT_PADDING` | ❌ Missing | 32-byte array |
| `HASHES_2B` | ❌ Missing | `["SHA-256", "SHA-384", "SHA-512"]` |

## Other Encryption Classes

### StandardProtectionPolicy
| Original Java Method | Crystal Method Name | Status |
|----------------------|---------------------|---------|
| `public StandardProtectionPolicy(String ownerPassword, String userPassword, AccessPermission permissions)` | ❌ Missing | ❌ Missing |
| `public String getOwnerPassword()` | ❌ Missing | ❌ Missing |
| `public String getUserPassword()` | ❌ Missing | ❌ Missing |
| `public AccessPermission getPermissions()` | ❌ Missing | ❌ Missing |
| `public int getEncryptionKeyLength()` | `def length : Int32` | ✅ Implemented |

### DecryptionMaterial Classes
| Class | Status |
|-------|---------|
| `StandardDecryptionMaterial` | ✅ Basic implementation |
| `PublicKeyDecryptionMaterial` | ✅ Basic implementation |

### SecurityHandlerFactory
| Original Java Method | Crystal Method Name | Status |
|----------------------|---------------------|---------|
| `public static SecurityHandlerFactory getInstance()` | `def self.instance : SecurityHandlerFactory` | ✅ Implemented |
| `public SecurityHandler newSecurityHandlerForFilter(String name)` | `def new_security_handler_for_filter(name : String) : SecurityHandler?` | ✅ Implemented |

## Porting Notes

### Naming Conventions Applied
1. **CamelCase → snake_case**: `getFilter()` → `filter`, `isEncryptMetaData()` → `encrypt_metadata?`
2. **Boolean getters with `?` suffix**: `isEncryptMetaData()` → `encrypt_metadata?`
3. **Setter methods**: `setFilter()` → `set_filter` (snake_case)
4. **Acronyms**: Treat as words: `getCOSObject()` → `dictionary` (renamed for clarity)
5. **Arrays**: `byte[]` → `Bytes` (alias for `Slice(UInt8)`)
6. **Exceptions**: `throws IOException` → raises `IO::Error` or returns `nil`/`?` type

### Ameba Compliance
- Java-style setters (`set_can_*`) kept for test compatibility but documented
- All Crystal methods follow snake_case naming
- Boolean methods use `?` suffix
- No `ameba:disable` directives used

### Test Coverage
- **Symmetric Key Encryption Tests**: 7 test methods ported, 1 currently failing (expected)
- **Public Key Encryption Tests**: 13 test methods ported, all pending implementation
- Test resources (PDFs, certificates, keystores) copied to `spec/resources/pdfbox/encryption/`

### Implementation Priority
1. **High**: `StandardSecurityHandler.prepare_for_decryption` for revision 2 (40-bit RC4)
2. **High**: `PDEncryption` getters/setters for keys (`owner_key`, `user_key`, etc.)
3. **Medium**: Encryption algorithms (RC4, MD5, SHA)
4. **Low**: Public key encryption support

## Next Steps
1. Create subagents to implement missing methods with corresponding tests
2. Start with `StandardSecurityHandler.prepare_for_decryption` and basic RC4/MD5
3. Ensure 1:1 method coverage as documented above
4. Update status table as implementation progresses