# PDStream represents a stream in a PDF document.
# Streams are tied to a single PDF document.
module Pdfbox::Pdmodel::Common
  class PDStream
    @stream : Cos::Stream

    # Creates a PDStream which wraps the given COSStream
    def initialize(@stream : Cos::Stream)
    end

    # Get the cos stream associated with this object
    def cos_object : Cos::Stream
      @stream
    end

    # This will get a stream that can be written to
    def create_output_stream : IO
      @stream.create_output_stream
    end

    # This will get a stream that can be written to, with the given filter
    def create_output_stream(filter : Cos::Name) : IO
      @stream.create_output_stream(filter)
    end

    # This will get a stream that can be read from
    def create_input_stream : IO
      @stream.create_input_stream
    end

    # This will get the length of the filtered/compressed stream
    def length : Int32
      @stream.get_int(Cos::Name::LENGTH, 0).to_i32
    end

    # This will get the list of filters that are associated with this stream
    # Returns an empty array if there are no filters
    def filters : Array(Cos::Name)
      filters_base = @stream[Cos::Name::FILTER]

      case filters_base
      when Cos::Name
        [filters_base]
      when Cos::Array
        filters_base.items.map { |item| item.as(Cos::Name) }
      else
        [] of Cos::Name
      end
    end

    # This will set the filters that are part of this stream
    def filters=(filters : Array(Cos::Name))
      @stream[Cos::Name::FILTER] = Cos::Array.new(filters)
    end

    # This will copy the stream into a byte array
    def to_byte_array : Bytes
      io = create_input_stream
      io.getb_to_end
    end
  end
end
