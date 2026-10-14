require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDListAttributeObject.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDExportFormatAttributeObject.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  describe PDListAttributeObject do
    it "defaults the list numbering to None and round-trips it" do
      attr = PDListAttributeObject.new
      attr.owner.should eq(PDListAttributeObject::OWNER_LIST)
      attr.list_numbering.should eq(PDListAttributeObject::LIST_NUMBERING_NONE)

      attr.list_numbering = PDListAttributeObject::LIST_NUMBERING_UPPER_ROMAN
      attr.list_numbering.should eq("UpperRoman")
    end
  end

  describe PDExportFormatAttributeObject do
    it "defaults and round-trips list numbering and table attributes" do
      attr = PDExportFormatAttributeObject.new
      attr.list_numbering.should eq(PDListAttributeObject::LIST_NUMBERING_NONE)
      attr.row_span.should eq(1)
      attr.col_span.should eq(1)
      attr.headers.should be_nil
      attr.scope.should be_nil
      attr.summary.should be_nil

      attr.list_numbering = PDListAttributeObject::LIST_NUMBERING_DECIMAL
      attr.row_span = 2
      attr.col_span = 3
      attr.scope = PDTableAttributeObject::SCOPE_COLUMN
      attr.summary = "A table"

      attr.list_numbering.should eq("Decimal")
      attr.row_span.should eq(2)
      attr.col_span.should eq(3)
      attr.scope.should eq("Column")
      attr.summary.should eq("A table")
    end

    it "writes /Headers as strings and reads name entries (Java asymmetry)" do
      attr = PDExportFormatAttributeObject.new
      attr.headers = ["H1", "H2"]
      array = attr.cos_object.get_array(Pdfbox::Cos::Name.new("Headers")).not_nil!
      array[0].as(Pdfbox::Cos::String).value.should eq("H1")

      dict = Pdfbox::Cos::Dictionary.new
      names = Pdfbox::Cos::Array.new
      names.add(Pdfbox::Cos::Name.new("Name1"))
      names.add(Pdfbox::Cos::Name.new("Name2"))
      dict.set_item("Headers", names)
      PDExportFormatAttributeObject.new(dict).headers.should eq(["Name1", "Name2"])
    end
  end
end
