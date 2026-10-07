require "openssl"

# Low-level OpenSSL bindings and helpers for PKCS#12 keystores and PKCS#7/CMS
# EnvelopedData, used by the public key security handler.
#
# Crystal's bundled OpenSSL bindings do not expose the RSA/PKCS#7/PKCS#12 entry
# points, so they are declared here. They reuse the `LibCrypto` link already
# configured by `openssl/lib_crypto`.
lib LibCrypto
  type PKCS12 = Void*
  type PKCS7 = Void*
  type EVP_PKEY = Void*

  fun ossl_provider_load = OSSL_PROVIDER_load(libctx : Void*, name : Char*) : Void*
  fun d2i_pkcs12 = d2i_PKCS12(a : PKCS12*, inp : UInt8**, len : Long) : PKCS12
  fun pkcs12_parse = PKCS12_parse(p12 : PKCS12, pass : Char*, pkey : EVP_PKEY*, cert : X509*, ca : Void*) : Int
  fun pkcs12_free = PKCS12_free(a : PKCS12)

  fun d2i_pkcs7 = d2i_PKCS7(a : PKCS7*, inp : UInt8**, len : Long) : PKCS7
  fun pkcs7_decrypt = PKCS7_decrypt(p7 : PKCS7, pkey : EVP_PKEY, cert : X509, data : Bio*, flags : Int) : Int
  fun pkcs7_free = PKCS7_free(a : PKCS7)

  fun evp_pkey_free = EVP_PKEY_free(pkey : EVP_PKEY)
end

module Pdfbox::Crypto
  # Raised when a PKCS#12 keystore cannot be decoded or parsed.
  class Error < ::Exception
  end

  @@providers_loaded = false

  # Loads the OpenSSL `default` and `legacy` providers.
  #
  # The legacy provider is required to decrypt PKCS#12 keystores that use the
  # RC2/3DES PBE algorithms commonly produced by the JDK `keytool`. Calling this
  # more than once is a no-op.
  def self.ensure_providers : Nil
    return if @@providers_loaded

    LibCrypto.ossl_provider_load(nil, "default")
    LibCrypto.ossl_provider_load(nil, "legacy")
    @@providers_loaded = true
  end

  # A decoded PKCS#12 keystore holding a private key and its certificate.
  class PKCS12
    getter private_key : LibCrypto::EVP_PKEY
    getter certificate : LibCrypto::X509

    # Decodes *data* and extracts the private key and certificate using
    # *password* (the keystore password).
    def initialize(data : Bytes, password : String)
      Crypto.ensure_providers

      input = data.to_unsafe
      p12 = LibCrypto.d2i_pkcs12(nil, pointerof(input), data.size.to_i64)
      raise Error.new("Could not decode PKCS#12 keystore") if p12.null?

      private_key = Pointer(Void).null.as(LibCrypto::EVP_PKEY)
      certificate = Pointer(Void).null.as(LibCrypto::X509)
      result = LibCrypto.pkcs12_parse(p12, password, pointerof(private_key), pointerof(certificate), nil)
      LibCrypto.pkcs12_free(p12)
      raise Error.new("Could not parse PKCS#12 keystore (wrong password?)") if result == 0

      @private_key = private_key
      @certificate = certificate
    end

    def finalize
      LibCrypto.evp_pkey_free(@private_key) unless @private_key.null?
      LibCrypto.x509_free(@certificate) unless @certificate.null?
    end
  end

  # PKCS#7 / CMS EnvelopedData helpers.
  module PKCS7
    # Decrypts a DER-encoded PKCS#7 EnvelopedData *recipient_bytes* using the
    # private key and certificate in *keystore*.
    #
    # Returns the decrypted content, or `nil` when the certificate matches none
    # of the enveloped recipients.
    def self.decrypt(recipient_bytes : Bytes, keystore : PKCS12) : Bytes?
      input = recipient_bytes.to_unsafe
      pkcs7 = LibCrypto.d2i_pkcs7(nil, pointerof(input), recipient_bytes.size.to_i64)
      return nil if pkcs7.null?

      output = ::IO::Memory.new
      bio = OpenSSL::BIO.new(output)
      result = LibCrypto.pkcs7_decrypt(pkcs7, keystore.private_key, keystore.certificate, bio.to_unsafe, 0)
      LibCrypto.pkcs7_free(pkcs7)
      return nil if result == 0

      output.to_slice
    end
  end
end
