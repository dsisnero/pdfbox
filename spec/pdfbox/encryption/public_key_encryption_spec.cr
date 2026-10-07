# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Port of org.apache.pdfbox.encryption.TestPublicKeyEncryption.

require "../../spec_helper"

private def encryption_resource(filename : String) : String
  "spec/resources/pdfbox/encryption/#{filename}"
end

private def certificate_from(resource : String) : OpenSSL::X509::Certificate
  bytes = File.read(encryption_resource(resource)).to_slice
  cert, _ = OpenSSL::X509::Certificate.from_der?(bytes)
  raise "Could not read certificate #{resource}" unless cert

  cert
end

# Mirrors TestPublicKeyEncryption#getRecipient.
private def get_recipient(resource : String, permission : Pdfbox::Pdmodel::Encryption::AccessPermission) : Pdfbox::Pdmodel::Encryption::PublicKeyRecipient
  recipient = Pdfbox::Pdmodel::Encryption::PublicKeyRecipient.new
  recipient.permissions = permission
  recipient.x509_certificate = certificate_from(resource)
  recipient
end

# Mirrors Loader.loadPDF(source, password, keyStore, alias): the document
# password doubles as the PKCS#12 store password.
private def load_public_key_from(path : String, password : String,
                                 key_store : String, alias_name : String? = nil) : Pdfbox::Pdmodel::Document
  File.open(encryption_resource(key_store)) do |key_store_io|
    Pdfbox::Loader.load_pdf(File.read(path).to_slice, password, key_store_io, alias_name)
  end
end

private def load_public_key_encrypted(filename : String, password : String,
                                      key_store : String, alias_name : String? = nil) : Pdfbox::Pdmodel::Document
  load_public_key_from(encryption_resource(filename), password, key_store, alias_name)
end

private def public_key_handler(doc : Pdfbox::Pdmodel::Document) : Pdfbox::Pdmodel::Encryption::SecurityHandler
  doc.encryption.try(&.security_handler) ||
    raise "document has no security handler"
end

private def permission_for(permission2 : Bool) : Pdfbox::Pdmodel::Encryption::AccessPermission
  permission = Pdfbox::Pdmodel::Encryption::AccessPermission.new
  permission.can_assemble_document = false
  permission.can_extract_content = false
  permission.can_extract_for_accessibility = true
  permission.can_fill_in_form = false
  permission.can_modify = false
  permission.can_modify_annotations = false
  permission.can_print = permission2
  permission.can_print_faithful = false
  permission
end

KEY_LENGTHS = [40, 128, 256]

