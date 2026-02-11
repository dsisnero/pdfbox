# Latin-specific implementation of GSUB system
#
# Ported from Apache PDFBox GsubWorkerForLatin.
module Fontbox::TTF::Gsub
  class GsubWorkerForLatin < GsubWorker
    Log = ::Log.for(self)

    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(gsub_data : ::Fontbox::TTF::Model::GsubData)
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      # TODO: implement Latin-specific GSUB transformations
      Log.warn { "Latin GSUB worker not fully implemented, using default behavior" }
      original_glyph_ids.dup
    end
  end
end
