require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDUserAttributeObject.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDUserProperty.java
#
# Characterization spec: upstream has no dedicated PDUserAttributeObject test,
# so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDUserAttributeObject do
    it "defaults to the UserProperties owner" do
      attribute = PDUserAttributeObject.new
      attribute.owner.should eq("UserProperties")
      attribute.user_properties.should be_empty
    end

    it "adds, reads back, and removes a user property" do
      attribute = PDUserAttributeObject.new
      property = PDUserProperty.new(attribute)
      property.name = "foo"
      property.value = Cos::String.new("bar")
      property.formatted_value = "baz"
      property.hidden = true
      attribute.add_user_property(property)

      read = attribute.user_properties
      read.size.should eq(1)
      read[0].name.should eq("foo")
      read[0].value.as(Cos::String).value.should eq("bar")
      read[0].formatted_value.should eq("baz")
      read[0].hidden?.should be_true

      # The /P array holds the property dictionary with the /N, /V, /F, /H entries.
      array = attribute.cos_object.get_array(Cos::Name.new("P"))
      array.should_not be_nil
      array.not_nil!.size.should eq(1)
      read[0].cos_object.get_name_as_string(Cos::Name.new("N")).should eq("foo")
      read[0].cos_object.get_string(Cos::Name.new("F")).should eq("baz")
      read[0].cos_object.get_dictionary_object(Cos::Name.new("V")).as(Cos::String).value.should eq("bar")
      read[0].cos_object.get_dictionary_object(Cos::Name.new("H")).as(Cos::Boolean).value.should be_true

      attribute.remove_user_property(read[0])
      attribute.user_properties.should be_empty
    end

    it "round-trips the whole property list through the setter" do
      attribute = PDUserAttributeObject.new
      first = PDUserProperty.new(attribute)
      first.name = "one"
      second = PDUserProperty.new(attribute)
      second.name = "two"

      attribute.user_properties = [first, second]

      names = attribute.user_properties.map(&.name)
      names.should eq(["one", "two"])
    end

    it "has empty defaults for a fresh user property" do
      property = PDUserProperty.new(nil)
      property.name.should be_nil
      property.value.should be_nil
      property.formatted_value.should be_nil
      property.hidden?.should be_false
    end

    it "dispatches through PDAttributeObject.create on the UserProperties owner" do
      dict = Cos::Dictionary.new
      dict.set_name(Cos::Name.new("O"), "UserProperties")

      attribute = PDAttributeObject.create(dict)
      attribute.should be_a(PDUserAttributeObject)
    end
  end
end
