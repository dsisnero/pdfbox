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

    def encode(input : Bytes) : Bytes
      output = ::IO::Memory.new
      writer = Compress::Zlib::Writer.new(output)
      writer.write(input)
      writer.close
      output.to_slice
    end
  end
end
