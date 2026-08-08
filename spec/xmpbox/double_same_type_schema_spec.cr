require "../spec_helper"
require "../../src/xmpbox"

module Xmpbox
  # Port of DoubleSameTypeSchemaTest.java — two DublinCore schemas with the same
  # namespace but different prefixes must coexist in one metadata.
  describe XMPMetadata do
    it "keeps two schemas of the same type with different prefixes" do
      metadata = XMPMetadata.create_xmp_metadata
      dc1 = metadata.create_and_add_dublin_core_schema
      own_prefix = "test"
      dc2 = Xmpbox::Schema::DublinCoreSchema.new(metadata, nil, own_prefix)
      metadata.add_schema(dc2)

      creators = ["creator1", "creator2"]

      format = "application/pdf"
      dc1.format = format
      dc1.add_creator(creators[0])
      dc1.add_creator(creators[1])

      coverage = "Coverage"
      dc2.coverage = coverage
      dc2.add_creator(creators[0])
      dc2.add_creator(creators[1])

      st_dub = Xmpbox::Schema::DublinCoreSchema.structured_type_info

      # Metadata getSchema(prefix, nsURI) selects by prefix
      schema1 = metadata.schema(st_dub[:prefered_prefix], st_dub[:namespace])
      schema1.should_not be_nil
      schema1.as(Xmpbox::Schema::DublinCoreSchema).format.should eq(format)
      schema2 = metadata.schema(own_prefix, st_dub[:namespace])
      schema2.should_not be_nil
      schema2.as(Xmpbox::Schema::DublinCoreSchema).coverage.should eq(coverage)

      # Both schemas retain all creators
      metadata.all_schemas.each do |xmp_schema|
        dc = xmp_schema.as(Xmpbox::Schema::DublinCoreSchema)
        creators.all? { |c| dc.creators.not_nil!.includes?(c) }.should be_true
      end
    end
  end
end
