require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java
#     add(PDFont) -> add(COSName.FONT, "F", font), which reads the resource
#     sub-dictionary with COSDictionary#getCOSDictionary (an *indirect* entry is
#     dereferenced), so an existing /Font dictionary loaded from a file is
#     extended rather than replaced.
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     setFont -> resources.add(font).
#
# Upstream has no dedicated test for the indirect sub-dictionary case; this is a
# characterization spec for a regression where a file whose appearance stream
# /Resources /Font was an indirect object lost the already registered fonts.
module Pdfbox::Pdmodel
  describe PDAppearanceContentStream do
    it "extends an indirect /Font resource dictionary instead of replacing it" do
      helvetica = Font::PDType1Font.new(Font::Standard14Fonts::FontName::HELVETICA)

      existing_fonts = Cos::Dictionary.new
      existing_fonts[Cos::Name.new("Helv")] = helvetica.cos_object
      resources = PDResources.new(Cos::Dictionary.new)
      resources.cos_object.as(Cos::Dictionary)[Cos::Name.new("Font")] =
        Cos::Object.new(existing_fonts)

      stream = Interactive::Annotation::PDAppearanceStream.new(Cos::Stream.new)
      stream.resources = resources

      cs = PDAppearanceContentStream.new(stream, ::IO::Memory.new)
      cs.set_font(helvetica, 12.0)
      cs.close

      fonts = resources.cos_object.as(Cos::Dictionary)
        .get_dictionary(Cos::Name.new("Font")).not_nil!
      # The loaded key is kept (Java returns the existing resource name)...
      fonts.entries.keys.map(&.value).should eq(["Helv"])
      fonts[Cos::Name.new("Helv")]?.should_not be_nil
    end
  end
end
