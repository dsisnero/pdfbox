require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDField.java
#
# Characterization spec: upstream has no dedicated test for the alternate/mapping
# name accessors, so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDField do
    it "round-trips the alternate field name (/TU)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDTextField.new(acro)
        field.alternate_field_name.should be_nil

        field.alternate_field_name = "The alternate name"
        field.alternate_field_name.should eq("The alternate name")

        # Java COSDictionary.getString accepts a COSName as well.
        field.cos_object.set_name("TU", "NameAlt")
        field.alternate_field_name.should eq("NameAlt")
      ensure
        document.close
      end
    end

    it "round-trips the mapping name (/TM)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDTextField.new(acro)
        field.mapping_name.should be_nil

        field.mapping_name = "ExportName"
        field.mapping_name.should eq("ExportName")
      ensure
        document.close
      end
    end
  end
end
