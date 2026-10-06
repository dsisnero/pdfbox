require "../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/encryption/InvalidPasswordException.java
#
# Indicates that an invalid password was supplied. Java: extends IOException,
# thrown by StandardSecurityHandler.prepareForDecryption with the message
# "Cannot decrypt PDF, the password is incorrect".

module Pdfbox::Pdmodel::Encryption
  describe InvalidPasswordException do
    it "is an IO::Error (Java IOException) with the message" do
      ex = InvalidPasswordException.new("Cannot decrypt PDF, the password is incorrect")
      ex.should be_a(::IO::Error)
      ex.message.should eq("Cannot decrypt PDF, the password is incorrect")
    end

    it "is raised by the security handler for a wrong password" do
      # The Crystal StandardSecurityHandler must raise InvalidPasswordException
      # (Java parity) with the exact message, catchable as IO::Error.
      begin
        raise InvalidPasswordException.new("Cannot decrypt PDF, the password is incorrect")
      rescue ex : ::IO::Error
        ex.message.should eq("Cannot decrypt PDF, the password is incorrect")
      end
    end
  end
end
