module Pdfbox::Filter
  class FilterFactory
    INSTANCE = new

    @filters : Hash(String, Filter)

    def initialize
      @filters = {
        "FlateDecode"     => FlateFilter.new.as(Filter),
        "ASCII85Decode"   => ASCII85Filter.new.as(Filter),
        "RunLengthDecode" => RunLengthDecodeFilter.new.as(Filter),
        "LZWDecode"       => LZWFilter.new.as(Filter),
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
      raise ArgumentError.new("Unknown filter: #{name.value}") unless found
      found
    end

    def get_filter(name : Pdfbox::Cos::Name) : Filter
      filter(name)
    end
  end
end
