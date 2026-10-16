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

      it "sets and gets manager variant, last URL and save ID" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        schema.manager_variant = "variant"
        schema.last_url = "http://example.com/"
        schema.save_id = 7

        schema.manager_variant.should eq("variant")
        schema.last_url.should eq("http://example.com/")
        schema.save_id.should eq(7)
      end

      it "sets and gets the DerivedFrom and ManagedFrom resource references" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        derived = Xmpbox::Type::ResourceRefType.new(meta)
        derived.document_id = "xmp.did:derived"
        derived.property_name = XMPMediaManagementSchema::DERIVED_FROM
        schema.derived_from_property = derived

        managed = Xmpbox::Type::ResourceRefType.new(meta)
        managed.document_id = "xmp.did:managed"
        managed.property_name = XMPMediaManagementSchema::MANAGED_FROM
        schema.managed_from_property = managed

        schema.derived_from_property.not_nil!.document_id.should eq("xmp.did:derived")
        schema.managed_from_property.not_nil!.document_id.should eq("xmp.did:managed")
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPMediaManagementSchema.new(meta)

        schema.document_id.should be_nil
        schema.manager.should be_nil
        schema.instance_id.should be_nil
        schema.version_id.should be_nil
        schema.derived_from_property.should be_nil
        schema.managed_from_property.should be_nil
      end
    end
  end
end
