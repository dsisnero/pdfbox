require "../../spec_helper"
require "../../../src/xmpbox"

module Xmpbox
  module Schema
    # Port of PDFAIdentificationTest.java and PDFAIdentificationOthersTest.java
    # — verifies PDFAIdentificationSchema part/amd/conformance/rev properties.
    describe PDFAIdentificationSchema do
      it "sets and gets part via int and string" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_part_value_with_int(1)
        schema.part.should eq(1)
        schema.part_property.not_nil!.string_value.should eq("1")
      end

      it "sets part via string value" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_part_value_with_string("1")
        schema.part.should eq(1)
      end

      it "rejects a non-integer part string" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_part_value_with_string("1")
        expect_raises(Exception) do
          schema.set_part_value_with_string("ojoj")
        end
      end

      it "sets and gets amd" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_amd("2005")
        schema.amendment.should eq("2005")
        schema.amd.should eq("2005")
        schema.amd_property.not_nil!.string_value.should eq("2005")
      end

      it "sets and gets conformance" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_conformance("B")
        schema.conformance.should eq("B")
        schema.conformance_property.not_nil!.string_value.should eq("B")
      end

      it "rejects an invalid conformance value" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        expect_raises(Type::BadFieldValueException) do
          schema.set_conformance("kiohiohiohiohio")
        end
      end

      it "sets and gets rev" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_rev_value_with_int(2020)
        schema.rev.should eq(2020)
        schema.rev_property.not_nil!.string_value.should eq("2020")
      end

      it "sets rev via string value" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.set_rev_value_with_string("2020")
        schema.rev.should eq(2020)
      end

      it "returns nil for unset properties" do
        meta = XMPMetadata.create_xmp_metadata
        schema = PDFAIdentificationSchema.new(meta)

        schema.part.should be_nil
        schema.amendment.should be_nil
        schema.conformance.should be_nil
        schema.rev.should be_nil
      end

      it "round-trips through serialize/parse via metadata factory" do
        meta = XMPMetadata.create_xmp_metadata
        pdfaid = meta.create_and_add_pdfa_identification_schema

        pdfaid.set_part_value_with_int(1)
        pdfaid.set_amd("2005")
        pdfaid.set_conformance("B")

        serialized = Xmpbox::Xml::XmpSerializer.new.serialize(meta)
        rxmp = Xmpbox::Xml::DomXmpParser.new.parse(serialized)
        rpdfaid = rxmp.pdfa_identification_schema
        rpdfaid.should_not be_nil

        rpdfaid.not_nil!.part.should eq(1)
        rpdfaid.not_nil!.amendment.should eq("2005")
        rpdfaid.not_nil!.conformance.should eq("B")
        rpdfaid.not_nil!.part_property.not_nil!.string_value.should eq("1")
        rpdfaid.not_nil!.amd_property.not_nil!.string_value.should eq("2005")
        rpdfaid.not_nil!.conformance_property.not_nil!.string_value.should eq("B")
      end
    end
  end
end
