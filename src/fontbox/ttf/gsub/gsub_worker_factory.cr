# Gets a `Language` specific instance of a `GsubWorker`
#
# Ported from Apache PDFBox GsubWorkerFactory.
module Fontbox::TTF::Gsub
  class GsubWorkerFactory
    Log = ::Log.for(self)

    # Gets a language-specific GsubWorker.
    #
    # @param cmap_lookup [CmapLookup] provides glyph ID lookup (CmapLookup interface)
    # @param gsub_data [::Fontbox::TTF::Model::GsubData] GSUB data for the font
    # @return [GsubWorker] language-specific worker or DefaultGsubWorker
    def get_gsub_worker(cmap_lookup : CmapLookup, gsub_data : ::Fontbox::TTF::Model::GsubData) : GsubWorker
      # TODO: this needs to be redesigned / improved because if a font supports several languages,
      # it will choose one of them and maybe not the one expected.
      # See also PDFBOX-5700 and PDFBOX-5729
      # For example, NotoSans-Regular hits Devanagari first
      # See also GlyphSubstitutionDataExtractor.getSupportedLanguage() which decides the language?!
      language = gsub_data.get_language
      Log.debug { "Language: #{language}" }

      case language
      when ::Fontbox::TTF::Model::Language::BENGALI
        GsubWorkerForBengali.new(cmap_lookup, gsub_data)
      when ::Fontbox::TTF::Model::Language::DEVANAGARI
        GsubWorkerForDevanagari.new(cmap_lookup, gsub_data)
      when ::Fontbox::TTF::Model::Language::GUJARATI
        GsubWorkerForGujarati.new(cmap_lookup, gsub_data)
      when ::Fontbox::TTF::Model::Language::LATIN
        GsubWorkerForLatin.new(gsub_data)
      when ::Fontbox::TTF::Model::Language::DFLT
        GsubWorkerForDflt.new(gsub_data)
      when ::Fontbox::TTF::Model::Language::TAMIL
        GsubWorkerForTamil.new(cmap_lookup, gsub_data)
      else
        DefaultGsubWorker.new
      end
    end
  end
end
