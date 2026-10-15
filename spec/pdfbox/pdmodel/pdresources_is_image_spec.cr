require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java
#     isImageXObject (/XObject entry whose /Subtype is /Image).
private def resources_with_xobjects : Pdfbox::Pdmodel::PDResources
  xobjects = Pdfbox::Cos::Dictionary.new

  form = Pdfbox::Cos::Stream.new
  form.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
  xobjects[Pdfbox::Cos::Name.new("Fm1")] = form

  image = Pdfbox::Cos::Stream.new
  image.set_name(Pdfbox::Cos::Name.new("Subtype"), "Image")
  xobjects[Pdfbox::Cos::Name.new("Im1")] = image

  xobjects[Pdfbox::Cos::Name.new("NotStream")] = Pdfbox::Cos::String.new("nope")

  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name.new("XObject")] = xobjects
  Pdfbox::Pdmodel::PDResources.new(dict)
end

module Pdfbox::Pdmodel
  describe PDResources do
    it "detects image XObjects (Java isImageXObject)" do
      resources = resources_with_xobjects
      resources.image_x_object?(Cos::Name.new("Im1")).should be_true
      resources.image_x_object?(Cos::Name.new("Fm1")).should be_false
      resources.image_x_object?(Cos::Name.new("NotStream")).should be_false
      resources.image_x_object?(Cos::Name.new("Missing")).should be_false
    end

    it "exposes the Java-compatible is_image_xobject alias" do
      resources = resources_with_xobjects
      resources.is_image_xobject(Cos::Name.new("Im1")).should be_true
      resources.is_image_xobject(Cos::Name.new("Fm1")).should be_false
    end
  end
end
