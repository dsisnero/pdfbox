# CMap resource loader and cache.
# Corresponds to CMapManager in Apache PDFBox.
require "../../../fontbox/cmap/cmap_parser"

module Pdfbox::Pdmodel::Font
  class CMapManager
    @@cache = {} of String => Fontbox::CMap::CMap
    @@mutex = Mutex.new

    # Fetches the predefined CMap from disk (or cache).
    def self.get_predefined_cmap(c_map_name : String) : Fontbox::CMap::CMap
      @@mutex.synchronize do
        cached = @@cache[c_map_name]?
        return cached if cached
      end

      parser = Fontbox::CMap::CMapParser.new
      target_cmap = parser.parse_predefined(c_map_name)

      @@mutex.synchronize do
        @@cache[target_cmap.name || c_map_name] = target_cmap
      end
      target_cmap
    end

    # Parse the given CMap.
    def self.parse_cmap(random_access_read : Pdfbox::IO::RandomAccessRead?) : Fontbox::CMap::CMap?
      return if random_access_read.nil?

      parser = Fontbox::CMap::CMapParser.new
      parser.parse(random_access_read)
    end
  end
end
