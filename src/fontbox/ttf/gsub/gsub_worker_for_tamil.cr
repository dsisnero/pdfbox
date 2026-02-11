# Tamil-specific implementation of GSUB system (not yet implemented)
#
# Ported from Apache PDFBox GsubWorkerForTamil (TODO).
module Fontbox::TTF::Gsub
  class GsubWorkerForTamil < GsubWorker
    Log = ::Log.for(self)

    @cmap_lookup : CmapLookup
    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData)
      @cmap_lookup = cmap_lookup
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      Log.warn { "Tamil GSUB worker not implemented, using default behavior" }
      original_glyph_ids.dup
    end
  end
end
