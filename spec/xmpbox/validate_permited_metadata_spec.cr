require "../spec_helper"
require "../../src/xmpbox"

describe "XMP permitted metadata" do
  # Port of TestValidatePermitedMetadata.java — every property in
  # permited_metadata.txt must exist as a schema factory with matching preferred
  # prefix and be declared in the schema's property_types.
  manifest_path = File.join(__DIR__, "..", "..", "vendor", "pdfbox", "xmpbox",
    "src", "test", "resources", "permited_metadata.txt")

  entries = [] of Tuple(String, String, String)
  File.each_line(manifest_path) do |line|
    next if line.starts_with?("#") || line.empty?
    next unless line.starts_with?("http://")
    pos = line.rindex(':')
    next unless pos
    spos = line.rindex('/', pos)
    next unless spos
    namespace = line[0...spos + 1]
    preferred = line[spos + 1...pos]
    fieldname = line[pos + 1..]
    entries << {namespace, preferred, fieldname}
  end

  it "declares every permitted metadata field" do
    meta = Xmpbox::XMPMetadata.create_xmp_metadata
    tm = meta.type_mapping

    entries.each do |(namespace, preferred, fieldname)|
      factory = tm.schema_factory(namespace)
      factory.should_not be_nil, "Schema not existing: #{namespace}"

      schema = factory.not_nil!.create_xmp_schema(meta, "aa")
      schema.prefered_prefix.should eq(preferred), "prefix #{preferred} for #{namespace}"

      found = schema.class.property_types.has_key?(fieldname)
      found.should be_true, "Did not find field definition for '#{fieldname}' in #{namespace}"
    end
  end
end
