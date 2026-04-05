require "../spec_helper"

describe Tools::Encrypt do
  it "creates protection policy and marks document as encrypted" do
    # Create a simple test
    input_file = "vendor/pdfbox/tools/target/test-classes/org/apache/pdfbox/hello3.pdf"
    output_file = "temp/test_encrypted.pdf"

    # Load document
    document = Pdfbox::Loader.load_pdf(input_file)

    # Create access permissions
    ap = Pdfbox::Pdmodel::Encryption::AccessPermission.new
    ap.can_print = true
    ap.can_modify = false

    # Create protection policy
    policy = Pdfbox::Pdmodel::Encryption::StandardProtectionPolicy.new("ownerpass", "userpass", ap)
    policy.encryption_key_length = 128

    # Protect document
    document.protect(policy)

    # Verify document is marked as encrypted
    document.encrypted?.should be_true

    # Save document (even though encryption isn't fully implemented)
    document.save(output_file)
    document.close

    # Clean up
    File.delete(output_file) if File.exists?(output_file)
  end

  it "Encrypt tool accepts basic arguments" do
    # Test that the tool can parse arguments without error
    encrypt = Tools::Encrypt.new(IO::Memory.new, IO::Memory.new)

    # Test help
    result = encrypt.call(["-h"])
    result.should eq(0)
  end
end
