# PDF 1.5+ Xref stream parser
# Similar to Apache PDFBox PDFXrefStreamParser
require "../cos"
require "./xref_trailer_resolver"
require "./xref/xreference_entry"
require "./xref/xreference_type"
require "./xref/free_xreference"
require "./xref/normal_xreference"
require "./xref/object_stream_xreference"

module Pdfbox::Pdfparser
  # Parse PDF 1.5 (or better) Xref stream and extract xref information
  class PDFXrefStreamParser
    Log = ::Log.for(self)

    @w = Array(Int32).new(3, 0)
    @object_numbers : ObjectNumbers?
    @data : Bytes

    # Constructor
    # @param stream The stream to parse
    def initialize(stream : Pdfbox::Cos::Stream, data : Bytes)
      @data = data
      init_parser_values(stream)
    end

    private def init_parser_values(stream : Pdfbox::Cos::Stream) : Nil
      dict = stream
      # Get /W array (required)
      w_entry = dict[Pdfbox::Cos::Name.new("W")]
      unless w_entry && w_entry.is_a?(Pdfbox::Cos::Array) && w_entry.size == 3
        raise SyntaxError.new("/W array missing or invalid in XRef stream")
      end

      w = [] of Int32
      w_entry.items.each do |item|
        unless item.is_a?(Pdfbox::Cos::Integer)
          raise SyntaxError.new("/W array element is not an integer")
        end
        w << item.value.to_i32
      end
      unless w.size == 3
        raise SyntaxError.new("/W array must have 3 elements, got #{w.size}")
      end
      if w[0] < 0 || w[1] < 0 || w[2] < 0
        raise SyntaxError.new("Incorrect /W array in XRef: #{w}")
      end
      if w[0] + w[1] + w[2] > 20
        # PDFBOX-6037
        raise SyntaxError.new("Incorrect /W array in XRef: #{w}")
      end
      @w = w

      # Get /Index array or default to [0, Size]
      size_entry = dict[Pdfbox::Cos::Name.new("Size")]
      unless size_entry && size_entry.is_a?(Pdfbox::Cos::Integer)
        raise SyntaxError.new("/Size missing in XRef stream")
      end
      size = size_entry.value

      index_array = Pdfbox::Cos::Array.new
      index_entry = dict[Pdfbox::Cos::Name.new("Index")]
      if index_entry && index_entry.is_a?(Pdfbox::Cos::Array)
        index_array = index_entry
      else
        # Default: [0, Size]
        index_array.add(Pdfbox::Cos::Integer.new(0))
        index_array.add(Pdfbox::Cos::Integer.new(size))
      end
      if index_array.size == 0 || index_array.size % 2 == 1
        raise SyntaxError.new("Wrong number of values for /Index array in XRef: #{@w}")
      end
      # Create iterator for all object numbers using the index array
      @object_numbers = ObjectNumbers.new(index_array)
    end

    # Parse through the unfiltered stream and populate the xrefTable HashMap
    # @param resolver resolver to read the xref/trailer information
    # @return Array of XReferenceEntry objects created during parsing
    def parse(resolver : XrefTrailerResolver) : Array(Xref::XReferenceEntry)
      curr_line = Bytes.new(@w[0] + @w[1] + @w[2])
      object_numbers = @object_numbers.as(ObjectNumbers)
      data_pos = 0
      total_entry_width = @w.sum
      entries = [] of Xref::XReferenceEntry

      while data_pos + total_entry_width <= @data.size
        # Get the current objID
        obj_id = object_numbers.next
        break if obj_id.is_a?(Iterator::Stop)

        # Read current line from data
        @data[data_pos, curr_line.size].copy_to(curr_line)
        data_pos += total_entry_width

        # Default value is 1 if w[0] == 0, otherwise parse first field
        type = @w[0] == 0 ? 1 : parse_value(curr_line, 0, @w[0]).to_i32

        # Second field holds the offset (type 1) or the object stream number (type 2)
        offset = parse_value(curr_line, @w[0], @w[1])
        # Third field may hold the generation number (type1) or the index within a object stream (type2)
        third_value = parse_value(curr_line, @w[0] + @w[1], @w[2]).to_i32

        case type
        when 0
          # Free entry - create FreeXReference
          key = Pdfbox::Cos::ObjectKey.new(obj_id.as(Int64), third_value)
          entries << Xref::FreeXReference.new(key, offset)
          # Add to resolver with offset 0
          resolver.add_xref(key, 0_i64)
        when 1
          # In-use entry - create NormalXReference
          key = Pdfbox::Cos::ObjectKey.new(obj_id.as(Int64), third_value)
          entries << Xref::NormalXReference.new(offset, key, nil)
          resolver.add_xref(key, offset)
        when 2
          # Compressed entry - create ObjectStreamXReference
          key = Pdfbox::Cos::ObjectKey.new(obj_id.as(Int64), 0, third_value.to_i32)
          parent_key = Pdfbox::Cos::ObjectKey.new(offset, 0)
          entries << Xref::ObjectStreamXReference.new(third_value.to_i32, key, parent_key, nil)
          # Store negative offset to indicate compressed entry
          resolver.add_xref(key, -offset)
        else
          raise SyntaxError.new("Invalid entry type #{type} for object #{obj_id}")
        end
      end
      entries
    end

    private def parse_value(data : Bytes, start : Int32, length : Int32) : Int64
      return 0_i64 if length == 0
      value = 0_i64
      length.times do |i|
        value = (value << 8) | (data[i + start] & 0xff).to_i64
      end
      value
    end

    # Iterator for object numbers based on /Index array
    private class ObjectNumbers
      include Iterator(Int64)

      @start : Array(Int64)
      @end : Array(Int64)
      @current_range = 0
      @current_end : Int64
      @current_number : Int64

      def initialize(index_array : Pdfbox::Cos::Array)
        size = index_array.size // 2
        @start = Array(Int64).new(size, 0_i64)
        @end = Array(Int64).new(size, 0_i64)
        counter = 0
        items = index_array.items

        0.step(to: items.size - 1, by: 2) do |i|
          start_item = items[i]
          unless start_item.is_a?(Pdfbox::Cos::Integer)
            raise SyntaxError.new("Xref stream must have integer in /Index array")
          end
          start_value = start_item.value

          if i + 1 >= items.size
            break
          end
          size_item = items[i + 1]
          unless size_item.is_a?(Pdfbox::Cos::Integer)
            raise SyntaxError.new("Xref stream must have integer in /Index array")
          end
          size_value = size_item.value

          @start[counter] = start_value
          @end[counter] = start_value + size_value
          counter += 1
        end

        @current_number = @start[0]
        @current_end = @end[0]
      end

      def has_next? : Bool
        if @start.size == 1
          return @current_number < @current_end
        end
        @current_range < @start.size - 1 || @current_number < @current_end
      end

      def next
        if @current_number < @current_end
          value = @current_number
          @current_number += 1
          return value
        end
        if @current_range >= @start.size - 1
          return Iterator::Stop::INSTANCE
        end
        @current_range += 1
        @current_number = @start[@current_range]
        @current_end = @end[@current_range]
        value = @current_number
        @current_number += 1
        value
      end
    end
  end
end
