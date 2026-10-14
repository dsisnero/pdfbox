require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPage.java
#
# Characterization spec: upstream has no dedicated test for the bleed/trim/art
# boxes or page additional actions, so these assertions are inferred from the
# Java observable behavior.
private def page_rect_array(llx : Float64, lly : Float64, urx : Float64, ury : Float64) : Pdfbox::Cos::Array
  Pdfbox::Cos::Array.new([
    Pdfbox::Cos::Float.new(llx),
    Pdfbox::Cos::Float.new(lly),
    Pdfbox::Cos::Float.new(urx),
    Pdfbox::Cos::Float.new(ury),
  ])
end

module Pdfbox::Pdmodel
  describe Page do
    it "falls back to the crop box when bleed/trim/art are unset" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("MediaBox")] = page_rect_array(0.0, 0.0, 612.0, 792.0)
      dict[Cos::Name.new("CropBox")] = page_rect_array(10.0, 10.0, 600.0, 780.0)

      page = Page.new(dict)
      page.bleed_box.not_nil!.to_a.should eq([10.0, 10.0, 600.0, 780.0])
      page.trim_box.not_nil!.to_a.should eq([10.0, 10.0, 600.0, 780.0])
      page.art_box.not_nil!.to_a.should eq([10.0, 10.0, 600.0, 780.0])
    end

    it "clips a set box to the media box" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("MediaBox")] = page_rect_array(0.0, 0.0, 612.0, 792.0)
      dict[Cos::Name.new("BleedBox")] = page_rect_array(-10.0, -20.0, 700.0, 800.0)

      page = Page.new(dict)
      page.bleed_box.not_nil!.to_a.should eq([0.0, 0.0, 612.0, 792.0])
    end

    it "round-trips the bleed/trim/art box setters and clears on nil" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("MediaBox")] = page_rect_array(0.0, 0.0, 612.0, 792.0)
      page = Page.new(dict)

      page.bleed_box = Rectangle.new(1.0, 2.0, 3.0, 4.0)
      page.bleed_box.not_nil!.to_a.should eq([1.0, 2.0, 3.0, 4.0])

      page.trim_box = Rectangle.new(5.0, 6.0, 7.0, 8.0)
      page.trim_box.not_nil!.to_a.should eq([5.0, 6.0, 7.0, 8.0])

      page.art_box = Rectangle.new(9.0, 10.0, 11.0, 12.0)
      page.art_box.not_nil!.to_a.should eq([9.0, 10.0, 11.0, 12.0])

      page.bleed_box = nil
      page.cos_object.not_nil![Cos::Name.new("BleedBox")]?.should be_nil
      # with /BleedBox cleared it falls back to the crop box, which here is the media box
      page.bleed_box.not_nil!.to_a.should eq([0.0, 0.0, 612.0, 792.0])
    end

    it "exposes page additional actions, creating /AA lazily" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("MediaBox")] = page_rect_array(0.0, 0.0, 612.0, 792.0)
      page = Page.new(dict)

      actions = page.actions
      actions.should be_a(Interactive::Action::PDPageAdditionalActions)
      page.cos_object.not_nil![Cos::Name.new("AA")].should_not be_nil

      # assignments go through the same object
      page.actions = actions
      page.actions.cos_object.should be(actions.cos_object)
    end
  end
end
