require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/PublicKeyProtectionPolicy.java
#     addRecipient/removeRecipient/getRecipientsIterator/getNumberOfRecipients/
#     getDecryptionCertificate/setDecryptionCertificate.
module Pdfbox::Pdmodel::Encryption
  describe PublicKeyProtectionPolicy do
    it "adds, iterates and removes recipients (Java add/removeRecipient/getRecipientsIterator)" do
      policy = PublicKeyProtectionPolicy.new
      r1 = PublicKeyRecipient.new
      r2 = PublicKeyRecipient.new
      policy.add_recipient(r1)
      policy.add_recipient(r2)
      policy.number_of_recipients.should eq(2)

      policy.recipients_iterator.to_a.should eq([r1, r2])

      policy.remove_recipient(r1).should be_true
      policy.number_of_recipients.should eq(1)
      policy.remove_recipient(r1).should be_false
    end

    it "reads and writes the decryption certificate (Java get/setDecryptionCertificate)" do
      policy = PublicKeyProtectionPolicy.new
      policy.decryption_certificate.should be_nil

      policy.decryption_certificate = nil
      policy.decryption_certificate.should be_nil
    end
  end
end
