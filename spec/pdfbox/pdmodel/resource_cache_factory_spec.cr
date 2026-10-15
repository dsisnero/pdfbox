require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/ResourceCacheFactory.java
#     createResourceCache/getResourceCacheCreateFunction/setResourceCacheCreateFunction
#     and the DefaultResourceCacheCreateImpl default.
module Pdfbox::Pdmodel
  describe ResourceCacheFactory do
    it "creates a default resource cache (Java createResourceCache)" do
      ResourceCacheFactory.create_resource_cache.should be_a(ResourceCache)
    end

    it "disables caching when the function is nil (Java setResourceCacheCreateFunction(null))" do
      original = ResourceCacheFactory.resource_cache_create_function
      begin
        ResourceCacheFactory.resource_cache_create_function = nil
        ResourceCacheFactory.create_resource_cache.should be_nil
      ensure
        ResourceCacheFactory.resource_cache_create_function = original
      end
    end

    it "uses a custom create function when set (Java setResourceCacheCreateFunction)" do
      original = ResourceCacheFactory.resource_cache_create_function
      begin
        custom = ResourceCache.new
        ResourceCacheFactory.resource_cache_create_function = FixedCacheCreate.new(custom)
        ResourceCacheFactory.create_resource_cache.should be(custom)
      ensure
        ResourceCacheFactory.resource_cache_create_function = original
      end
    end
  end

  # Test helper create function.
  class FixedCacheCreate < ResourceCacheCreateFunction
    def initialize(@cache : ResourceCache)
    end

    def create : ResourceCache?
      @cache
    end
  end
end
