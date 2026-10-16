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

      it "adds, lists and removes bag/seq array properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.add_subject("s1")
        schema.add_subject("s2")
        schema.subjects.should eq(["s1", "s2"])
        schema.remove_subject("s1")
        schema.subjects.should eq(["s2"])

        schema.add_type("t1")
        schema.types.should eq(["t1"])
        schema.remove_type("t1")
        schema.types.should eq([] of String)

        schema.add_relation("r1")
        schema.relations.should eq(["r1"])

        schema.add_language("en")
        schema.languages.should eq(["en"])

        schema.add_publisher("p1")
        schema.publishers.should eq(["p1"])

        now = Time.utc(2023, 6, 1, 12, 0, 0)
        schema.add_date(now)
        schema.dates.not_nil!.size.should eq(1)
        schema.dates.not_nil![0].to_unix.should eq(now.to_unix)
        schema.remove_date(now)
        schema.dates.should eq([] of Time)

        schema.remove_contributor("Alice")
        schema.remove_creator("Alice")
      end

      it "sets and gets rights as a language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.add_rights(nil, "All rights reserved")
        schema.add_rights("fr", "Tous droits réservés")

        schema.rights.should eq("All rights reserved")
        schema.rights("fr").should eq("Tous droits réservés")
        schema.rights_languages.not_nil!.should contain("x-default")
        schema.rights_languages.not_nil!.should contain("fr")
        schema.rights_property.not_nil!.property_name.should eq("rights")

        schema.title = "A Title"
        schema.set_title("fr", "Un Titre")
        schema.title_languages.not_nil!.should contain("fr")
        schema.title_property.not_nil!.property_name.should eq("title")
      end

      it "exposes the array property getters" do
        meta = XMPMetadata.create_xmp_metadata
        schema = DublinCoreSchema.new(meta)

        schema.add_contributor("Alice")
        schema.add_creator("Bob")
        schema.add_subject("s1")
        schema.add_type("t1")
        schema.add_relation("r1")
        schema.add_language("en")
        schema.add_publisher("p1")
        schema.add_date(Time.utc(2023, 6, 1, 12, 0, 0))
        schema.description = "D"

        schema.contributors_property.not_nil!.property_name.should eq("contributor")
        schema.creators_property.not_nil!.property_name.should eq("creator")
        schema.subjects_property.not_nil!.property_name.should eq("subject")
        schema.types_property.not_nil!.property_name.should eq("type")
        schema.relations_property.not_nil!.property_name.should eq("relation")
        schema.languages_property.not_nil!.property_name.should eq("language")
        schema.publishers_property.not_nil!.property_name.should eq("publisher")
        schema.dates_property.not_nil!.property_name.should eq("date")
        schema.description_property.not_nil!.property_name.should eq("description")
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
        schema.rights.should be_nil
        schema.rights_property.should be_nil
        schema.title_languages.should be_nil
        schema.contributors_property.should be_nil
      end
    end
  end
end
