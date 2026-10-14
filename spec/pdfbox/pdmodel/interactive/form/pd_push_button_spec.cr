require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDPushButton.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDPushButton do
    it "has no value, default value, export values, or on values" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        button = PDPushButton.new(acro)
        button.value.should eq("")
        button.default_value.should eq("")
        button.get_export_values.should be_empty
        button.get_on_values.should be_empty
      ensure
        document.close
      end
    end

    it "rejects export values (a push button shall not use /Opt)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        button = PDPushButton.new(acro)
        button.set_export_values([] of String)
        button.set_export_values(nil)
        expect_raises(ArgumentError, "A PDPushButton shall not use the Opt entry in the field dictionary") do
          button.set_export_values(["A"])
        end
      ensure
        document.close
      end
    end
  end
end
