require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Characterization spec for TiffSchema.java — the Artist (ProperName),
    # ImageDescription and Copyright (LangAlt) accessors. Upstream has no
    # dedicated TiffSchema test.
    describe TiffSchema do
      it "sets and gets the Artist proper-name property" do
        meta = XMPMetadata.create_xmp_metadata
        schema = TiffSchema.new(meta)

        schema.artist = "An Artist"

        schema.artist.should eq("An Artist")
        schema.artist_property.not_nil!.should be_a(Xmpbox::Type::ProperNameType)
        schema.artist_property.not_nil!.prefix.should eq("tiff")
        schema.artist_property.not_nil!.property_name.should eq("Artist")
      end

      it "adds and gets the ImageDescription language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = TiffSchema.new(meta)

        schema.add_image_description(nil, "A description")
        schema.add_image_description("fr", "Une description")

        schema.image_description.should eq("A description")
        schema.image_description("fr").should eq("Une description")
        schema.image_description_languages.not_nil!.should contain("x-default")
        schema.image_description_languages.not_nil!.should contain("fr")
        schema.image_description_property.not_nil!.property_name.should eq("ImageDescription")
      end

      it "adds and gets the Copyright language alternative" do
        meta = XMPMetadata.create_xmp_metadata
        schema = TiffSchema.new(meta)

        schema.add_copyright(nil, "Copyright 2026")
        schema.add_copyright("fr", "Droits 2026")

        schema.copyright.should eq("Copyright 2026")
        schema.copyright("fr").should eq("Droits 2026")
        schema.copyright_languages.not_nil!.should contain("fr")
        schema.copyright_property.not_nil!.property_name.should eq("Copyright")
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = TiffSchema.new(meta)

        schema.artist.should be_nil
        schema.image_description.should be_nil
        schema.copyright.should be_nil
      end
    end
  end
end
