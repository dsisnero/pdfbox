require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPage.java
#     getUserUnit/setUserUnit and getViewports/setViewports.
module Pdfbox::Pdmodel
  describe Page do
    it "defaults the user unit to 1.0 and round-trips it (Java getUserUnit/setUserUnit)" do
      page = Page.new
      page.user_unit.should eq(1.0_f32)

      page.user_unit = 2.5_f32
      page.user_unit.should eq(2.5_f32)
    end

    it "returns 1.0 for a non-positive user unit (Java getUserUnit clamp)" do
      dict = Cos::Dictionary.new
      dict[Cos::Name.new("UserUnit")] = Cos::Float.new(0.0)
      Page.new(dict).user_unit.should eq(1.0_f32)
    end

    it "raises for a non-positive user unit (Java setUserUnit)" do
      page = Page.new
      expect_raises(ArgumentError, "User unit must be positive") do
        page.user_unit = 0.0_f32
      end
    end

    it "round-trips the viewports and clears on nil (Java get/setViewports)" do
      page = Page.new
      page.viewports.should be_nil

      viewport = Interactive::Measurement::PDViewportDictionary.new
      page.viewports = [viewport]
      page.viewports.not_nil!.size.should eq(1)
      page.viewports.not_nil!.first.cos_object.should be(viewport.cos_object)

      page.viewports = nil
      page.viewports.should be_nil
    end
  end
end
