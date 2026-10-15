require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDDocument.java
#     getResourceCache/setResourceCache (default is a fresh in-memory cache;
#     setResourceCache accepts null).
module Pdfbox::Pdmodel
  describe Document do
    it "defaults to an in-memory resource cache (Java PDDocument field)" do
      Document.create.resource_cache.should be_a(ResourceCache)
    end

    it "replaces and clears the resource cache (Java get/setResourceCache)" do
      doc = Document.create
      custom = ResourceCache.new
      doc.resource_cache = custom
      doc.resource_cache.should be(custom)

      doc.resource_cache = nil
      doc.resource_cache.should be_nil
    end
  end
end