describe Pdfbox::Pdmodel::Encryption do
  test_results_dir = "target/test-output/crypto"

  before_all do
    Dir.mkdir_p(test_results_dir)
    # Skip JCE unlimited strength check - not applicable to Crystal.
  end

  permission1 = permission_for(false)
  permission2 = permission_for(true)

  recipient1 = get_recipient("test1.der", permission1)
  recipient2 = get_recipient("test2.der", permission2)

  password1 = "test1"
  password2 = "test2"

  key_store1 = "test1.pfx"
  key_store2 = "test2.pfx"

  # Mirrors TestPublicKeyEncryption#reload: reopens *path* with the given
  # keystore and asserts the extracted text and producer are unchanged.
  reload = ->(path : String, password : String, key_store : String, text : String, producer : String?) do
    doc = load_public_key_from(path, password, key_store)
    begin
      Pdfbox::Text::PDFTextStripper.new.get_text(doc).should eq(text)
      doc.document_information.try(&.producer).should eq(producer)
      doc
    rescue ex
      doc.close
      raise ex
    end
  end

  KEY_LENGTHS.each do |key_length|
    describe "with key length #{key_length}" do
      # Port of TestPublicKeyEncryption#testProtection.
      it "testProtection" do
        document = Pdfbox::Loader.load_pdf(File.read(encryption_resource("test.pdf")).to_slice)
        text = Pdfbox::Text::PDFTextStripper.new.get_text(document)
        producer = document.document_information.try(&.producer)

        policy = Pdfbox::Pdmodel::Encryption::PublicKeyProtectionPolicy.new
        policy.add_recipient(recipient1)
        policy.encryption_key_length = key_length
        document.protect(policy)
        path = File.join(test_results_dir, "testProtection-#{key_length}bit.pdf")
        document.save(path)
        document.close

        encrypted_doc = reload.call(path, password1, key_store1, text, producer)
        begin
          encrypted_doc.encrypted?.should be_true
          permission = encrypted_doc.current_access_permission
          permission.can_assemble_document?.should be_false
          permission.can_extract_content?.should be_false
          permission.can_extract_for_accessibility?.should be_true
          permission.can_fill_in_form?.should be_false
          permission.can_modify?.should be_false
          permission.can_modify_annotations?.should be_false
          permission.can_print?.should be_false
          permission.can_print_faithful?.should be_false
        ensure
          encrypted_doc.close
        end
      end

      # Port of TestPublicKeyEncryption#testProtectionError.
      it "testProtectionError" do
        document = Pdfbox::Loader.load_pdf(File.read(encryption_resource("test.pdf")).to_slice)
        policy = Pdfbox::Pdmodel::Encryption::PublicKeyProtectionPolicy.new
        policy.add_recipient(recipient1)
        policy.encryption_key_length = key_length
        document.protect(policy)
        path = File.join(test_results_dir, "testProtectionError-#{key_length}bit.pdf")
        document.save(path)
        document.close

        expect_raises(::IO::Error, "serial-#: rid 2 vs. cert 3") do
          load_public_key_from(path, password2, key_store2)
        end
      end

      # Port of TestPublicKeyEncryption#testMultipleRecipients.
      it "testMultipleRecipients" do
        document = Pdfbox::Loader.load_pdf(File.read(encryption_resource("test.pdf")).to_slice)
        text = Pdfbox::Text::PDFTextStripper.new.get_text(document)
        producer = document.document_information.try(&.producer)

        policy = Pdfbox::Pdmodel::Encryption::PublicKeyProtectionPolicy.new
        policy.add_recipient(recipient1)
        policy.add_recipient(recipient2)
        policy.encryption_key_length = key_length
        document.protect(policy)
        path = File.join(test_results_dir, "testMultipleRecipients-#{key_length}bit.pdf")
        document.save(path)
        document.close

        # open first time
        encrypted_doc1 = reload.call(path, password1, key_store1, text, producer)
        begin
          permission = encrypted_doc1.current_access_permission
          permission.can_assemble_document?.should be_false
          permission.can_extract_content?.should be_false
          permission.can_extract_for_accessibility?.should be_true
          permission.can_modify?.should be_false
          permission.can_print?.should be_false
        ensure
          encrypted_doc1.close
        end

        # open second time
        encrypted_doc2 = reload.call(path, password2, key_store2, text, producer)
        begin
          permission = encrypted_doc2.current_access_permission
          permission.can_assemble_document?.should be_false
          permission.can_extract_content?.should be_false
          permission.can_extract_for_accessibility?.should be_true
          permission.can_modify?.should be_false
          permission.can_print?.should be_true
        ensure
          encrypted_doc2.close
        end
      end
    end
  end

  # PDFBOX-4421: read a file encrypted with AES128 by another tool, with a
  # missing /Length entry in the encryption dictionary.
  it "testReadPubkeyEncryptedAES128" do
    doc = load_public_key_encrypted("AESkeylength128.pdf", "w!z%C*F-JaNdRgUk",
      "PDFBOX-4421-keystore.pfx", "testnutzer")
    begin
      handler = public_key_handler(doc)
      handler.should be_a(Pdfbox::Pdmodel::Encryption::PublicKeySecurityHandler)
      handler.key_length.should eq(128)
      Pdfbox::Text::PDFTextStripper.new.get_text(doc).strip.should eq("Key length: 128")
    ensure
      doc.close
    end
  end

  # PDFBOX-4421: read a file encrypted with AES256 by another tool, with a
  # missing /Length entry in the encryption dictionary.
  it "testReadPubkeyEncryptedAES256" do
    doc = load_public_key_encrypted("AESkeylength256.pdf", "w!z%C*F-JaNdRgUk",
      "PDFBOX-4421-keystore.pfx", "testnutzer")
    begin
      handler = public_key_handler(doc)
      handler.should be_a(Pdfbox::Pdmodel::Encryption::PublicKeySecurityHandler)
      handler.key_length.should eq(256)
      Pdfbox::Text::PDFTextStripper.new.get_text(doc).strip.should eq("Key length: 256")
    ensure
      doc.close
    end
  end

  # PDFBOX-5249: read a file encrypted with AES128 with exposed Metadata.
  it "testReadPubkeyEncryptedAES128withMetadataExposed" do
    doc = load_public_key_encrypted("AES128ExposedMeta.pdf", "",
      "PDFBOX-5249.p12", "test")
    begin
      handler = public_key_handler(doc)
      handler.should be_a(Pdfbox::Pdmodel::Encryption::PublicKeySecurityHandler)
      handler.key_length.should eq(128)
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.get_text(doc).strip.should eq("AES key length: 128\nwith exposed Metadata")
    ensure
      doc.close
    end
  end

  # PDFBOX-5249: read a file encrypted with AES256 with exposed Metadata.
  it "testReadPubkeyEncryptedAES256withMetadataExposed" do
    doc = load_public_key_encrypted("AES256ExposedMeta.pdf", "",
      "PDFBOX-5249.p12", "test")
    begin
      handler = public_key_handler(doc)
      handler.should be_a(Pdfbox::Pdmodel::Encryption::PublicKeySecurityHandler)
      handler.key_length.should eq(256)
      stripper = Pdfbox::Text::PDFTextStripper.new
      stripper.line_separator = "\n"
      stripper.get_text(doc).strip.should eq("AES key length: 256 \nwith exposed Metadata")
    ensure
      doc.close
    end
  end
end
