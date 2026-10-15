require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocumentInformation.java
#     setTrapped (validates True/False/Unknown and writes a name), getTrapped,
#     setCustomMetadataValue/getCustomMetadataValue.
#
# TestPDDocumentInformation only reads values, so the setter assertions below
# are derived from the Java source.
module Pdfbox::Pdmodel
  describe DocumentInformation do
    it "round-trips valid trapped values as a name (Java setTrapped)" do
      info = DocumentInformation.new
      info.trapped.should be_nil

      info.trapped = "True"
      info.trapped.should eq("True")
      info.cos_object[Cos::Name.new("Trapped")].should be_a(Cos::Name)

      info.trapped = "Unknown"
      info.trapped.should eq("Unknown")
    end

    it "clears trapped on nil (Java setName with null)" do
      info = DocumentInformation.new
      info.trapped = "False"
      info.trapped = nil
      info.trapped.should be_nil
    end

    it "raises for an invalid trapped value (Java IllegalArgumentException)" do
      info = DocumentInformation.new
      expect_raises(ArgumentError, "Valid values for trapped are 'True', 'False', or 'Unknown'") do
        info.trapped = "Maybe"
      end
    end

    it "sets and reads a custom metadata value (Java setCustomMetadataValue)" do
      info = DocumentInformation.new
      info.set_custom_metadata_value("Company", "Basis Technology Corp.")
      info.custom_metadata_value("Company").should eq("Basis Technology Corp.")
    end
  end
end
