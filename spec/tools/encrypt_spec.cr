require "../spec_helper"
require "base64"

hello3_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf")

describe Tools::Encrypt do
  it "creates protection policy and marks document as encrypted" do
    output_file = "temp/test_encrypted.pdf"

    document = Pdfbox::Loader.load_pdf(hello3_path)

    ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    ap.can_print = true
    ap.can_modify = false

    policy = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new("ownerpass", "userpass", ap)
    policy.encryption_key_length = 128

    document.protect(policy)
    document.encrypted?.should be_true

    document.save(output_file)
    document.close

    File.delete(output_file) if File.exists?(output_file)
  end

  it "reports missing input file" do
    err = IO::Memory.new
    enc = Tools::Encrypt.new(IO::Memory.new, err)
    result = enc.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end

  it "encrypts with an X.509 certificate and decrypts with the keystore" do
    encryption_dir = SpecPaths.resolve("spec/resources/pdfbox/encryption")
    cert_path = File.join(encryption_dir, "test1.der")
    keystore_path = File.join(encryption_dir, "test1.pfx")
    output_file = "temp/test_cert_encrypted.pdf"
    Dir.mkdir_p("temp")

    enc = Tools::Encrypt.new(IO::Memory.new, IO::Memory.new)
    result = enc.call(["-i", hello3_path, "-o", output_file, "--certFile", cert_path])
    result.should eq(0)

    File.open(keystore_path) do |key_store|
      reloaded = Pdfbox::Loader.load_pdf(File.read(output_file).to_slice, "test1", key_store)
      reloaded.encrypted?.should be_true
      Pdfbox::Text::PDFTextStripper.new.get_text(reloaded).should contain("Hello")
      reloaded.close
    end

    File.delete(output_file) if File.exists?(output_file)
  end

  it "encrypts with a PEM certificate file" do
    encryption_dir = SpecPaths.resolve("spec/resources/pdfbox/encryption")
    keystore_path = File.join(encryption_dir, "test1.pfx")
    pem_path = "temp/test1_cert.pem"
    output_file = "temp/test_cert_pem_encrypted.pdf"
    Dir.mkdir_p("temp")

    der = File.read(File.join(encryption_dir, "test1.der"))
    pem = "-----BEGIN CERTIFICATE-----\n" +
          Base64.encode(der).gsub(/(.{64})/, "\\1\n") +
          "-----END CERTIFICATE-----\n"
    File.write(pem_path, pem)

    enc = Tools::Encrypt.new(IO::Memory.new, IO::Memory.new)
    result = enc.call(["-i", hello3_path, "-o", output_file, "--certFile", pem_path])
    result.should eq(0)

    File.open(keystore_path) do |key_store|
      reloaded = Pdfbox::Loader.load_pdf(File.read(output_file).to_slice, "test1", key_store)
      reloaded.encrypted?.should be_true
      reloaded.close
    end

    File.delete(pem_path) if File.exists?(pem_path)
    File.delete(output_file) if File.exists?(output_file)
  end

  it "reports an error for a missing certificate file" do
    err = IO::Memory.new
    enc = Tools::Encrypt.new(IO::Memory.new, err)
    result = enc.call(["-i", hello3_path, "-o", "temp/should_not_exist.pdf",
                       "--certFile", "temp/does_not_exist.der"])
    result.should eq(1)
    err.to_s.should contain("Certificate file not found")
  end
end
