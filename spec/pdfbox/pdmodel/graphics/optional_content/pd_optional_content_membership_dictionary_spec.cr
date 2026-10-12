require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/PDOptionalContentMembershipDictionary.java
#
# Characterization spec: upstream exercises OCMD only indirectly (via
# TestOptionalContentGroups), so these assertions are inferred from the Java
# observable behavior.
module Pdfbox::Pdmodel::Graphics::OptionalContent
  describe PDOptionalContentMembershipDictionary do
    it "defaults to the /OCMD type, no OCGs, and the AnyOn visibility policy" do
      ocmd = PDOptionalContentMembershipDictionary.new
      ocmd.cos_object.get_name_as_string(Cos::Name.new("Type")).should eq("OCMD")
      ocmd.ocgs.should be_empty
      ocmd.visibility_policy.value.should eq("AnyOn")
    end

    it "rejects a dictionary whose /Type is not /OCMD" do
      dict = Cos::Dictionary.new
      dict.set_name(Cos::Name.new("Type"), "OCG")
      expect_raises(ArgumentError) do
        PDOptionalContentMembershipDictionary.new(dict)
      end
    end

    it "round-trips the OCG list" do
      ocmd = PDOptionalContentMembershipDictionary.new
      first = PDOptionalContentGroup.new("Layer 1")
      second = PDOptionalContentGroup.new("Layer 2")

      ocmd.ocgs = [first, second]

      # /OCGs is stored as an array.
      ocmd.cos_object.get_array(Cos::Name.new("OCGs")).not_nil!.size.should eq(2)

      read = ocmd.ocgs
      read.size.should eq(2)
      read[0].as(PDOptionalContentGroup).name.should eq("Layer 1")
      read[1].as(PDOptionalContentGroup).name.should eq("Layer 2")
    end

    it "accepts a single dictionary for /OCGs" do
      ocmd = PDOptionalContentMembershipDictionary.new
      ocmd.cos_object[Cos::Name.new("OCGs")] = PDOptionalContentGroup.new("Only").cos_object

      read = ocmd.ocgs
      read.size.should eq(1)
      read[0].as(PDOptionalContentGroup).name.should eq("Only")
    end

    it "round-trips the visibility policy name" do
      ocmd = PDOptionalContentMembershipDictionary.new
      ocmd.visibility_policy = Cos::Name.new("AllOn")
      ocmd.visibility_policy.value.should eq("AllOn")

      ocmd.visibility_policy = Cos::Name.new("AnyOff")
      ocmd.visibility_policy.value.should eq("AnyOff")
    end

    it "dispatches through PDPropertyList.create on the /Type entry" do
      ocmd_dict = Cos::Dictionary.new
      ocmd_dict.set_name(Cos::Name.new("Type"), "OCMD")
      Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
        .create(ocmd_dict).should be_a(PDOptionalContentMembershipDictionary)

      ocg_dict = PDOptionalContentGroup.new("Layer").cos_object
      Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
        .create(ocg_dict).should be_a(PDOptionalContentGroup)
    end
  end
end
