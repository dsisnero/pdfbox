require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/common/filespecification/PDComplexFileSpecification.java
#
# Characterization spec: upstream does not cover the embedded-file accessors
# directly, so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Common::Filespecification
  describe PDComplexFileSpecification do
    it "round-trips the embedded file (/EF /F)" do
      spec = PDComplexFileSpecification.new
      spec.embedded_file.should be_nil

      stream = Pdfbox::Cos::Stream.new
      stream.data = "payload".to_slice
      file = PDEmbeddedFile.new(stream)
      spec.embedded_file = file

      spec.embedded_file.not_nil!.cos_object.should be(file.cos_object)
      ef = spec.cos_object.get_dictionary(Pdfbox::Cos::Name.new("EF"))
      ef.not_nil!.get_stream(Pdfbox::Cos::Name.new("F")).should be(stream)
    end

    it "reads the DOS/Mac/Unix embedded-file variants" do
      spec = PDComplexFileSpecification.new
      ef = Pdfbox::Cos::Dictionary.new
      spec.cos_object.set_item("EF", ef)

      dos = Pdfbox::Cos::Stream.new
      dos.data = "dos".to_slice
      mac = Pdfbox::Cos::Stream.new
      mac.data = "mac".to_slice
      unix = Pdfbox::Cos::Stream.new
      unix.data = "unix".to_slice
      ef.set_item("DOS", dos)
      ef.set_item("Mac", mac)
      ef.set_item("Unix", unix)

      spec.embedded_file_dos.not_nil!.cos_object.should be(dos)
      spec.embedded_file_mac.not_nil!.cos_object.should be(mac)
      spec.embedded_file_unix.not_nil!.cos_object.should be(unix)
    end

    it "sets the unicode embedded file (/EF /UF)" do
      spec = PDComplexFileSpecification.new
      stream = Pdfbox::Cos::Stream.new
      stream.data = "uni".to_slice
      file = PDEmbeddedFile.new(stream)

      spec.embedded_file_unicode = file
      spec.embedded_file_unicode.not_nil!.cos_object.should be(stream)
    end
  end
end
