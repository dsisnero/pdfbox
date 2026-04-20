# CMap resource loader and cache.
# Corresponds to CMapManager in Apache PDFBox.
require "../../../fontbox/cmap/cmap_parser"

module Pdfbox::Pdmodel::Font
  class CMapManager
    private getter cache : Hash(String, Fontbox::CMap::CMap)

    # Singleton instance
    @@instance : CMapManager?

    private def initialize
      @cache = {} of String => Fontbox::CMap::CMap
    end

    def self.instance : CMapManager
      @@instance ||= new
    end

    # Fetches the predefined CMap from disk (or cache).
    #
    # @param c_map_name CMap name
    # @return The predefined CMap, never nil.
    # @raises ::IO::Error if the CMap cannot be loaded
    def self.get_predefined_cmap(c_map_name : String) : Fontbox::CMap::CMap
      instance.get_predefined_cmap(c_map_name)
    end

    # Parse the given CMap.
    #
    # @param random_access_read the source of the CMap to be read
    # @return the parsed CMap, or nil if random_access_read is nil
    # @raises ::IO::Error if parsing fails
    def self.parse_cmap(random_access_read : Pdfbox::IO::RandomAccessRead?) : Fontbox::CMap::CMap?
      instance.parse_cmap(random_access_read)
    end

    protected def get_predefined_cmap(c_map_name : String) : Fontbox::CMap::CMap
      cached = @cache[c_map_name]?
      return cached if cached

      parser = Fontbox::CMap::CMapParser.new
      target_cmap = parser.parse_predefined(c_map_name)

      # limit the cache to predefined CMaps
      @cache[target_cmap.name || c_map_name] = target_cmap
      target_cmap
    end

    protected def parse_cmap(random_access_read : Pdfbox::IO::RandomAccessRead?) : Fontbox::CMap::CMap?
      return if random_access_read.nil?

      parser = Fontbox::CMap::CMapParser.new
      parser.parse(random_access_read)
    end
  end
end
