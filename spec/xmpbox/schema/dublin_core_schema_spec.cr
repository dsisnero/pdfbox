require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of DublinCoreTest.java — verifies DublinCoreSchema simple text
    # properties, language-alternative title/description, and seq/bag arrays.
    describe DublinCoreSchema do
      it "sets and gets simple text properties with prefix dc" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.coverage = "the coverage"
        schema.format = "application/pdf"
        schema.identifier = "id-123"
        schema.source = "the source"

        schema.coverage.should eq("the coverage")
        schema.format.should eq("application/pdf")
        schema.identifier.should eq("id-123")
        schema.source.should eq("the source")

        schema.coverage_property.not_nil!.prefix.should eq("dc")
        schema.coverage_property.not_nil!.property_name.should eq("coverage")
      end

      it "sets and gets title as a language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.title = "A Title"
        schema.title.should eq("A Title")
        schema.title("x-default").should eq("A Title")

        schema.set_title("fr", "Un Titre")
        schema.title("fr").should eq("Un Titre")
      end

      it "sets and gets description as a language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.description = "A description"
        schema.description.should eq("A description")
        schema.description_languages.not_nil!.should contain("x-default")
      end

      it "adds and lists contributors (bag)" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.add_contributor("Alice")
        schema.add_contributor("Bob")

        schema.contributors.should eq(["Alice", "Bob"])
      end

      it "adds and lists creators (seq)" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.add_creator("Alice")
        schema.add_creator("Bob")

        schema.creators.should eq(["Alice", "Bob"])
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.coverage.should be_nil
        schema.format.should be_nil
        schema.identifier.should be_nil
        schema.source.should be_nil
        schema.title.should be_nil
        schema.description.should be_nil
      end
    end
  end
end
