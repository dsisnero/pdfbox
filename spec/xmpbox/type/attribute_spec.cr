require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Type
    describe Attribute do
      it "creates attribute" do
        attr = Attribute.new("http://ns.test.org/", "name1", "value1")
        attr.ns_uri.should eq("http://ns.test.org/")
        attr.name.should eq("name1")
        attr.value.should eq("value1")
      end

      it "creates attribute with nil namespace" do
        attr = Attribute.new(nil, "name", "value")
        attr.ns_uri.should be_nil
        attr.name.should eq("name")
      end

      it "sets attribute on field" do
        meta = XMPMetadata.create_xmp_metadata
        int_type = IntegerType.new(meta, nil, "test", "integer", 1)
        attr = Attribute.new("http://www.test.org/test/", "value1", "StringValue1")
        attr2 = Attribute.new("http://www.test.org/test/", "value2", "StringValue2")

        int_type.attribute = attr
        int_type.attribute("value1").should eq(attr)
        int_type.contains_attribute?("value1").should be_true

        # Replace attribute with same name
        attr_replacement = Attribute.new("http://www.test.org/test/", "value1", "Replaced")
        int_type.attribute = attr_replacement
        int_type.attribute("value1").should eq(attr_replacement)

        # Attribute with different name coexists
        int_type.attribute = attr2
        int_type.contains_attribute?("value1").should be_true
        int_type.contains_attribute?("value2").should be_true

        # Removal
        int_type.remove_attribute("value2")
        int_type.contains_attribute?("value2").should be_false
      end

      it "all_attributes deduplicates by name" do
        meta = XMPMetadata.create_xmp_metadata
        int_type = IntegerType.new(meta, nil, "test", "integer", 1)

        attr_ns = Attribute.new("http://www.tefst2.org/test/", "value2", "StringValue.2")
        int_type.attribute = attr_ns
        attr_ns2 = Attribute.new("http://www.test2.org/test/", "value2", "StringValueTwo")
        int_type.attribute = attr_ns2

        attrs = int_type.all_attributes
        attrs.includes?(attr_ns).should be_false
        attrs.includes?(attr_ns2).should be_true
      end
    end
  end
end
