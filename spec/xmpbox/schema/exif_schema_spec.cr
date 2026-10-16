require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of TestExifXmp.java — verifies lenient parsing of exif.xmp with the
    # Exif schema and its SpectralSensitivity text property.
    describe ExifSchema do
      it "parses exif.xmp leniently and reads SpectralSensitivity" do
        fixture_path = File.join(__DIR__, "..", "..", "fixtures", "xmpbox", "validxmp", "exif.xmp")
        parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
        rxmp = parser.parse(File.open(fixture_path))

        schema = rxmp.exif_schema
        schema.should_not be_nil

        ss = schema.not_nil!.abstract_property("SpectralSensitivity")
        ss.should_not be_nil
        ss.should be_a(Xmpbox::Type::TextType)
        ss.as(Xmpbox::Type::TextType).string_value.should eq("spectral sens value")
      end

      it "serializes an exif schema with an OECF structured property" do
        meta = XMPMetadata.create_xmp_metadata
        exif = ExifSchema.new(meta)
        meta.add_schema(exif)

        oecf = Xmpbox::Type::OECFType.new(meta)
        oecf.add_property(meta.type_mapping.create_integer(
          oecf.namespace, oecf.prefix, Xmpbox::Type::OECFType::COLUMNS, 14))
        oecf.property_name = "OECF"
        exif.add_property(oecf)

        serialized = Xmpbox::Xml::XmpSerializer.new.serialize(meta, false)
        serialized.should_not be_nil
        serialized.includes?("OECF").should be_true
      end

      it "reads the UserComment language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = ExifSchema.new(meta)

        schema.set_unqualified_language_property_value("UserComment", nil, "A comment")
        schema.set_unqualified_language_property_value("UserComment", "fr", "Un commentaire")

        schema.user_comment.should eq("A comment")
        schema.user_comment("fr").should eq("Un commentaire")
        schema.user_comment_languages.not_nil!.should contain("x-default")
        schema.user_comment_languages.not_nil!.should contain("fr")
        schema.user_comment_property.not_nil!.property_name.should eq("UserComment")
      end

      it "returns nil for an unset UserComment" do
        meta = XMPMetadata.create_xmp_metadata
        schema = ExifSchema.new(meta)

        schema.user_comment.should be_nil
        schema.user_comment_property.should be_nil
        schema.user_comment_languages.should be_nil
      end
    end
  end
end
