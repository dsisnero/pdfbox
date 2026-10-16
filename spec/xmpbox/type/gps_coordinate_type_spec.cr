require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/xmpbox/src/main/java/org/apache/xmpbox/type/GPSCoordinateType.java
# GPSCoordinateType is a TextType subclass used for the EXIF GPS coordinate
# properties (GPSLatitude/GPSLongitude/GPSDestLatitude/GPSDestLongitude).
# Upstream has no dedicated test; this is a characterization spec.
module Xmpbox
  module Type
    describe GPSCoordinateType do
      it "is a TextType holding the given string value" do
        metadata = XMPMetadata.create_xmp_metadata
        element = GPSCoordinateType.new(metadata, nil, "exif", "GPSLatitude", "12,34,56N")

        element.namespace.should be_nil
        element.prefix.should eq("exif")
        element.property_name.should eq("GPSLatitude")
        element.value.should eq("12,34,56N")
        element.string_value.should eq("12,34,56N")
      end

      it "reports its implementing class name" do
        Types::GPSCoordinate.implementing_class_name.should eq("GPSCoordinateType")
        Types::GPSCoordinate.basic.should eq(Types::Text)
      end

      it "is instantiated by the type mapping" do
        metadata = XMPMetadata.create_xmp_metadata
        property = metadata.type_mapping.instanciate_simple_property(
          "http://ns.adobe.com/exif/1.0/", "exif", "GPSLongitude", "10,20,30E", Types::GPSCoordinate)

        property.should be_a(GPSCoordinateType)
        property.as(GPSCoordinateType).string_value.should eq("10,20,30E")
      end
    end
  end
end
