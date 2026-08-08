require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of XMPMediaManagementTest.java — verifies XMPMediaManagementSchema
    # text properties and seq history.
    describe XMPMediaManagementSchema do
      it "sets and gets text properties with prefix xmpMM" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        schema.document_id = "uuid:FB031973-5E75-11B2-8F06-E7F5C101C07A"
        schema.manager = "Raoul"
        schema.manage_to = "uuid:36"
        schema.manage_ui = "uuid:3635"
        schema.instance_id = "uuid:42"
        schema.original_document_id = "uuid:142"
        schema.rendition_params = "my params"
        schema.version_id = "14"

        schema.document_id.should eq("uuid:FB031973-5E75-11B2-8F06-E7F5C101C07A")
        schema.manager.should eq("Raoul")
        schema.manage_to.should eq("uuid:36")
        schema.manage_ui.should eq("uuid:3635")
        schema.instance_id.should eq("uuid:42")
        schema.original_document_id.should eq("uuid:142")
        schema.rendition_params.should eq("my params")
        schema.version_id.should eq("14")
      end

      it "adds and lists history as a sequence" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        schema.add_history("action 1")
        schema.add_history("action 2")
        schema.add_history("action 3")

        schema.history.should eq(["action 1", "action 2", "action 3"])
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        schema.document_id.should be_nil
        schema.manager.should be_nil
        schema.instance_id.should be_nil
        schema.version_id.should be_nil
      end
    end
  end
end
