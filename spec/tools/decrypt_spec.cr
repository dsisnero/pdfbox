require "../spec_helper"
require "../../src/tools"

describe Tools::Decrypt do
  encryption_dir = File.expand_path("../../../vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/encryption", __DIR__)

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
end
