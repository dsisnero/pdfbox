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

      it "adds and lists thumbnails (Alt of ThumbnailType)" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.add_thumbnails(162, 216, "JPEG", "/9j/4AAQ")
        schema.add_thumbnails(80, 100, "PNG", "iVBORw0")

        thumbs = schema.thumbnails_property
        thumbs.should_not be_nil
        thumbs.not_nil!.size.should eq(2)
        thumbs.not_nil![0].height.should eq(162)
        thumbs.not_nil![0].width.should eq(216)
        thumbs.not_nil![0].format.should eq("JPEG")
        thumbs.not_nil![0].image.should eq("/9j/4AAQ")
        thumbs.not_nil![1].height.should eq(80)
      end

      it "exposes the property getters" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)

        schema.base_url = "http://example.com"
        schema.creator_tool = "Tool"
        schema.label = "label"
        schema.nickname = "nick"
        schema.rating = 7
        schema.add_identifier("id1")
        schema.add_advisory("xpath1")
        now = Time.utc(2024, 1, 15, 10, 30, 0)
        schema.create_date = now
        schema.metadata_date = now
        schema.modify_date = now
        schema.modifier_date = now

        schema.base_url_property.not_nil!.property_name.should eq("BaseURL")
        schema.creator_tool_property.not_nil!.property_name.should eq("CreatorTool")
        schema.label_property.not_nil!.property_name.should eq("Label")
        schema.nickname_property.not_nil!.property_name.should eq("Nickname")
        schema.rating_property.not_nil!.property_name.should eq("Rating")
        schema.identifiers_property.not_nil!.property_name.should eq("Identifier")
        schema.advisory_property.not_nil!.property_name.should eq("Advisory")
        schema.create_date_property.not_nil!.property_name.should eq("CreateDate")
        schema.metadata_date_property.not_nil!.property_name.should eq("MetadataDate")
        schema.modify_date_property.not_nil!.property_name.should eq("ModifyDate")
        schema.modifier_date_property.not_nil!.property_name.should eq("ModifierDate")
      end

      it "sets values via the property setters" do
        meta = XMPMetadata.create_xmp_metadata
        schema = XMPBasicSchema.new(meta)
        tm = meta.type_mapping

        schema.set_base_url_property(tm.create_url(nil, schema.prefix, "BaseURL", "http://x"))
        schema.set_creator_tool_property(tm.create_agent_name(nil, schema.prefix, "CreatorTool", "Tool"))
        schema.set_label_property(tm.create_text(nil, schema.prefix, "Label", "lbl"))
        schema.set_nickname_property(tm.create_text(nil, schema.prefix, "Nickname", "nick"))
        schema.set_rating_property(tm.create_integer(nil, schema.prefix, "Rating", 5))
        now = Time.utc(2024, 1, 15, 10, 30, 0)
        schema.set_create_date_property(tm.create_date(nil, schema.prefix, "CreateDate", now))
        schema.set_metadata_date_property(tm.create_date(nil, schema.prefix, "MetadataDate", now))
        schema.set_modify_date_property(tm.create_date(nil, schema.prefix, "ModifyDate", now))
        schema.set_modifier_date_property(tm.create_date(nil, schema.prefix, "ModifierDate", now))

        schema.base_url.should eq("http://x")
        schema.creator_tool.should eq("Tool")
        schema.label.should eq("lbl")
        schema.nickname.should eq("nick")
        schema.rating.should eq(5)
        schema.create_date.not_nil!.to_unix.should eq(now.to_unix)
        schema.metadata_date.not_nil!.to_unix.should eq(now.to_unix)
        schema.modify_date.not_nil!.to_unix.should eq(now.to_unix)
        schema.modifier_date.not_nil!.to_unix.should eq(now.to_unix)
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
        schema.thumbnails_property.should be_nil
      end
    end
  end
end
