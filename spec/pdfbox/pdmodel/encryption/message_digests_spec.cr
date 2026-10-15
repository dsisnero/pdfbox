require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/MessageDigests.java
#     getMD5/getSHA1/getSHA256 return the requested digest implementation.
module Pdfbox::Pdmodel::Encryption
  describe MessageDigests do
    it "returns an MD5 digest (Java getMD5)" do
      digest = MessageDigests.get_md5
      digest.update("abc")
      digest.final.hexstring.should eq("900150983cd24fb0d6963f7d28e17f72")
    end

    it "returns a SHA-1 digest (Java getSHA1)" do
      digest = MessageDigests.get_sha1
      digest.update("abc")
      digest.final.hexstring.should eq("a9993e364706816aba3e25717850c26c9cd0d89d")
    end

    it "returns a SHA-256 digest (Java getSHA256)" do
      digest = MessageDigests.get_sha256
      digest.update("abc")
      digest.final.hexstring.should eq("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
    end
  end
end
