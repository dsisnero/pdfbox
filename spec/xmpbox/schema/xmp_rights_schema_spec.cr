require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of XmpRightsSchemaTest.java — verifies XMPRightsManagementSchema
    # URL, boolean, bag owner, and LangAlt usage-terms properties.
    describe XMPRightsManagementSchema do
      it "sets and gets certificate and web statement" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPRightsManagementSchema.new(meta)

        schema.certificate = "http://une.url.vers.un.certificat/moncert.cer"
        schema.web_statement = "http://une.url.vers.une.page.fr/"

        schema.certificate.should eq("http://une.url.vers.un.certificat/moncert.cer")
        schema.web_statement.should eq("http://une.url.vers.une.page.fr/")
      end

      it "sets and gets the marked boolean" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPRightsManagementSchema.new(meta)

        schema.marked = true
        schema.marked.should be_true

        schema.marked = false
        schema.marked.should be_false
      end

      it "adds and lists owners as a bag" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPRightsManagementSchema.new(meta)

        schema.add_owner("OwnerName")
        schema.owners.should eq(["OwnerName"])
      end

      it "sets and gets usage terms as a language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPRightsManagementSchema.new(meta)

        schema.usage_terms = "All rights reserved"
        schema.usage_terms.should eq("All rights reserved")
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPRightsManagementSchema.new(meta)

        schema.certificate.should be_nil
        schema.web_statement.should be_nil
        schema.marked.should be_nil
        schema.usage_terms.should be_nil
      end
    end
  end
end
