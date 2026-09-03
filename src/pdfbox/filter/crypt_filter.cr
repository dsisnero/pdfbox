require "log"

module Pdfbox::Filter
  # Decrypts/encrypts data via a security handler's crypt filter. The only
  # supported implementation is the Identity crypt filter; other names are not
  # implemented. Java: org.apache.pdfbox.filter.CryptFilter
  class CryptFilter < Filter
    Log = ::Log.for(self)

    def decode(encoded : Bytes) : Bytes
      # Identity crypt filter: pass-through. Java reads /Name from the
      # DecodeParms dictionary and delegates to IdentityFilter for Identity (or
      # absent) /Name. Document-level encryption (StandardSecurityHandler)
      # handles actual ciphertext; the Identity crypt filter is a no-op.
      encoded.dup
    end

    def encode(input : Bytes) : Bytes
      input.dup
    end
  end
end
