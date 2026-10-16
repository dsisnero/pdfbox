require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/FontMapperImpl.java
#     private static final FontCache fontCache = new FontCache();
#     private static class DefaultFontProvider { INSTANCE = new FileSystemFontProvider(fontCache); }
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/font/FontMappers.java
#     private static class DefaultFontMapper { INSTANCE = new FontMapperImpl(); }
# The default provider/cache/mapper are process-wide singletons in Java. Upstream
# has no dedicated test; this is a characterization spec.
module Pdfbox::Pdmodel::Font
  describe FontMapperImpl do
    it "shares the font cache across mapper instances (Java static fontCache)" do
      a = FontMapperImpl.new
      b = FontMapperImpl.new

      a.font_cache.should be(b.font_cache)
    end

    it "returns the same lazily-created default provider for every mapper" do
      a = FontMapperImpl.new
      b = FontMapperImpl.new

      a.provider.should be(b.provider)
      a.provider.should be(FontMapperImpl::DefaultFontProvider.instance)
    end
  end

  describe FontMappers do
    it "exposes a DefaultFontMapper singleton holder" do
      FontMappers::DefaultFontMapper.instance.should be(FontMappers::DefaultFontMapper.instance)
    end
  end
end
