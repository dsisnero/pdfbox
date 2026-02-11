# Gujarati-specific implementation of GSUB system
#
# Ported from Apache PDFBox GsubWorkerForGujarati.
module Fontbox::TTF::Gsub
  class GsubWorkerForGujarati < GsubWorker
    Log = ::Log.for(self)

    @cmap_lookup : CmapLookup
    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData)
      @cmap_lookup = cmap_lookup
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      # TODO: implement Gujarati-specific GSUB transformations
      Log.warn { "Gujarati GSUB worker not fully implemented, using default behavior" }
      original_glyph_ids.dup
    end
  end
end
