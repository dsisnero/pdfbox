require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDResources.java
#
# Characterization spec: upstream has no dedicated test for these accessors, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel
  describe PDResources do
    it "reads color space, properties and shading entries" do
      dict = Pdfbox::Cos::Dictionary.new

      color_spaces = Pdfbox::Cos::Dictionary.new
      color_spaces[Pdfbox::Cos::Name.new("Cs1")] = Pdfbox::Cos::Name.new("DeviceRGB")
      dict[Pdfbox::Cos::Name.new("ColorSpace")] = color_spaces

      properties = Pdfbox::Cos::Dictionary.new
      ocg = Pdfbox::Cos::Dictionary.new
      ocg.set_name("Type", "OCG")
      ocg.set_string("Name", "Layer")
      properties[Pdfbox::Cos::Name.new("P1")] = ocg
      dict[Pdfbox::Cos::Name.new("Properties")] = properties

      shadings = Pdfbox::Cos::Dictionary.new
      shading = Pdfbox::Cos::Dictionary.new
      shading.set_int("ShadingType", 2)
      shadings[Pdfbox::Cos::Name.new("Sh1")] = shading
      dict[Pdfbox::Cos::Name.new("Shading")] = shadings

      resources = PDResources.new(dict)

      resources.color_space(Pdfbox::Cos::Name.new("Cs1")).should be_a(Graphics::Color::PDDeviceRGB)
      resources.color_space_names.should eq([Pdfbox::Cos::Name.new("Cs1")])
      resources.has_color_space?(Pdfbox::Cos::Name.new("Cs1")).should be_true
      resources.has_color_space?(Pdfbox::Cos::Name.new("Nope")).should be_false

      resources.properties(Pdfbox::Cos::Name.new("P1"))
        .should be_a(DocumentInterchange::MarkedContent::PDPropertyList)
      resources.properties_names.should eq([Pdfbox::Cos::Name.new("P1")])

      resources.shading_names.should eq([Pdfbox::Cos::Name.new("Sh1")])
    end
  end
end
