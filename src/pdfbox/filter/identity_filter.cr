module Pdfbox::Filter
  # Identity filter (PDF spec): leaves data unchanged.
  class IdentityFilter < Filter
    def decode(encoded : Bytes) : Bytes
      encoded.dup
    end

    def encode(input : Bytes) : Bytes
      input.dup
    end
  end
end
