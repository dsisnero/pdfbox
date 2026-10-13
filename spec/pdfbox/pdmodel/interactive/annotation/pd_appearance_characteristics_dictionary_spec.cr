require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/annotation/PDAppearanceCharacteristicsDictionary.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Annotation
  describe PDAppearanceCharacteristicsDictionary do
    it "has no icons by default" do
      chars = PDAppearanceCharacteristicsDictionary.new(Pdfbox::Cos::Dictionary.new)
      chars.normal_icon.should be_nil
      chars.rollover_icon.should be_nil
      chars.alternate_icon.should be_nil
    end

    it "reads the normal/rollover/alternate form XObject icons (/I /RI /IX)" do
      dict = Pdfbox::Cos::Dictionary.new
      normal = Pdfbox::Cos::Stream.new
      normal.set_name(Pdfbox::Cos::Name::SUBTYPE, "Form")
      rollover = Pdfbox::Cos::Stream.new
      rollover.set_name(Pdfbox::Cos::Name::SUBTYPE, "Form")
      alternate = Pdfbox::Cos::Stream.new
      alternate.set_name(Pdfbox::Cos::Name::SUBTYPE, "Form")
      dict.set_item("I", normal)
      dict.set_item("RI", rollover)
      dict.set_item("IX", alternate)

      chars = PDAppearanceCharacteristicsDictionary.new(dict)
      chars.normal_icon.not_nil!.cos_object.should be(normal)
      chars.rollover_icon.not_nil!.cos_object.should be(rollover)
      chars.alternate_icon.not_nil!.cos_object.should be(alternate)
    end
  end
end
