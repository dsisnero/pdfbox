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
  type ASN1_INTEGER = Void*
  type BIGNUM = Void*

  # BIO_ctrl command returning the memory BIO's data pointer/length (BIO_get_mem_data).
  BIO_CTRL_INFO = 3

  # PKCS7_encrypt flag: copy content as binary instead of SMIME CRLF conversion.
  PKCS7_BINARY = 0x80

  fun ossl_provider_load = OSSL_PROVIDER_load(libctx : Void*, name : Char*) : Void*
  fun d2i_pkcs12 = d2i_PKCS12(a : PKCS12*, inp : UInt8**, len : Long) : PKCS12
  fun pkcs12_parse = PKCS12_parse(p12 : PKCS12, pass : Char*, pkey : EVP_PKEY*, cert : X509*, ca : Void*) : Int
  fun pkcs12_free = PKCS12_free(a : PKCS12)

  fun d2i_pkcs7 = d2i_PKCS7(a : PKCS7*, inp : UInt8**, len : Long) : PKCS7
  fun pkcs7_decrypt = PKCS7_decrypt(p7 : PKCS7, pkey : EVP_PKEY, cert : X509, data : Bio*, flags : Int) : Int
  fun pkcs7_encrypt = PKCS7_encrypt(certs : Void*, input : Bio*, cipher : EVP_CIPHER, flags : Int) : PKCS7
  fun pkcs7_free = PKCS7_free(a : PKCS7)
  fun i2d_pkcs7 = i2d_PKCS7(a : PKCS7, out : UInt8**) : Int

  fun bio_new_mem_buf = BIO_new_mem_buf(buf : Void*, len : Int) : Bio*
  fun bio_s_mem = BIO_s_mem : BioMethod*
  fun evp_rc2_cbc = EVP_rc2_cbc : EVP_CIPHER

  fun sk_new_null = OPENSSL_sk_new_null : Void*
  fun sk_push = OPENSSL_sk_push(st : Void*, data : Void*) : Int

  fun evp_pkey_free = EVP_PKEY_free(pkey : EVP_PKEY)

  fun x509_get_serial_number = X509_get_serialNumber(x : X509) : ASN1_INTEGER
  fun asn1_integer_to_bn = ASN1_INTEGER_to_BN(ai : ASN1_INTEGER, bn : BIGNUM) : BIGNUM
  fun bn_bn2hex = BN_bn2hex(a : BIGNUM) : Char*
  fun bn_free = BN_free(a : BIGNUM)
  fun crypto_free = CRYPTO_free(addr : Void*, file : Char*, line : Int)
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

  # Formats an OpenSSL `ASN1_INTEGER` as a hexadecimal string (matching Java's
  # `BigInteger.toString(16)`), or `nil` when it is NULL.
  def self.asn1_integer_hex(integer : LibCrypto::ASN1_INTEGER) : String?
    return nil if integer.null?

    bignum = LibCrypto.asn1_integer_to_bn(integer, Pointer(Void).null.as(LibCrypto::BIGNUM))
    return nil if bignum.null?

    begin
      hex = LibCrypto.bn_bn2hex(bignum)
      return nil if hex.null?

      begin
        value = String.new(hex).downcase
        while value.size > 1 && value.starts_with?('0')
          value = value.lchop('0')
        end
        value
      ensure
        LibCrypto.crypto_free(hex.as(Void*), nil, 0)
      end
    ensure
      LibCrypto.bn_free(bignum)
    end
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

    # The certificate's serial number as a lowercase hexadecimal string.
    def certificate_serial_hex : String?
      Crypto.asn1_integer_hex(LibCrypto.x509_get_serial_number(@certificate))
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

      output = LibCrypto.BIO_new(LibCrypto.bio_s_mem)
      if output.null?
        LibCrypto.pkcs7_free(pkcs7)
        return nil
      end

      begin
        result = LibCrypto.pkcs7_decrypt(pkcs7, keystore.private_key, keystore.certificate, output, 0)
        return nil if result == 0

        pointer = Pointer(UInt8).null
        length = LibCrypto.BIO_ctrl(output, LibCrypto::BIO_CTRL_INFO, 0, pointerof(pointer).as(Void*)).to_i32
        data = Bytes.new(length)
        data.copy_from(pointer, length) if length > 0
        data
      ensure
        LibCrypto.pkcs7_free(pkcs7)
        LibCrypto.BIO_free(output)
      end
    end

    # Hexadecimal serial numbers of the recipients embedded in a DER-encoded
    # PKCS#7 EnvelopedData. Used to build the "matches none" diagnostic, mirroring
    # Java's `PublicKeySecurityHandler#appendCertInfo`.
    #
    # OpenSSL does not expose the enveloped recipient issuer/serial, so the
    # minimal CMS DER structure is walked directly:
    #   ContentInfo ::= SEQUENCE { contentType OID, [0] EnvelopedData }
    #   EnvelopedData ::= SEQUENCE { version INTEGER, recipientInfos SET OF
    #                     RecipientInfo, ... }
    #   RecipientInfo ::= SEQUENCE { version INTEGER, issuerAndSerialNumber
    #                     SEQUENCE { issuer Name, serialNumber INTEGER }, ... }
    def self.recipient_serials(recipient_bytes : Bytes) : Array(String)
      serials = [] of String

      _, content_start, _ = tlv(recipient_bytes, 0) || return serials
      # contentType OID
      oid_pos = content_start
      _, _, oid_end = tlv(recipient_bytes, oid_pos) || return serials
      # content [0]
      _, wrapped_start, _ = tlv(recipient_bytes, oid_end) || return serials
      # EnvelopedData SEQUENCE
      _, env_start, _ = tlv(recipient_bytes, wrapped_start) || return serials
      # version INTEGER
      _, _, version_end = tlv(recipient_bytes, env_start) || return serials
      # recipientInfos SET
      _, set_start, set_end = tlv(recipient_bytes, version_end) || return serials

      position = set_start
      while position < set_end
        # RecipientInfo SEQUENCE
        _, ri_start, ri_end = tlv(recipient_bytes, position) || break
        # version INTEGER
        _, _, ri_version_end = tlv(recipient_bytes, ri_start) || break
        # issuerAndSerialNumber SEQUENCE
        _, ias_start, _ = tlv(recipient_bytes, ri_version_end) || break
        # issuer Name SEQUENCE
        _, _, name_end = tlv(recipient_bytes, ias_start) || break
        # serialNumber INTEGER
        if serial_tlv = tlv(recipient_bytes, name_end)
          serials << integer_hex(recipient_bytes[serial_tlv[1], serial_tlv[2] - serial_tlv[1]])
        end
        position = ri_end
      end

      serials
    end

    # Reads a DER TLV at *position*, returning `{tag, content_start, content_end}`.
    private def self.tlv(data : Bytes, position : Int32) : {UInt8, Int32, Int32}?
      return nil if position < 0 || position >= data.size

      tag = data[position]
      cursor = position + 1
      first = data[cursor]? || return nil
      cursor += 1
      length = if first < 0x80
                 first.to_i32
               else
                 count = first & 0x7F
                 value = 0
                 count.times do
                   byte = data[cursor]? || return nil
                   value = (value << 8) | byte
                   cursor += 1
                 end
                 value
               end

      content_start = cursor
      content_end = content_start + length
      return nil if content_end > data.size

      {tag, content_start, content_end}
    end

    # Formats a DER INTEGER's content bytes as a hexadecimal string, stripping
    # leading zeros to match Java's `BigInteger.toString(16)`.
    private def self.integer_hex(content : Bytes) : String
      hex = content.hexstring.downcase
      while hex.size > 1 && hex.starts_with?('0')
        hex = hex.lchop('0')
      end
      hex
    end

    # Encrypts *data* for *certificates* as a DER-encoded PKCS#7 EnvelopedData.
    #
    # The content is encrypted with RC2-CBC and a fresh random key, and the key
    # is wrapped for each recipient certificate, matching Apache PDFBox's
    # `PublicKeySecurityHandler.createDERForRecipient`.
    def self.encrypt(data : Bytes, certificates : Enumerable(LibCrypto::X509)) : Bytes
      Crypto.ensure_providers

      certs = LibCrypto.sk_new_null
      raise Error.new("Could not allocate certificate stack") if certs.null?

      begin
        certificates.each { |certificate| LibCrypto.sk_push(certs, certificate.as(Void*)) }

        input = LibCrypto.bio_new_mem_buf(data.to_unsafe, data.size)
        raise Error.new("Could not allocate input BIO") if input.null?

        begin
          pkcs7 = LibCrypto.pkcs7_encrypt(certs, input, LibCrypto.evp_rc2_cbc, LibCrypto::PKCS7_BINARY)
          raise Error.new("Could not create PKCS#7 EnvelopedData") if pkcs7.null?

          begin
            der_length = LibCrypto.i2d_pkcs7(pkcs7, Pointer(Pointer(UInt8)).null)
            raise Error.new("Could not encode PKCS#7 EnvelopedData") if der_length <= 0

            der = Bytes.new(der_length)
            output = der.to_unsafe
            LibCrypto.i2d_pkcs7(pkcs7, pointerof(output))
            der
          ensure
            LibCrypto.pkcs7_free(pkcs7)
          end
        ensure
          LibCrypto.BIO_free(input)
        end
      ensure
        LibCrypto.sk_free(certs)
      end
    end
  end
end
