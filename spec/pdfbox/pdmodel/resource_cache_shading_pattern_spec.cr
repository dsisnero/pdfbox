require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/DefaultResourceCache.java
#     getShading/put/removeShading and getPattern/put/removePattern.
module Pdfbox::Pdmodel
  describe ResourceCache do
    it "caches shadings (Java getShading/put/removeShading)" do
      cache = ResourceCache.new
      key = Cos::Object.new(1_i64, 0_i64, Cos::Dictionary.new)
      shading = Graphics::Shading::PDShadingType1.new(Cos::Dictionary.new)

      cache.get_shading(key).should be_nil
      cache.put(key, shading)
      cache.get_shading(key).should be(shading)
      cache.remove_shading(key).should be(shading)
      cache.get_shading(key).should be_nil
    end

    it "caches patterns (Java getPattern/put/removePattern)" do
      cache = ResourceCache.new
      key = Cos::Object.new(1_i64, 0_i64, Cos::Dictionary.new)
      stream = Cos::Stream.new
      stream.set_int(Cos::Name.new("PatternType"), 1)
      pattern = Graphics::Pattern::PDTilingPattern.new(stream)

      cache.get_pattern(key).should be_nil
      cache.put(key, pattern)
      cache.get_pattern(key).should be(pattern)
      cache.remove_pattern(key).should be(pattern)
      cache.get_pattern(key).should be_nil
    end
  end
end
