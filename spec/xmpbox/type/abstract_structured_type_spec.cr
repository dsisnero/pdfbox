require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Type
    # Port of TestAbstractStructuredType.java — base class namespace/prefix and
    # simple-property behaviors using a custom structured type subclass.
    class MyStructuredType < AbstractStructuredType
      MY_TEXT = "my-text"
      MY_DATE = "my-date"

      def initialize(metadata : XMPMetadata, namespace_uri : String? = nil, field_prefix : String? = nil, property_name : String? = nil)
        super(metadata, namespace_uri, field_prefix, property_name || "structuredPN")
      end

      def self.structured_type_info
        nil
      end
    end

    MY_NS     = "http://www.apache.org/test#"
    MY_PREFIX = "test"

    describe AbstractStructuredType do
      xmp = XMPMetadata.create_xmp_metadata

      describe "validate" do
        it "keeps the given namespace and prefix" do
          st = MyStructuredType.new(xmp, MY_NS, MY_PREFIX)
          st.namespace.should eq(MY_NS)
          st.prefix.should eq(MY_PREFIX)
        end
      end

      describe "test_non_existing_property" do
        it "returns nil for an unknown property" do
          st = MyStructuredType.new(xmp, MY_NS, MY_PREFIX)
          st.property("NOT_EXISTING").should be_nil
        end
      end

      describe "test_not_valuated_property" do
        it "returns nil for an unset property" do
          st = MyStructuredType.new(xmp, MY_NS, MY_PREFIX)
          st.property(MyStructuredType::MY_TEXT).should be_nil
        end
      end

      describe "test_valuated_text_property" do
        it "adds and reads a text property" do
          st = MyStructuredType.new(xmp, MY_NS, MY_PREFIX)
          s = "my value"
          st.add_simple_property(MyStructuredType::MY_TEXT, s)
          st.property_value_as_string(MyStructuredType::MY_TEXT).should eq(s)
          st.property_value_as_string(MyStructuredType::MY_DATE).should be_nil
          st.property(MyStructuredType::MY_TEXT).should_not be_nil
        end
      end

      describe "test_valuated_date_property" do
        it "adds and reads a date property" do
          st = MyStructuredType.new(xmp, MY_NS, MY_PREFIX)
          c = Time.utc
          st.add_simple_property(MyStructuredType::MY_DATE, c)
          st.date_property_as_calendar(MyStructuredType::MY_DATE).not_nil!.to_unix.should eq(c.to_unix)
          st.date_property_as_calendar(MyStructuredType::MY_TEXT).should be_nil
          st.property(MyStructuredType::MY_DATE).should_not be_nil
        end
      end
    end
  end
end
