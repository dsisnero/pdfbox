# PDF 1.5+ Xref stream writer
# Similar to Apache PDFBox PDFXRefStream
require "../cos"
require "./xref/xreference_entry"
require "./xref/free_xreference"
require "compress/deflate"

module Pdfbox::Pdfparser
  # XRef stream writer for PDF 1.5+ files
  class PDFXRefStream
    Log = ::Log.for(self)

    @stream_data : Array(Xref::XReferenceEntry)
    @object_numbers : Set(Int64)
    @stream : Cos::Stream
    @size : Int64 = -1_i64

    # Create a fresh XRef stream like for a fresh file or an incremental update
    def initialize
      @stream_data = [] of Xref::XReferenceEntry
      @object_numbers = Set(Int64).new
      @stream = Cos::Stream.new
    end

    # Returns the stream of the XRef
    def stream : Cos::Stream
      @stream[Cos::Name.new("Type")] = Cos::Name.new("XRef")
      if @size == -1
        raise ArgumentError.new("size is not set in xrefstream")
      end
      @stream[Cos::Name.new("Size")] = Cos::Integer.new(@size)

      index_entry = get_index_entry
      index_array = Cos::Array.new
      index_entry.each do |i|
        index_array.add(Cos::Integer.new(i))
      end
      @stream[Cos::Name.new("Index")] = index_array

      w_entry = get_w_entry
      w_array = Cos::Array.new
      w_entry.each do |j|
        w_array.add(Cos::Integer.new(j))
      end
      @stream[Cos::Name.new("W")] = w_array

      # Create compressed stream data
      io = IO::Memory.new
      write_stream_data(io, w_entry)

      # Compress with FlateDecode
      compressed = Compress::Deflate.compress(io.to_slice)
      @stream.data = compressed
      @stream[Cos::Name.new("Filter")] = Cos::Name.new("FlateDecode")

      # Set direct flag for certain entries
      @stream.entries.each_key do |key|
        if [Cos::Name.new("Root"), Cos::Name.new("Info"), Cos::Name.new("Prev"), Cos::Name.new("Encrypt")].includes?(key)
          next
        end
        value = @stream[key]?
        value.set_direct(true) if value
      end

      @stream
    end

    # Copy all Trailer Information to this file
    def add_trailer_info(trailer_dict : Cos::Dictionary)
      trailer_dict.entries.each do |key, value|
        if [Cos::Name.new("Info"), Cos::Name.new("Root"), Cos::Name.new("Encrypt"),
            Cos::Name.new("ID"), Cos::Name.new("Prev")].includes?(key)
          @stream[key] = value
        end
      end
    end

    # Add a new entry to the XRef stream
    def add_entry(entry : Xref::XReferenceEntry)
      obj_num = entry.referenced_key.number
      return if @object_numbers.includes?(obj_num)
      @object_numbers.add(obj_num)
      @stream_data << entry
    end

    # Set the size of the XRef stream
    def set_size(stream_size : Int64) : Nil
      @size = stream_size
    end

    private def get_w_entry : Array(Int32)
      w_max = [0_i64, 0_i64, 0_i64]
      @stream_data.each do |entry|
        w_max[0] = Math.max(w_max[0], entry.first_column_value)
        w_max[1] = Math.max(w_max[1], entry.second_column_value)
        w_max[2] = Math.max(w_max[2], entry.third_column_value)
      end
      # Also include null entry (object 0)
      null_entry = Xref::FreeXReference::NULL_ENTRY
      w_max[0] = Math.max(w_max[0], null_entry.first_column_value)
      w_max[1] = Math.max(w_max[1], null_entry.second_column_value)
      w_max[2] = Math.max(w_max[2], null_entry.third_column_value)

      # Find the max bytes needed to display that column
      w = [0_i32, 0_i32, 0_i32]
      3.times do |i|
        while w_max[i] > 0
          w[i] += 1
          w_max[i] >>= 8
        end
      end
      w
    end

    private def get_index_entry : Array(Int64)
      # Add object number 0 to the set
      obj_numbers = @object_numbers.dup
      obj_numbers.add(0_i64)
      sorted_numbers = obj_numbers.to_a.sort

      return [0_i64, sorted_numbers.size.to_i64] if sorted_numbers.empty?

      result = [] of Int64
      first = sorted_numbers.first
      length = 1_i64

      sorted_numbers.each_with_index do |obj_number, idx|
        next if idx == 0 # already processed as first

        if first + length == obj_number
          length += 1
        else
          # gap detected, add current range and start new
          result << first << length
          first = obj_number
          length = 1_i64
        end
      end

      # Add final range
      result << first << length
      result
    end

    private def write_number(io : IO, number : Int64, bytes : Int32) : Nil
      return if bytes <= 0
      buffer = Bytes.new(bytes)
      temp = number
      bytes.times do |i|
        buffer[i] = (temp & 0xff).to_u8
        temp >>= 8
      end

      # Write in big-endian order
      (bytes - 1).downto(0) do |i|
        io.write_byte(buffer[i])
      end
    end

    private def write_stream_data(io : IO, w : Array(Int32)) : Nil
      # Sort entries
      @stream_data.sort!

      # Write null entry (object 0)
      null_entry = Xref::FreeXReference::NULL_ENTRY
      write_number(io, null_entry.first_column_value, w[0])
      write_number(io, null_entry.second_column_value, w[1])
      write_number(io, null_entry.third_column_value, w[2])

      # Write all entries
      @stream_data.each do |entry|
        write_number(io, entry.first_column_value, w[0])
        write_number(io, entry.second_column_value, w[1])
        write_number(io, entry.third_column_value, w[2])
      end
    end
  end
end
