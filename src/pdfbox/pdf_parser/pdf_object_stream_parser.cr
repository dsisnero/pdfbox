require "log"
require "../cos"
require "../io"
require "./cos_parser"

module Pdfbox::Pdfparser
  # PDF 1.5 object stream parser that extracts objects from compressed object streams
  # Similar to Apache PDFBox PDFObjectStreamParser
  class PDFObjectStreamParser < COSParser
    Log = ::Log.for(self)

    @number_of_objects : Int32
    @first_object : Int32

    # Constructor.
    # @param stream The stream to parse.
    # @param parser The main parser (provides object pool and xref table)
    def initialize(stream : Pdfbox::Cos::Stream, parser : Parser)
      # Create a view of the decoded stream data
      Log.debug { "PDFObjectStreamParser initialize: stream.data size = #{stream.data.size}" }
      Log.debug { "PDFObjectStreamParser initialize: stream dictionary keys: #{stream.entries.keys.map(&.value)}" }
      if stream.has_key?(Pdfbox::Cos::Name.new("Filter"))
        filter_entry = stream[Pdfbox::Cos::Name.new("Filter")]
        Log.debug { "PDFObjectStreamParser initialize: Filter = #{filter_entry.inspect}" }
      end
      if stream.has_key?(Pdfbox::Cos::Name.new("DecodeParms"))
        decode_entry = stream[Pdfbox::Cos::Name.new("DecodeParms")]
        Log.debug { "PDFObjectStreamParser initialize: DecodeParms = #{decode_entry.inspect}" }
      end
      data = parser.decode_stream_data(stream)
      Log.debug { "PDFObjectStreamParser initialize: decoded data size = #{data.size}" }
      Log.debug { "PDFObjectStreamParser initialize: first 20 bytes of decoded data: #{data[0, Math.min(20, data.size)].hexstring}" } if data.size > 0
      if data.size == 0
        Log.error { "PDFObjectStreamParser initialize: DECODED DATA IS EMPTY!" }
      end
      source = Pdfbox::IO::MemoryRandomAccessRead.new(data)
      super(source, parser)

      # Get mandatory number of objects
      n_entry = stream[Pdfbox::Cos::Name.new("N")]
      unless n_entry && n_entry.is_a?(Pdfbox::Cos::Integer)
        raise ::IO::Error.new("/N entry missing in object stream")
      end
      @number_of_objects = n_entry.value.to_i32
      if @number_of_objects < 0
        raise ::IO::Error.new("Illegal /N entry in object stream: #{@number_of_objects}")
      end

      # Get mandatory stream offset of the first object
      first_entry = stream[Pdfbox::Cos::Name.new("First")]
      unless first_entry && first_entry.is_a?(Pdfbox::Cos::Integer)
        raise ::IO::Error.new("/First entry missing in object stream")
      end
      @first_object = first_entry.value.to_i32
      if @first_object < 0
        raise ::IO::Error.new("Illegal /First entry in object stream: #{@first_object}")
      end
    end

    # Search for/parse the object with the given object number.
    # The stream is closed after parsing the object with the given number.
    # @param object_number the number of the object to be parsed
    # @return the parsed object or nil if the object with the given number can't be found
    def parse_object(object_number : Int64) : Pdfbox::Cos::Base?
      stream_object = nil
      begin
        object_offset = private_read_object_numbers[object_number]?
        if object_offset
          # jump to the offset of the first object
          current_position = source.position
          if @first_object > 0 && current_position < @first_object
            source.skip(@first_object - current_position.to_i32)
          end
          # jump to the offset of the object to be parsed
          source.skip(object_offset)
          stream_object = parse_dir_object
          if stream_object
            stream_object.set_direct(false)
          end
        end
      ensure
        source.close
        # document = nil (not needed)
      end
      stream_object
    end

    # Parse all compressed objects. The stream is closed after parsing.
    # @return a map containing all parsed objects using the object number as key
    def parse_all_objects : Hash(Pdfbox::Cos::ObjectKey, Pdfbox::Cos::Base)
      all_objects = {} of Pdfbox::Cos::ObjectKey => Pdfbox::Cos::Base
      begin
        object_numbers = private_read_object_offsets
        # count the number of object numbers eliminating double entries
        distinct_object_numbers = object_numbers.values.uniq!.size
        # the usage of the index should be restricted to cases where more than one
        # object use the same object number.
        index_needed = object_numbers.size > distinct_object_numbers
        current_position = source.position
        if @first_object > 0 && current_position < @first_object
          source.skip(@first_object - current_position.to_i32)
        end
        index = 0
        object_numbers.each do |offset, obj_number|
          object_key = get_object_key(obj_number, 0_i64)
          # skip object if the index doesn't match
          if index_needed && object_key.stream_index > -1 && object_key.stream_index != index
            index += 1
            next
          end
          final_position = @first_object + offset
          current_position = source.position
          if final_position > 0 && current_position < final_position
            # jump to the offset of the object to be parsed
            source.skip(final_position - current_position.to_i32)
          end
          stream_object = parse_dir_object
          if stream_object.nil?
            stream_object = Pdfbox::Cos::Null.instance
          else
            stream_object.set_direct(false)
          end
          all_objects[object_key] = stream_object.as(Pdfbox::Cos::Base)
          index += 1
        end
      ensure
        source.close
        # document = nil
      end
      all_objects
    end

    private def private_read_object_numbers : Hash(Int64, Int32)
      # don't initialize map using @number_of_objects as there might be less object numbers than expected
      object_numbers = {} of Int64 => Int32
      first_object_position = source.position + @first_object - 1
      @number_of_objects.times do |_|
        # don't read beyond the part of the stream reserved for the object numbers
        break if source.position >= first_object_position
        object_number = read_object_number
        offset = read_long.to_i32
        object_numbers[object_number] = offset
      end
      object_numbers
    end

    private def private_read_object_offsets : Hash(Int32, Int64)
      # according to the pdf spec the offsets shall be sorted ascending
      # but we can't rely on that, so we have to sort the offsets
      # as the sequential parsers relies on it
      Log.debug { "private_read_object_offsets: START, number_of_objects=#{@number_of_objects}, first_object=#{@first_object}, source.position=#{source.position}" }
      object_offsets = {} of Int32 => Int64
      first_object_position = source.position + @first_object - 1
      Log.debug { "private_read_object_offsets: first_object_position=#{first_object_position}" }
      @number_of_objects.times do |i|
        break if source.position >= first_object_position
        Log.debug { "private_read_object_offsets: iteration #{i}, position before read=#{source.position}" }
        object_number = read_object_number
        Log.debug { "private_read_object_offsets: read object_number=#{object_number}" }
        offset = read_long.to_i32
        Log.debug { "private_read_object_offsets: read offset=#{offset}" }
        object_offsets[offset] = object_number
      end
      # sort by offset (key)
      sorted = object_offsets.to_a.sort_by { |offset, _| offset }
      Log.debug { "private_read_object_offsets: read #{object_offsets.size} object offsets" }
      Hash(Int32, Int64).new.tap do |hash|
        sorted.each { |offset, obj| hash[offset] = obj }
      end
    end

    # Read all object numbers from the compressed object stream.
    # The stream is closed after reading the object numbers.
    # @return a map of all object numbers and the corresponding offset within the object stream.
    def read_object_numbers : Hash(Int64, Int32)
      object_numbers = nil
      begin
        object_numbers = private_read_object_numbers
      ensure
        source.close
        # document = nil
      end
      object_numbers
    end
  end
end
