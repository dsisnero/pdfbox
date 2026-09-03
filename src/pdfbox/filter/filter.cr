module Pdfbox::Filter
  class Filter
    def decode(_encoded : Bytes) : Bytes
      raise NotImplementedError.new("decode must be implemented by subclasses")
    end

    def encode(_input : Bytes) : Bytes
      raise NotImplementedError.new("encode must be implemented by subclasses")
    end

    # Decode with stream parameters. The default implementation ignores the
    # parameters and delegates to decode(Bytes); filters that need DecodeParms
    # (e.g. CCITTFaxFilter) override this.
    def decode(encoded : Bytes, _decode_params : Pdfbox::Cos::Dictionary?, _width : Int32 = 0, _height : Int32 = 0) : Bytes
      decode(encoded)
    end

    # Java parity: Filter.decode must reject an empty filter list.
    def self.decode(input : Bytes, filters : Array(Filter), _decode_params : Pdfbox::Cos::Dictionary, _index = nil, _options = nil) : Bytes
      raise ArgumentError.new("filters must not be empty") if filters.empty?
      decoded = input
      filters.each { |filter| decoded = filter.decode(decoded) }
      decoded
    end

    # Fallback overload kept for parity with generic callers.
    def self.decode(_input, filters : Array(T), _decode_params : Pdfbox::Cos::Dictionary, _index = nil, _options = nil) : Nil forall T
      raise ArgumentError.new("filters must not be empty") if filters.empty?
      raise NotImplementedError.new("Filter.decode dispatch is only implemented for Array(Filter)")
    end
  end
end
