require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of AdobePDFTest.java — verifies AdobePDFSchema getters/setters for
    # Keywords, PDFVersion, and Producer (text properties under prefix "pdf").
    describe AdobePDFSchema do
      it "sets and gets keywords, pdf version, and producer" do
        meta = XMPMetadata.create_xmp_metadata
        schema = AdobePDFSchema.new(meta)

        schema.keywords = "kw1 kw2 kw3"
        schema.pdf_version = "1.4"
        schema.producer = "testcase"

        schema.keywords.should eq("kw1 kw2 kw3")
        schema.pdf_version.should eq("1.4")
        schema.producer.should eq("testcase")

        schema.keywords_property.not_nil!.prefix.should eq("pdf")
        schema.keywords_property.not_nil!.property_name.should eq("Keywords")

        schema.pdf_version_property.not_nil!.prefix.should eq("pdf")
        schema.pdf_version_property.not_nil!.property_name.should eq("PDFVersion")

        schema.producer_property.not_nil!.prefix.should eq("pdf")
        schema.producer_property.not_nil!.property_name.should eq("Producer")
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = AdobePDFSchema.new(meta)

        schema.keywords.should be_nil
        schema.pdf_version.should be_nil
        schema.producer.should be_nil
      end
    end
  end
end
