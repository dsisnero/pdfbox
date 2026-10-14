require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDNonTerminalField.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDNonTerminalField do
    it "reads the local field type and value and writes the value/default value" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        dict = Pdfbox::Cos::Dictionary.new
        dict.set_name("T", "Parent")
        field = PDNonTerminalField.new(acro, dict, nil)

        field.field_type.should eq("")
        field.value.should be_nil
        field.default_value.should be_nil

        dict.set_name("FT", "Tx")
        field.field_type.should eq("Tx")

        field.value = Pdfbox::Cos::String.new("hello")
        field.value.as(Pdfbox::Cos::String).value.should eq("hello")

        field.default_value = Pdfbox::Cos::String.new("default")
        field.default_value.as(Pdfbox::Cos::String).value.should eq("default")

        field.value = nil
        field.value.should be_nil
        field.default_value = nil
        field.default_value.should be_nil
      ensure
        document.close
      end
    end

    it "reads and writes child fields (/Kids)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        dict = Pdfbox::Cos::Dictionary.new
        field = PDNonTerminalField.new(acro, dict, nil)

        child_dict = Pdfbox::Cos::Dictionary.new
        child_dict.set_name("FT", "Tx")
        child_dict.set_string("T", "Child1")
        kids = Pdfbox::Cos::Array.new
        kids.add(child_dict)
        dict.set_item("Kids", kids)

        field.children.size.should eq(1)
        field.children[0].partial_name.should eq("Child1")

        # Java getString accepts a COSName /T as well as a COSString.
        named = Pdfbox::Cos::Dictionary.new
        named.set_name("FT", "Tx")
        named.set_name("T", "NamedChild")
        named_kids = Pdfbox::Cos::Array.new
        named_kids.add(named)
        dict.set_item("Kids", named_kids)
        field.children[0].partial_name.should eq("NamedChild")

        child = PDTextField.new(acro)
        field.children = [child]
        field.cos_object.get_array(Pdfbox::Cos::Name.new("Kids")).not_nil!.size.should eq(1)
      ensure
        document.close
      end
    end
  end
end
