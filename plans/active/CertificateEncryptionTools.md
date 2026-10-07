# Port Plan: Certificate-Based Encryption/Decryption Tools

**Goal:** `pdfbox encrypt --certFile` and `pdfbox decrypt --keyStore/--alias`
use X.509 certificate key material, matching Java `Encrypt`/`Decrypt`.

## Source of truth

- `vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/Encrypt.java` (`certFileList` branch)
- `vendor/pdfbox/tools/src/main/java/org/apache/pdfbox/tools/Decrypt.java` (keyStore/alias branch)
- Crypto behavior: `TestPublicKeyEncryption.java` (already green in
  `spec/pdfbox/encryption/public_key_encryption_spec.cr`)

## Steps (red-green)

1. [x] `Encrypt` tool: parse `--certFile` into `OpenSSL::X509::Certificate`,
   build `PublicKeyProtectionPolicy` + `PublicKeyRecipient`, set key length,
   `document.protect(policy)` + `save` (mirrors Java's single-recipient loop).
2. [x] `Decrypt` tool: open the PKCS#12 keystore and call
   `Loader.load_pdf(data, password, key_store_io, alias)`; keep password-only path.
3. [x] Also mirror Java's "Document is already encrypted." guard in `Encrypt`.
4. [x] Specs: `spec/tools/encrypt_spec.cr` (cert file protects document;
   round-trip reload with keystore extracts text), `spec/tools/decrypt_spec.cr`
   (keystore-based decrypt removes encryption).
5. [x] Run gates: `crystal tool format --check src spec`, `ameba src spec`,
   `crystal spec`; update parity.md + inventory.

## Notes

- Java `Encrypt` creates one `PublicKeyRecipient`, sets the certificate in the
  loop, and adds the same recipient reference per certificate file. Port the
  same semantics (single-cert case is the tested path).
- Certificate files may be DER (`.der`, as in the Java test resources) or PEM.
- `Loader.load_pdf(bytes, password, key_store, alias)` already threads the
  PKCS#12 store through the parser (public-key decryption port).
