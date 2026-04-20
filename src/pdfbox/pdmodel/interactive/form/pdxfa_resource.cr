require "xml"

module Pdfbox::Pdmodel::Interactive::Form
  class PDXFAResource
    @xfa : Cos::Base

    def initialize(@xfa : Cos::Base)
    end

    def cos_object : Cos::Base
      @xfa
    end

    def bytes : Bytes
      case base = dereference(@xfa)
      when Cos::Array
        bytes_from_packet(base)
      when Cos::Stream
        bytes_from_stream(base)
      else
        Bytes.empty
      end
    end

    def document : XML::Node
      XML.parse(String.new(bytes))
    end

    private def bytes_from_packet(cos_array : Cos::Array) : Bytes
      io = ::IO::Memory.new
      index = 1
      while index < cos_array.items.size
        stream = dereference(cos_array[index]?).as?(Cos::Stream)
        io.write(bytes_from_stream(stream)) if stream
        index += 2
      end
      io.to_slice
    end

    private def bytes_from_stream(stream : Cos::Stream) : Bytes
      io = stream.create_input_stream
      io.getb_to_end
    end

    private def dereference(base : Cos::Base?) : Cos::Base?
      case base
      when Cos::Object
        base.object
      else
        base
      end
    end
  end
end
