require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDDefaultAttributeObject.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDAttributeObject.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDDefaultAttributeObject do
    it "round-trips named attributes" do
      attr = PDDefaultAttributeObject.new
      attr.attribute_names.should be_empty
      attr.attribute_value("Foo").should be_nil

      attr.set_attribute("Foo", Pdfbox::Cos::Name.new("Bar"))
      attr.attribute_names.should eq(["Foo"])
      attr.attribute_value("Foo").as(Pdfbox::Cos::Name).value.should eq("Bar")

      attr.set_attribute("Num", Pdfbox::Cos::Integer.get(42_i64))
      attr.attribute_names.size.should eq(2)
      attr.attribute_value("Num").as(Pdfbox::Cos::Integer).value.should eq(42)
    end

    it "excludes the owner (/O) from the attribute names" do
      attr = PDDefaultAttributeObject.new
      attr.cos_object.set_name("O", "Custom")
      attr.owner.should eq("Custom")
      attr.set_attribute("Foo", Pdfbox::Cos::Name.new("Bar"))
      attr.attribute_names.should eq(["Foo"])
    end

    it "notifies the structure element when an attached attribute value changes" do
      element = PDStructureElement.new("S", nil)
      element.revision_number = 3

      attr = PDDefaultAttributeObject.new
      element.add_attribute(attr)
      element.attributes.get_revision_number(0).should eq(3)

      element.revision_number = 9
      attr.set_attribute("Foo", Pdfbox::Cos::Name.new("Bar"))
      element.attributes.get_revision_number(0).should eq(9)
    end
  end
end
