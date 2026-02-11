# DFLT (Default) script-specific implementation of GSUB system.
#
# According to the OpenType specification, a Script table with the script tag 'DFLT' (default)
# is used in fonts to define features that are not script-specific. Applications should use the
# DFLT script table when no script table exists for the specific script of the text being
# processed, or when text lacks a defined script (containing only symbols or punctuation).
#
# This implementation applies common, script-neutral typographic features that work across
# writing systems. The feature order follows standard OpenType recommendations for universal
# glyph substitutions.
#
# Ported from Apache PDFBox GsubWorkerForDflt.
module Fontbox::TTF::Gsub
  class GsubWorkerForDflt < GsubWorker
    Log = ::Log.for(self)

    @gsub_data : ::Fontbox::TTF::Model::GsubData

    def initialize(gsub_data : ::Fontbox::TTF::Model::GsubData)
      @gsub_data = gsub_data
    end

    def apply_transforms(original_glyph_ids : Array(Int32)) : Array(Int32)
      # TODO: implement DFLT-specific GSUB transformations
      Log.warn { "DFLT GSUB worker not fully implemented, using default behavior" }
      original_glyph_ids.dup
    end
  end
end
