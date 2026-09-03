module Pdfbox::Filter
  class FilterFactory
    INSTANCE = new

    @filters : Hash(String, Filter)

    def initialize
      flate = FlateFilter.new.as(Filter)
      ascii85 = ASCII85Filter.new.as(Filter)
      ascii_hex = ASCIIHexFilter.new.as(Filter)
      run_length = RunLengthDecodeFilter.new.as(Filter)
      lzw = LZWFilter.new.as(Filter)
      ccitt_fax = CCITTFaxFilter.new.as(Filter)
      dct = DCTFilter.new.as(Filter)
      @filters = {
        "Identity"        => IdentityFilter.new.as(Filter),
        "FlateDecode"     => flate,
        "ASCII85Decode"   => ascii85,
        "ASCIIHexDecode"  => ascii_hex,
        "RunLengthDecode" => run_length,
        "LZWDecode"       => lzw,
        "Crypt"           => CryptFilter.new.as(Filter),
        "CCITTFaxDecode"  => ccitt_fax,
        "DCTDecode"       => dct,
        # PDF 32000-1 table 6 filter abbreviations for the filters present in
        # the Crystal filter set (Java FilterFactory registers both the full
        # name and the abbreviation). JPX/JBIG2 filters are not in the Crystal
        # set yet, so their abbreviations are not registered.
        "A85" => ascii85,
        "AHx" => ascii_hex,
        "CCF" => ccitt_fax,
        "DCT" => dct,
        "Fl"  => flate,
        "LZW" => lzw,
        "RL"  => run_length,
      }
    end

    def all_filters : Array(Filter)
      @filters.values
    end

    # Java API compatibility wrapper.
    # ameba:disable Naming/AccessorMethodName
    def get_all_filters : Array(Filter)
      all_filters
    end

    # ameba:enable Naming/AccessorMethodName

    def filter(name : Pdfbox::Cos::Name) : Filter
      found = @filters[name.value]?
      raise ::IO::Error.new("Invalid filter: #{name.value}") unless found
      found
    end

    def get_filter(name : Pdfbox::Cos::Name) : Filter
      filter(name)
    end
  end
end
