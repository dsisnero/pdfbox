require "../spec_helper"
require "../../src/tools"

describe Tools::Decrypt do
  encryption_dir = SpecPaths.resolve("spec/resources/pdfbox/encryption")

  it "reports missing input file" do
    err = IO::Memory.new
    dec = Tools::Decrypt.new(IO::Memory.new, err)
    result = dec.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "loads an encrypted document with the owner password" do
    pdf_path = File.join(encryption_dir, "PasswordSample-40bit.pdf")
    if File.exists?(pdf_path)
      document = Pdfbox::Loader.load_pdf(pdf_path, "owner")
      document.encryption.should_not be_nil
      document.current_access_permission.owner_permission?.should be_true
      document.close
    end
  end

  it "loads an encrypted document with the user password" do
    pdf_path = File.join(encryption_dir, "PasswordSample-40bit.pdf")
    if File.exists?(pdf_path)
      document = Pdfbox::Loader.load_pdf(pdf_path, "user")
      document.encryption.should_not be_nil
      document.close
    end
  end

  it "decrypts a document and saves it without encryption" do
    pdf_path = File.join(encryption_dir, "PasswordSample-40bit.pdf")
    if File.exists?(pdf_path)
      out_path = File.expand_path("../../../temp/decrypted_test.pdf", __DIR__)
      Dir.mkdir_p(File.dirname(out_path))

      dec = Tools::Decrypt.new(IO::Memory.new, IO::Memory.new)
      result = dec.call(["-i", pdf_path, "-o", out_path, "--password", "owner"])
      result.should eq(0)

      reloaded = Pdfbox::Loader.load_pdf(out_path)
      reloaded.encryption.should be_nil
      reloaded.close

      File.delete(out_path) if File.exists?(out_path)
    end
  end

  it "rejects incorrect password" do
    pdf_path = File.join(encryption_dir, "PasswordSample-40bit.pdf")
    if File.exists?(pdf_path)
      expect_raises(Exception) do
        Pdfbox::Loader.load_pdf(pdf_path, "wrongpassword")
      end
    end
  end

  it "decrypts a certificate-encrypted document using a keystore" do
    cert_path = File.join(encryption_dir, "test1.der")
    keystore_path = File.join(encryption_dir, "test1.pfx")
    encrypted_path = "temp/test_cert_for_decrypt.pdf"
    decrypted_path = "temp/test_cert_decrypted.pdf"
    Dir.mkdir_p("temp")

    hello3_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")
    document = Pdfbox::Loader.load_pdf(hello3_path)
    ap = Pdfbox::Pdmodel::Encryption::AccessPermission.owner_access_permission
    recipient = Pdfbox::Pdmodel::Encryption::PublicKeyRecipient.new
    recipient.permissions = ap
    recipient.x509_certificate = read_der_certificate(cert_path)
    policy = Pdfbox::Pdmodel::Encryption::PublicKeyProtectionPolicy.new
    policy.add_recipient(recipient)
    document.protect(policy)
    document.save(encrypted_path)
    document.close

    dec = Tools::Decrypt.new(IO::Memory.new, IO::Memory.new)
    result = dec.call(["-i", encrypted_path, "-o", decrypted_path,
                       "--keyStore", keystore_path, "--password", "test1"])
    result.should eq(0)

    reloaded = Pdfbox::Loader.load_pdf(decrypted_path)
    reloaded.encryption.should be_nil
    reloaded.close

    File.delete(encrypted_path) if File.exists?(encrypted_path)
    File.delete(decrypted_path) if File.exists?(decrypted_path)
  end

  it "reports an error for a missing keystore" do
    err = IO::Memory.new
    dec = Tools::Decrypt.new(IO::Memory.new, err)
    result = dec.call(["-i", File.join(encryption_dir, "PasswordSample-40bit.pdf"),
                       "--keyStore", "temp/does_not_exist.pfx", "--password", "owner"])
    result.should eq(1)
    err.to_s.should contain("Keystore does not exist")
  end
end

private def read_der_certificate(path : String) : OpenSSL::X509::Certificate
  certificate, _ = OpenSSL::X509::Certificate.from_der?(File.read(path).to_slice)
  raise "Could not read certificate #{path}" unless certificate

  certificate
end
