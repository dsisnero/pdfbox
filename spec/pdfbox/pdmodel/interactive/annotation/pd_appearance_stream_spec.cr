require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/annotation/PDAppearanceStream.java
#     getGroup/setGroup (/Group -> PDTransparencyGroupAttributes).
module Pdfbox::Pdmodel::Interactive::Annotation
  describe PDAppearanceStream do
    it "reads and writes the transparency group (Java getGroup/setGroup)" do
      stream = Cos::Stream.new
      stream.set_name(Cos::Name.new("Subtype"), "Form")
      appearance = PDAppearanceStream.new(stream)
      appearance.group.should be_nil

      attrs = Pdfbox::Pdmodel::Graphics::Form::PDTransparencyGroupAttributes.new
      appearance.group = attrs
      appearance.group.should_not be_nil
      appearance.cos_object.get_dictionary(Cos::Name.new("Group")).should be(attrs.cos_object)
    end
  end
end
