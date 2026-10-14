require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroForm.java
#
# Characterization spec: upstream has no dedicated test for the calculation order,
# so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDAcroForm do
    it "round-trips the calculation order (/CO)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        acro.calc_order.should be_nil

        array = Pdfbox::Cos::Array.new
        array.add(Pdfbox::Cos::String.new("field1"))
        acro.calc_order = array
        acro.calc_order.not_nil!.should be(array)

        acro.calc_order = nil
        acro.calc_order.should be_nil
      ensure
        document.close
      end
    end
  end
end
