require "../spec_helper"

hello3_path = File.expand_path("../../vendor/pdfbox/pdfbox/src/test/resources/input/hello3.pdf", __DIR__)

describe Tools::Encrypt do
  if File.exists?(hello3_path)
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
  else
    pending "hello3.pdf fixture not found"
  end

  it "reports missing input file" do
    err = IO::Memory.new
    enc = Tools::Encrypt.new(IO::Memory.new, err)
    result = enc.call([] of String)
    result.should eq(1)
    err.to_s.should contain("Missing required option: -i")
  end
end
