require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroForm.java
#
# Characterization spec: upstream has no dedicated test for the XFA/quadding
# accessors, so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDAcroForm do
    it "reads and writes the default quadding (/Q)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        acro.q.should eq(0)
        acro.q = 1
        acro.q.should eq(1)
      ensure
        document.close
      end
    end

    it "handles a stream XFA resource (/XFA)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        acro.has_xfa?.should be_false
        acro.xfa.should be_nil
        acro.xfa_is_dynamic?.should be_false

        xfa_stream = Pdfbox::Cos::Stream.new
        xfa_stream.data = "<x/>".to_slice
        acro.xfa = PDXFAResource.new(xfa_stream)

        acro.has_xfa?.should be_true
        acro.xfa.not_nil!.bytes.should eq("<x/>".to_slice)
        acro.xfa_is_dynamic?.should be_true
      ensure
        document.close
      end
    end
  end
end
