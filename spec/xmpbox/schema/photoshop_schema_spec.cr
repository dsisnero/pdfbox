require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of PhotoshopSchemaTest.java — verifies PhotoshopSchema text, date,
    # and integer property getters/setters.
    describe PhotoshopSchema do
      it "sets and gets text properties with prefix photoshop" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        schema.authors_position = "Author"
        schema.caption_writer = "Writer"
        schema.city = "Paris"
        schema.country = "France"
        schema.credit = "Credit"
        schema.headline = "Headline"
        schema.history = "History"
        schema.icc_profile = "sRGB"
        schema.instructions = "Instructions"
        schema.state = "IDF"

        schema.authors_position.should eq("Author")
        schema.caption_writer.should eq("Writer")
        schema.city.should eq("Paris")
        schema.country.should eq("France")
        schema.credit.should eq("Credit")
        schema.headline.should eq("Headline")
        schema.history.should eq("History")
        schema.icc_profile.should eq("sRGB")
        schema.instructions.should eq("Instructions")
        schema.state.should eq("IDF")
      end

      it "sets and gets integer color mode and urgency" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        schema.color_mode = 3
        schema.urgency = 5

        schema.color_mode.should eq(3)
        schema.urgency.should eq(5)
      end

      it "sets and gets the date created" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        now = Time.utc(2023, 6, 1, 12, 0, 0)
        schema.date_created = now
        schema.date_created.not_nil!.to_unix.should eq(now.to_unix)
      end

      it "sets and gets category, supplemental categories, transmission reference and ancestor id" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        schema.category = "Cat"
        schema.supplemental_categories = "Sub"
        schema.transmission_reference = "Ref"
        schema.ancestor_id = "xmp.did:1234"

        schema.category.should eq("Cat")
        schema.supplemental_categories.should eq("Sub")
        schema.transmission_reference.should eq("Ref")
        schema.ancestor_id.should eq("xmp.did:1234")
      end

      it "adds text layers (Seq of LayerType) and document ancestors (Bag)" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        schema.add_text_layers("Name1", "Text1")
        schema.add_text_layers("Name2", "Text2")
        schema.add_document_ancestors("adobe:docid:photoshop:1")
        schema.add_document_ancestors("adobe:docid:photoshop:2")

        layers = schema.text_layers
        layers.should_not be_nil
        layers.not_nil!.size.should eq(2)
        layers.not_nil![0].layer_name.should eq("Name1")
        layers.not_nil![0].layer_text.should eq("Text1")
        layers.not_nil![1].layer_name.should eq("Name2")
        layers.not_nil![1].layer_text.should eq("Text2")

        schema.document_ancestors.should eq(["adobe:docid:photoshop:1", "adobe:docid:photoshop:2"])
        schema.document_ancestors_property.not_nil!.property_name.should eq("DocumentAncestors")
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PhotoshopSchema.new(meta)

        schema.city.should be_nil
        schema.country.should be_nil
        schema.headline.should be_nil
        schema.color_mode.should be_nil
        schema.urgency.should be_nil
        schema.date_created.should be_nil
        schema.text_layers.should be_nil
        schema.document_ancestors.should be_nil
        schema.document_ancestors_property.should be_nil
      end
    end
  end
end
