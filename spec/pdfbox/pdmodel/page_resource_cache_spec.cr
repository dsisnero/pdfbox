require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDPage.java
#     removePageResourceFromCache/removeResources/getIndirectResourceObjects.
module Pdfbox::Pdmodel
  describe Page do
    it "removes page resources from the cache (Java removePageResourceFromCache)" do
      cache = ResourceCache.new
      page = Page.new
      page.resource_cache = cache

      ref = Cos::Object.new(1_i64, 0_i64, Cos::Dictionary.new)
      color_spaces = Cos::Dictionary.new
      color_spaces[Cos::Name.new("CS1")] = ref
      resources = Cos::Dictionary.new
      resources[Cos::Name.new("ColorSpace")] = color_spaces
      page.cos_object.not_nil![Cos::Name.new("Resources")] = resources

      cache.put(ref, Graphics::Color::PDDeviceRGB::INSTANCE)
      cache.get_color_space(ref).should_not be_nil

      page.remove_page_resource_from_cache
      cache.get_color_space(ref).should be_nil
    end

    it "is a no-op without a resource cache (Java removePageResourceFromCache)" do
      Page.new.remove_page_resource_from_cache
    end
  end
end
