require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/form/PDTransparencyGroup.java
#
# Characterization spec: upstream has no dedicated PDTransparencyGroup test, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Form
  private def self.form_stream(group_subtype : String?) : Cos::Stream
    stream = Cos::Stream.new
    if group_subtype
      group = Cos::Dictionary.new
      group[Cos::Name::S] = Cos::Name.new(group_subtype)
      stream[Cos::Name.new("Group")] = group
    end
    stream
  end

  describe PDTransparencyGroup do
    it "is a form XObject (Java does not validate the group subtype)" do
      group = PDTransparencyGroup.new(form_stream("Transparency"))
      group.should be_a(PDFormXObject)
      group.cos_object.get_name_as_string(Cos::Name::SUBTYPE).should eq("Form")
      group.cos_object.get_name_as_string(Cos::Name::TYPE).should eq("XObject")

      # A non-transparency form is still accepted by the constructor.
      PDTransparencyGroup.new(form_stream("DeviceRGB")).should be_a(PDFormXObject)
      PDTransparencyGroup.new(form_stream(nil)).should be_a(PDFormXObject)
    end

    it "is constructed for a transparency group by PDSoftMask#group" do
      smask = Cos::Dictionary.new
      group_stream = form_stream("Transparency")
      smask[Cos::Name.new("G")] = group_stream

      mask = Pdfbox::Pdmodel::Graphics::State::PDSoftMask.new(smask)
      mask.group.should be_a(PDTransparencyGroup)
    end

    it "is nil for a non-transparency /G stream in PDSoftMask#group" do
      smask = Cos::Dictionary.new
      smask[Cos::Name.new("G")] = form_stream("DeviceRGB")

      mask = Pdfbox::Pdmodel::Graphics::State::PDSoftMask.new(smask)
      mask.group.should be_nil
    end
  end
end
