require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/form/PDFormXObject.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::Form
  describe PDFormXObject do
    it "round-trips the optional content (/OC)" do
      stream = Pdfbox::Cos::Stream.new
      stream.data = "content".to_slice
      form = PDFormXObject.new(stream)
      form.optional_content.should be_nil

      group = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("Layer")
      form.optional_content = group
      resolved = form.optional_content
      resolved.should be_a(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup)
      resolved.not_nil!.cos_object.should be(group.cos_object)

      form.optional_content = nil
      form.optional_content.should be_nil
    end

    it "exposes the decoded form contents" do
      stream = Pdfbox::Cos::Stream.new
      stream.data = "q Q".to_slice
      form = PDFormXObject.new(stream)
      String.new(form.contents.getb_to_end).should eq("q Q")
    end
  end
end
