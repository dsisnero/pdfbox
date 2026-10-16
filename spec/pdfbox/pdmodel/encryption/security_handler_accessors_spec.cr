require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/SecurityHandler.java
#     isAES/setAES, getEncryptionKey/setEncryptionKey.
module Pdfbox::Pdmodel::Encryption
  describe SecurityHandler do
    it "exposes the AES flag (Java isAES/setAES)" do
      handler = StandardSecurityHandler.new
      handler.aes?.should be_false
      handler.aes = true
      handler.aes?.should be_true
    end

    it "exposes the encryption key (Java getEncryptionKey/setEncryptionKey)" do
      handler = StandardSecurityHandler.new
      handler.encryption_key.should be_nil

      handler.encryption_key = Bytes[1, 2, 3]
      handler.encryption_key.should eq(Bytes[1, 2, 3])

      handler.encryption_key = nil
      handler.encryption_key.should be_nil
    end
  end
end
