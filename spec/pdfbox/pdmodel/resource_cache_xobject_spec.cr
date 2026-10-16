require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/DefaultResourceCache.java
#     getXObject/put(COSObject, PDXObject)/removeXObject.
module Pdfbox::Pdmodel
  describe ResourceCache do
    it "caches XObjects (Java getXObject/put/removeXObject)" do
      cache = ResourceCache.new
      key = Cos::Object.new(1_i64, 0_i64, Cos::Dictionary.new)
      stream = Cos::Stream.new
      stream.set_name(Cos::Name.new("Subtype"), "Image")
      xobject = Graphics::Image::PDImageXObject.new(nil, stream, stream)

      cache.get_xobject(key).should be_nil
      cache.put(key, xobject)
      cache.get_xobject(key).should be(xobject)
      cache.remove_xobject(key).should be(xobject)
      cache.get_xobject(key).should be_nil
    end
  end
end
