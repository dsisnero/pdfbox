module Pdfbox::Filter
  class FlateFilter < Filter
    def decode(encoded : Bytes) : Bytes
      io = ::IO::Memory.new(encoded)
      reader = Compress::Zlib::Reader.new(io)
      output = ::IO::Memory.new
      ::IO.copy(reader, output)
      reader.close
      output.to_slice
    end

    # Java FlateFilter#decode applies the DecodeParms predictor after inflation.
    def decode(encoded : Bytes, decode_params : Pdfbox::Cos::Dictionary?, _width : Int32 = 0, _height : Int32 = 0) : Bytes
      Predictor.decode_data(decode(encoded), decode_params)
    end

    def encode(input : Bytes) : Bytes
      output = ::IO::Memory.new
      writer = Compress::Zlib::Writer.new(output)
      writer.write(input)
      writer.close
      output.to_slice
    end
  end
end
