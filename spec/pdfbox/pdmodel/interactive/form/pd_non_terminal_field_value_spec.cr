require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDNonTerminalField.java
#     getValueAsString() returns `getCOSObject().getDictionaryObject(COSName.V).toString()`
#     (the local /V, without inheritance), or "" when there is no /V.
#   The `COSBase#toString()` implementations are debug forms in PDFBox:
#     COSString{"COSString{" + value + "}"}, COSName{"COSName{" + name + "}"},
#     COSInt{"COSInt{" + value + "}"}, COSFloat{"COSFloat{" + value + "}"}.
#   The port returned "" for every non-terminal field, so a group field with its
#   own /V reported no value at all.
private def non_terminal_field(value : Pdfbox::Cos::Base?) : Pdfbox::Pdmodel::Interactive::Form::PDField
  document = Pdfbox::Pdmodel::Document.create
  acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
  document.document_catalog.not_nil!.acro_form = acro_form

  kid = Pdfbox::Cos::Dictionary.new
  kid[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("kid")
  kid[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")

  parent = Pdfbox::Cos::Dictionary.new
  parent[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("parent")
  parent[Pdfbox::Cos::Name.new("V")] = value if value
  kids = Pdfbox::Cos::Array.new
  kids.add(kid)
  parent[Pdfbox::Cos::Name.new("Kids")] = kids

  fields = Pdfbox::Cos::Array.new
  fields.add(parent)
  acro_form.cos_object[Pdfbox::Cos::Name.new("Fields")] = fields

  document.close
  field = acro_form.get_field("parent")
  field.should be_a(Pdfbox::Pdmodel::Interactive::Form::PDNonTerminalField)
  field.not_nil!
end

describe Pdfbox::Pdmodel::Interactive::Form::PDNonTerminalField do
  it "returns the local value's string form" do
    non_terminal_field(Pdfbox::Cos::String.new("Parent Value"))
      .value_as_string.should eq("COSString{Parent Value}")
  end

  it "uses the COS name form for a name value" do
    non_terminal_field(Pdfbox::Cos::Name.new("Choice"))
      .value_as_string.should eq("COSName{Choice}")
  end

  it "uses the COS integer form for a number value" do
    non_terminal_field(Pdfbox::Cos::Integer.new(42))
      .value_as_string.should eq("COSInt{42}")
  end

  it "returns an empty string when there is no value" do
    non_terminal_field(nil).value_as_string.should eq("")
  end
end
