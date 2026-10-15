require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java#getXObject
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/PDXObject.java#createXObject
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/PDPostScriptXObject.java
private def xobject_resources : Pdfbox::Pdmodel::PDResources
  xobjects = Pdfbox::Cos::Dictionary.new

  image = Pdfbox::Cos::Stream.new
  image.set_name(Pdfbox::Cos::Name.new("Subtype"), "Image")
  xobjects[Pdfbox::Cos::Name.new("Im1")] = image

  form = Pdfbox::Cos::Stream.new
  form.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
  xobjects[Pdfbox::Cos::Name.new("Fm1")] = form

  transparency = Pdfbox::Cos::Stream.new
  transparency.set_name(Pdfbox::Cos::Name.new("Subtype"), "Form")
  group = Pdfbox::Cos::Dictionary.new
  group.set_name(Pdfbox::Cos::Name.new("S"), "Transparency")
  transparency[Pdfbox::Cos::Name.new("Group")] = group
  xobjects[Pdfbox::Cos::Name.new("Tr1")] = transparency

  ps = Pdfbox::Cos::Stream.new
  ps.set_name(Pdfbox::Cos::Name.new("Subtype"), "PS")
  xobjects[Pdfbox::Cos::Name.new("PS1")] = ps

  bogus = Pdfbox::Cos::Stream.new
  bogus.set_name(Pdfbox::Cos::Name.new("Subtype"), "Bogus")
  xobjects[Pdfbox::Cos::Name.new("Bad1")] = bogus

  dict = Pdfbox::Cos::Dictionary.new
  dict[Pdfbox::Cos::Name.new("XObject")] = xobjects
  Pdfbox::Pdmodel::PDResources.new(dict)
end

module Pdfbox::Pdmodel
  describe PDResources do
    it "dispatches XObject subtypes (Java getXObject/createXObject)" do
      resources = xobject_resources

      resources.get_xobject(Cos::Name.new("Im1")).should be_a(Graphics::Image::PDImageXObject)
      resources.get_xobject(Cos::Name.new("Fm1")).should be_a(Graphics::Form::PDFormXObject)
      resources.get_xobject(Cos::Name.new("Tr1")).should be_a(Graphics::Form::PDTransparencyGroup)
      resources.get_xobject(Cos::Name.new("PS1")).should be_a(Graphics::PDPostScriptXObject)
      resources.get_xobject(Cos::Name.new("Missing")).should be_nil
    end

    it "raises for an invalid XObject subtype (Java createXObject)" do
      resources = xobject_resources
      expect_raises(::IO::Error, "Invalid XObject Subtype: Bogus") do
        resources.get_xobject(Cos::Name.new("Bad1"))
      end
    end
  end
end
