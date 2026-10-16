require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/xmpbox/src/main/java/org/apache/xmpbox/type/VersionType.java
#     get/setEvent, get/setModifier, get/setVersion, get/setModifyDate.
# Upstream has no dedicated VersionType test; this is a characterization spec.
module Xmpbox
  module Type
    describe VersionType do
      it "sets and reads event, version and modifier" do
        metadata = XMPMetadata.create_xmp_metadata
        v = VersionType.new(metadata)

        v.event = "created"
        v.event.should eq("created")

        v.version = "1.2"
        v.version.should eq("1.2")

        v.modifier = "Jane Doe"
        v.modifier.should eq("Jane Doe")
      end

      it "sets and reads the modify date" do
        metadata = XMPMetadata.create_xmp_metadata
        v = VersionType.new(metadata)

        v.modify_date.should be_nil
        now = Time.utc
        v.modify_date = now
        v.modify_date.not_nil!.to_unix.should eq(now.to_unix)
      end
    end
  end
end
