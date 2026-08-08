require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Type
    # Port of TestDerivedType.java — verifies each derived TextType can be
    # instantiated with a string value and that getValue returns it.
    describe "Derived text types" do
      prefix = "myprefix"
      name = "myname"
      test_value = "myvalue"

      it "instantiates ProperNameType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = ProperNameType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates LocaleType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = LocaleType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates AgentNameType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = AgentNameType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates GUIDType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = GUIDType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates XPathType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = XPathType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates PartType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = PartType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates URLType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = URLType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates URIType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = URIType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates ChoiceType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = ChoiceType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates MIMEType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = MIMEType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end

      it "instantiates RenditionClassType" do
        metadata = XMPMetadata.create_xmp_metadata
        element = RenditionClassType.new(metadata, nil, prefix, name, test_value)
        element.namespace.should be_nil
        element.value.should eq(test_value)
      end
    end
  end
end
