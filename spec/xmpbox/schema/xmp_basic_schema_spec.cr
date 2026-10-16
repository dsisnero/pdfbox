require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of XMPBasicTest.java — verifies XMPBasicSchema text, date, integer,
    # and bag property getters/setters.
    describe XMPBasicSchema do
      it "sets and gets text properties with prefix xmp" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.base_url = "http://example.com"
        schema.creator_tool = "CreatorTool"
        schema.label = "label"
        schema.nickname = "nick name"

        schema.base_url.should eq("http://example.com")
        schema.creator_tool.should eq("CreatorTool")
        schema.label.should eq("label")
        schema.nickname.should eq("nick name")
      end

      it "sets and gets date properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        now = Time.utc(2024, 1, 15, 10, 30, 0)
        schema.create_date = now
        schema.metadata_date = now
        schema.modify_date = now

        schema.create_date.not_nil!.to_unix.should eq(now.to_unix)
        schema.metadata_date.not_nil!.to_unix.should eq(now.to_unix)
        schema.modify_date.not_nil!.to_unix.should eq(now.to_unix)
      end

      it "sets and gets integer rating" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.rating = 7
        schema.rating.should eq(7)
      end

      it "adds and lists bag identifiers and advisories" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.add_identifier("id1")
        schema.add_identifier("id2")
        schema.identifiers.should eq(["id1", "id2"])

        schema.add_advisory("xpath1")
        schema.add_advisory("xpath2")
        schema.advisories.should eq(["xpath1", "xpath2"])
      end

      it "sets the modifier date and removes identifiers and advisories" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        now = Time.utc(2024, 1, 15, 10, 30, 0)
        schema.modifier_date = now
        schema.modifier_date.not_nil!.to_unix.should eq(now.to_unix)

        schema.add_identifier("id1")
        schema.add_identifier("id2")
        schema.remove_identifier("id1")
        schema.identifiers.should eq(["id2"])

        schema.add_advisory("xpath1")
        schema.add_advisory("xpath2")
        schema.remove_advisory("xpath1")
        schema.advisories.should eq(["xpath2"])
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.base_url.should be_nil
        schema.creator_tool.should be_nil
        schema.label.should be_nil
        schema.nickname.should be_nil
        schema.create_date.should be_nil
        schema.rating.should be_nil
      end
    end
  end
end
