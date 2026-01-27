require "log"
require "../cos"
require "../cos/icosparser"
require "../cos/object_key"

module Pdfbox::Pdfparser
  # Main PDF parser class
  class Parser < Pdfbox::Cos::ICOSParser
    Log = ::Log.for(self)
    @source : Pdfbox::IO::RandomAccessRead
    @trailer : Pdfbox::Cos::Dictionary?
    @xref : XRef?
    @object_pool : Hash(Cos::ObjectKey, Cos::Object)
    @decompressed_objects : Hash(Int64, Hash(Cos::ObjectKey, Cos::Base))

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @source = source
      @trailer = nil
      @xref = nil
      @object_pool = Hash(Cos::ObjectKey, Cos::Object).new
      @decompressed_objects = Hash(Int64, Hash(Cos::ObjectKey, Cos::Base)).new
    end

    getter source
    getter xref
    getter object_pool
    getter decompressed_objects

    # Get object from pool or create a new proxy object for lazy resolution
    def get_object_from_pool(key : Cos::ObjectKey) : Cos::Object
      @object_pool[key] ||= Cos::Object.new(key, self)
    end

    # Get object from pool by object number and generation
    def get_object_from_pool(object_number : Int64, generation_number : Int64) : Cos::Object
      key = Cos::ObjectKey.new(object_number, generation_number)
      get_object_from_pool(key)
    end

    # Parse PDF header and return version string (e.g., "1.4")
    def parse_header : String
      # Read first line (up to newline)
      line = read_line
      unless line.starts_with?("%PDF-")
        raise SyntaxError.new("Invalid PDF header: #{line.inspect}")
      end
      # Extract version: %PDF-1.4
      version = line[5..]
      # Optional: read binary comment line (second line starting with %)
      # Check if next byte is '%' (binary comment)
      if @source.peek == '%'.ord
        read_line # skip binary comment line
      end
      version
    end

    private def read_line : String
      builder = String::Builder.new
      while byte = @source.read
        ch = byte.chr
        break if ch == '\n'
        builder << ch
      end
      builder.to_s
    end

    # Parse cross-reference table
    def parse_xref : XRef
      xref = XRef.new
      # Skip whitespace/comments before "xref"
      scanner = PDFScanner.new(@source)
      Log.debug { "parse_xref: scanner string length: #{scanner.scanner.string.bytesize}, start pos: #{scanner.position}" }
      scanner.skip_whitespace

      # Expect "xref" keyword
      unless scanner.scanner.scan(/xref/)
        raise SyntaxError.new("Expected 'xref' keyword at position #{scanner.position}")
      end

      # Skip whitespace after keyword
      scanner.skip_whitespace
      Log.debug { "parse_xref: after 'xref', rest first 50 chars: #{scanner.scanner.rest[0..50].inspect}" }

      # Parse subsections until we hit "trailer" or other keyword
      loop do
        scanner.skip_whitespace
        # Check for next keyword (trailer, startxref) or end of input
        break if scanner.scanner.eos? || scanner.scanner.check(/trailer|startxref/i)

        # Read starting object number and count
        start_obj = scanner.read_number
        count = scanner.read_number

        # Ensure they are integers
        start_obj = start_obj.to_i64
        count = count.to_i64

        # Parse count entries
        count.times do |i|
          scanner.skip_whitespace
          offset_str = scanner.scanner.scan(/\d{10}/)
          unless offset_str
            raise SyntaxError.new("Expected 10-digit offset at position #{scanner.position}")
          end
          offset = offset_str.to_i64

          scanner.scanner.scan(/\s+/)
          gen_str = scanner.scanner.scan(/\d{5}/)
          unless gen_str
            raise SyntaxError.new("Expected 5-digit generation at position #{scanner.position}")
          end
          generation = gen_str.to_i64

          scanner.scanner.scan(/\s+/)
          type_char = scanner.scanner.scan(/[nf]/)
          unless type_char
            raise SyntaxError.new("Expected 'n' or 'f' at position #{scanner.position}")
          end
          type = type_char == "n" ? :in_use : :free

          # Add entry to xref table
          obj_num = start_obj + i
          xref[obj_num] = XRefEntry.new(offset, generation, type)

          # Skip optional whitespace/newline
          scanner.skip_whitespace
        end
      end

      # Update source position to where scanner stopped
      final_pos = scanner.position
      Log.debug { "parse_xref: final scanner.position=#{final_pos}, source.position=#{@source.position}" }
      @source.seek(final_pos)
      xref
    end

    # Parse an xref stream
    def parse_xref_stream(offset : Int64) : XRef
      Log.debug { "parse_xref_stream: START parsing xref stream at offset #{offset}" }
      # Parse the stream object
      stream_obj = parse_indirect_object_at_offset(offset)
      unless stream_obj.is_a?(Pdfbox::Cos::Stream)
        raise SyntaxError.new("Expected stream object at offset #{offset}, got #{stream_obj.class}")
      end

      stream = stream_obj
      dict = stream
      Log.debug { "parse_xref_stream: stream dict keys: #{dict.entries.keys.map(&.value)}" }
      if dict.has_key?(Pdfbox::Cos::Name.new("Filter"))
        filter_entry = dict[Pdfbox::Cos::Name.new("Filter")]
        Log.debug { "parse_xref_stream: Filter = #{filter_entry.inspect}" }
      end
      if dict.has_key?(Pdfbox::Cos::Name.new("DecodeParms"))
        decode_entry = dict[Pdfbox::Cos::Name.new("DecodeParms")]
        Log.debug { "parse_xref_stream: DecodeParms = #{decode_entry.inspect}" }
      end

      # Check if it's actually an xref stream
      type_entry = dict[Pdfbox::Cos::Name.new("Type")]
      unless type_entry && type_entry.is_a?(Pdfbox::Cos::Name) && type_entry.value == "XRef"
        raise SyntaxError.new("Not an XRef stream at offset #{offset}")
      end

      # Get /W array (required)
      w = parse_w_array_from_dict(dict)

      Log.debug { "parse_xref_stream: W array = #{w}" }

      # Get /Index array or default to [0, Size]
      index_array, size = parse_index_array_from_dict(dict)

      Log.debug { "parse_xref_stream: Index array = #{index_array}, Size = #{size}" }
      Log.debug { "parse_xref_stream: stream data size = #{stream.data.size} bytes" }
      if stream.data.size > 0
        Log.debug { "parse_xref_stream: first 20 bytes of stream data: #{stream.data[0, Math.min(20, stream.data.size)].hexstring}" }
      end

      # Decode stream data if compressed
      data = decode_stream_data(stream)
      Log.debug { "parse_xref_stream: after decoding, size = #{data.size} bytes" }
      if data.size > 0
        Log.debug { "parse_xref_stream: first 20 bytes after decoding: #{data[0, Math.min(20, data.size)].hexstring}" }
      end

      # Parse stream data according to /W array
      Log.debug { "parse_xref_stream: starting to parse data, size=#{data.size}, w=#{w}, total_entry_width=#{w.sum}" }
      xref = parse_xref_stream_entries(data, w, index_array)

      Log.debug { "parse_xref_stream: parsed #{xref.size} entries" }
      xref
    end

    private def parse_w_array_from_dict(dict : Pdfbox::Cos::Dictionary) : Array(Int32)
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
      w
    end

    private def parse_index_array_from_dict(dict : Pdfbox::Cos::Dictionary) : Tuple(Array(Int64), Int64)
      size_entry = dict[Pdfbox::Cos::Name.new("Size")]
      unless size_entry && size_entry.is_a?(Pdfbox::Cos::Integer)
        raise SyntaxError.new("/Size missing in XRef stream")
      end
      size = size_entry.value.to_i64

      index_array = Array(Int64).new
      index_entry = dict[Pdfbox::Cos::Name.new("Index")]
      if index_entry && index_entry.is_a?(Pdfbox::Cos::Array)
        index_entry.items.each do |item|
          unless item.is_a?(Pdfbox::Cos::Integer)
            raise SyntaxError.new("/Index array element is not an integer")
          end
          index_array << item.value
        end
      else
        # Default: [0, Size]
        index_array = [0_i64, size]
      end
      {index_array, size}
    end

    private def parse_xref_stream_entries(data : Bytes, w : Array(Int32), index_array : Array(Int64)) : XRef
      xref = XRef.new
      total_entry_width = w.sum
      if total_entry_width == 0
        raise SyntaxError.new("Total width of entries is 0")
      end

      # Helper to parse big-endian integer from bytes
      parse_be = ->(bytes : Bytes) : Int64 {
        value = 0_i64
        bytes.each do |byte|
          value = (value << 8) | byte.to_i64
        end
        value
      }

      # Process index array pairs
      if index_array.size % 2 != 0
        raise SyntaxError.new("/Index array must have even number of elements, got #{index_array.size}")
      end
      index_array.each_slice(2) do |pair|
        start, count = pair[0], pair[1]
        Log.debug { "parse_xref_stream: processing index range start=#{start}, count=#{count}" }
        count.to_i64.times do |i|
          # Calculate position in data
          entry_index = i.to_i64
          pos = entry_index * total_entry_width
          if pos + total_entry_width > data.size
            raise SyntaxError.new("Stream data truncated: need #{total_entry_width} bytes at position #{pos} but only #{data.size} available")
          end

          # Read fields
          type = w[0] == 0 ? 1_i64 : parse_be.call(data[pos, w[0]])
          field2 = w[1] == 0 ? 0_i64 : parse_be.call(data[pos + w[0], w[1]])
          field3 = w[2] == 0 ? 0_i64 : parse_be.call(data[pos + w[0] + w[1], w[2]])

          obj_num = start + i

          if [1350_i64, 1352_i64, 1358_i64, 1360_i64].includes?(obj_num)
            Log.debug { "parse_xref_stream: FOUND PageLabels object #{obj_num}, type=#{type}" }
          end

          case type
          when 0
            # Free entry, skip
            Log.debug { "parse_xref_stream: free entry for object #{obj_num}" }
            next
          when 1
            # In-use entry
            offset = field2
            generation = field3
            Log.debug { "parse_xref_stream: in-use entry obj #{obj_num}: offset=#{offset}, gen=#{generation}" }
            xref[obj_num] = XRefEntry.new(offset, generation, :in_use)
          when 2
            # Compressed entry
            obj_stream_number = field2
            index_in_stream = field3
            Log.debug { "parse_xref_stream: compressed entry obj #{obj_num}: obj_stream=#{obj_stream_number}, index=#{index_in_stream}" }
            # Store with type :compressed (offset stores obj_stream_number, generation stores index)
            xref[obj_num] = XRefEntry.new(obj_stream_number, index_in_stream, :compressed)
          else
            raise SyntaxError.new("Invalid entry type #{type} for object #{obj_num}")
          end
        end
      end
      xref
    end

    # Parse object header (obj number, generation, "obj")
    private def parse_object_header(offset : Int64, key : Cos::ObjectKey?) : PDFScanner
      @source.seek(offset)
      scanner = PDFScanner.new(@source)
      scanner.skip_whitespace
      obj_num = scanner.read_number.to_i64
      gen_num = scanner.read_number.to_i64
      scanner.skip_whitespace
      unless scanner.scanner.scan(/obj/)
        raise SyntaxError.new("Expected 'obj' at position #{scanner.position}")
      end

      # Verify object number/generation matches key if provided
      if key && (obj_num != key.number || gen_num != key.generation)
        raise SyntaxError.new("Object at offset #{offset} has number/generation #{obj_num}/#{gen_num}, expected #{key.number}/#{key.generation}")
      end

      scanner
    end

    # Parse object body (actual COS object)
    private def parse_object_body(scanner : PDFScanner) : Pdfbox::Cos::Base
      # Parse the object using ObjectParser (starting at current position)
      object_parser = ObjectParser.new(scanner, self)
      # Try parsing as dictionary first (most common)
      object = object_parser.parse_dictionary
      unless object
        # Fall back to generic object parsing
        object = object_parser.parse_object
        unless object
          raise SyntaxError.new("Failed to parse object at position #{scanner.position}")
        end
      end
      object
    end

    # Handle stream if object is a dictionary followed by stream keyword
    private def handle_stream(scanner : PDFScanner, object : Pdfbox::Cos::Base) : Pdfbox::Cos::Base
      return object unless object.is_a?(Pdfbox::Cos::Dictionary)

      scanner.skip_whitespace
      return object unless scanner.scanner.scan(/stream/)

      # Handle optional newline after "stream"
      # According to PDF spec, "stream" must be followed by EOL marker (CR, LF, or CRLF)
      # before the stream data begins
      Log.debug { "handle_stream: found 'stream' at scanner pos #{scanner.position}" }

      # Get Length from dictionary
      length_entry = object[Pdfbox::Cos::Name.new("Length")]
      unless length_entry && length_entry.is_a?(Pdfbox::Cos::Integer)
        raise SyntaxError.new("Stream missing /Length entry")
      end
      length = length_entry.value.to_i64
      Log.debug { "handle_stream: stream length = #{length}" }

      # Skip whitespace (EOL marker) after "stream"
      scanner.skip_whitespace

      # Read stream data as raw bytes
      data = scanner.read_raw_bytes(length)
      Log.debug { "handle_stream: read #{data.size} bytes of stream data" }

      # Create Stream object with data
      stream_obj = Pdfbox::Cos::Stream.new(object.entries, data)

      # Skip "endstream"
      scanner.skip_whitespace
      unless scanner.scanner.scan(/endstream/)
        raise SyntaxError.new("Expected 'endstream' after stream data at position #{scanner.position}")
      end

      stream_obj
    end

    # Check for endobj marker
    private def check_endobj(scanner : PDFScanner) : Nil
      scanner.skip_whitespace
      Log.debug { "check_endobj: before endobj, scanner.rest first 50 chars: #{scanner.rest[0..50].inspect}, position: #{scanner.position}" }
      unless scanner.scanner.scan(/endobj/)
        raise SyntaxError.new("Expected 'endobj' at position #{scanner.position}")
      end
    end

    # Parse an indirect object at given offset
    def parse_indirect_object_at_offset(offset : Int64, key : Cos::ObjectKey? = nil) : Pdfbox::Cos::Base
      # Get object from pool if key provided
      cos_object = key ? get_object_from_pool(key) : nil

      # Check if already dereferenced
      if cos_object && (obj = cos_object.object)
        return obj
      end

      scanner = parse_object_header(offset, key)
      Log.debug { "parse_indirect_object_at_offset: after 'obj', scanner.rest first 1000 chars: #{scanner.rest[0..1000].inspect}" }

      object = parse_object_body(scanner)
      object = handle_stream(scanner, object)
      check_endobj(scanner)

      # Set the parsed object on the Cos::Object from pool
      if cos_object
        cos_object.object = object
      end

      object
    end

    # Locate xref table offset using startxref pointer
    def locate_xref_offset : Int64?
      # Save current position
      original_pos = @source.position
      begin
        file_size = @source.length
        read_size = 1024
        start = file_size - read_size
        start = 0_i64 if start < 0
        @source.seek(start)
        data = @source.read_all
        # Find "startxref" from end
        str = String.new(data, "ISO-8859-1")
        if idx = str.index("startxref")
          idx += 9 # length of "startxref"
          # Skip whitespace
          while idx < str.size && str[idx].ascii_whitespace?
            idx += 1
          end
          # Parse digits
          start_idx = idx
          while idx < str.size && str[idx].ascii_number?
            idx += 1
          end
          if start_idx < idx
            digits = str[start_idx...idx]
            return digits.to_i64
          end
        end
      ensure
        @source.seek(original_pos)
      end
      nil
    end

    # Parse page count from xref table (count page objects)
    private def parse_page_count_from_xref(xref : XRef) : Int32
      # Count objects with object number >= 3 that are in-use (page objects)
      page_count = 0
      xref.entries.each do |obj_num, entry|
        if obj_num >= 3 && entry.in_use?
          page_count += 1
        end
      end
      page_count
    end

    # Resolve a COS object, handling indirect references
    private def resolve_object(obj : Cos::Base, xref : XRef) : Cos::Base
      if obj.is_a?(Cos::Object)
        # Handle case where Cos::Object is just a wrapper around already dereferenced object
        if obj.key.nil?
          # Object is already dereferenced wrapper, return the underlying object
          dereferenced = obj.object
          return dereferenced if dereferenced
          raise SyntaxError.new("Cos::Object has nil key and nil object")
        end

        obj_num = obj.obj_number
        # Debug logging for PageLabels objects
        if [1350_i64, 1352_i64, 1358_i64, 1360_i64].includes?(obj_num)
          Log.debug { "resolve_object: resolving PageLabels object #{obj_num}" }
        end
        if xref_entry = xref[obj_num]
          if key = obj.key
            if xref_entry.compressed?
              # Object is compressed in an object stream
              parse_object_from_stream(xref_entry.offset, key, xref_entry.generation, xref)
            else
              parse_indirect_object_at_offset(xref_entry.offset, key)
            end
          else
            raise SyntaxError.new("Cos::Object has nil key")
          end
        else
          raise SyntaxError.new("Object #{obj_num} not found in xref")
        end
      else
        obj
      end
    end

    # Parse an object from an object stream (similar to Apache PDFBox parseObjectStreamObject)
    private def parse_object_from_stream(obj_stream_number : Int64, key : Cos::ObjectKey, index_in_stream : Int64, xref : XRef) : Cos::Base
      Log.debug { "parse_object_from_stream: parsing object #{key.number} from stream #{obj_stream_number} at index #{index_in_stream}" }

      # Get or create cache for this object stream
      stream_objects = @decompressed_objects[obj_stream_number] ||= Hash(Cos::ObjectKey, Cos::Base).new

      # Check if object is already in cache
      cached_object = stream_objects.delete(key)
      if cached_object
        Log.debug { "parse_object_from_stream: found object #{key.number} in cache" }
        return cached_object
      end

      # Object not in cache, need to parse the object stream
      obj_stream_xref_entry = xref[obj_stream_number]
      unless obj_stream_xref_entry
        raise SyntaxError.new("Object stream #{obj_stream_number} not found in xref")
      end

      unless obj_stream_xref_entry.in_use?
        raise SyntaxError.new("Object stream #{obj_stream_number} is not an in-use entry")
      end

      # Parse the object stream
      obj_stream_key = Pdfbox::Cos::ObjectKey.new(obj_stream_number, obj_stream_xref_entry.generation)
      obj_stream = parse_indirect_object_at_offset(obj_stream_xref_entry.offset, obj_stream_key)
      unless obj_stream.is_a?(Cos::Stream)
        raise SyntaxError.new("Object #{obj_stream_number} is not a stream")
      end

      # Parse all objects from the stream
      all_objects = parse_all_objects_from_stream(obj_stream)
      Log.debug { "parse_object_from_stream: parsed #{all_objects.size} objects from stream #{obj_stream_number}" }

      # Find the requested object
      requested_object = all_objects.delete(key)
      unless requested_object
        # Key might not match exactly (stream index different). Try to find by object number
        Log.debug { "parse_object_from_stream: object #{key.number} not found with exact key, searching by object number" }
        all_objects.each do |obj_key, obj|
          if obj_key.number == key.number
            requested_object = obj
            all_objects.delete(obj_key)
            Log.debug { "parse_object_from_stream: found object #{key.number} with key #{obj_key}" }
            break
          end
        end
      end

      unless requested_object
        raise SyntaxError.new("Object #{key.number} not found in object stream #{obj_stream_number}")
      end

      # Cache remaining objects
      all_objects.each do |obj_key, obj|
        stream_objects[obj_key] = obj
      end

      Log.debug { "parse_object_from_stream: cached #{all_objects.size} remaining objects" }
      requested_object
    end

    private def decompress_flate(data : Bytes) : Bytes
      io = ::IO::Memory.new(data)
      begin
        reader = Compress::Deflate::Reader.new(io)
        decompressed = reader.gets_to_end
        reader.close
        decompressed.to_slice
      rescue ex
        io.rewind
        begin
          reader = Compress::Zlib::Reader.new(io)
          decompressed = reader.gets_to_end
          reader.close
          decompressed.to_slice
        rescue ex
          # Use raw data as fallback (maybe already uncompressed)
          data
        end
      end
    end

    private def decode_stream_data(stream : Pdfbox::Cos::Stream) : Bytes
      data = stream.data
      dict = stream

      filter_entry = dict[Pdfbox::Cos::Name.new("Filter")]
      if filter_entry
        if filter_entry.is_a?(Pdfbox::Cos::Name) && filter_entry.value == "FlateDecode"
          data = decompress_flate(data)
        else
          raise SyntaxError.new("Unsupported filter: #{filter_entry.inspect}")
        end
      end

      decode_parms_entry = dict[Pdfbox::Cos::Name.new("DecodeParms")]
      if decode_parms_entry && decode_parms_entry.is_a?(Pdfbox::Cos::Dictionary)
        predictor = decode_parms_entry[Pdfbox::Cos::Name.new("Predictor")]
        columns = decode_parms_entry[Pdfbox::Cos::Name.new("Columns")]
        if predictor && predictor.is_a?(Pdfbox::Cos::Integer) && predictor.value >= 10 &&
           columns && columns.is_a?(Pdfbox::Cos::Integer)
          # PNG prediction
          data = apply_png_predictor(data, columns.value.to_i, predictor.value.to_i)
        end
      end

      data
    end

    private def apply_png_filter_none(output : Bytes, row_cols : Int32, columns : Int32, row_data : Bytes) : Bytes
      output[row_cols, columns].copy_from(row_data)
      output[row_cols, columns]
    end

    private def apply_png_filter_sub(output : Bytes, row_cols : Int32, columns : Int32, row_data : Bytes) : Bytes
      (0...columns).each do |col|
        left = col > 0 ? output[row_cols + col - 1] : 0
        decoded = (row_data[col] + left) & 0xFF
        output[row_cols + col] = decoded.to_u8
      end
      output[row_cols, columns]
    end

    private def apply_png_filter_up(output : Bytes, row_cols : Int32, columns : Int32, row_data : Bytes, previous_row : Bytes) : Bytes
      (0...columns).each do |col|
        up = previous_row[col]
        decoded = (row_data[col] + up) & 0xFF
        output[row_cols + col] = decoded.to_u8
      end
      output[row_cols, columns]
    end

    private def apply_png_filter_average(output : Bytes, row_cols : Int32, columns : Int32, row_data : Bytes, previous_row : Bytes) : Bytes
      (0...columns).each do |col|
        left = col > 0 ? output[row_cols + col - 1] : 0
        up = previous_row[col]
        decoded = (row_data[col] + ((left + up) // 2)) & 0xFF
        output[row_cols + col] = decoded.to_u8
      end
      output[row_cols, columns]
    end

    private def apply_png_filter_paeth(output : Bytes, row_cols : Int32, columns : Int32, row_data : Bytes, previous_row : Bytes) : Bytes
      (0...columns).each do |col|
        left = col > 0 ? output[row_cols + col - 1] : 0
        up = previous_row[col]
        up_left = col > 0 ? previous_row[col - 1] : 0
        # Paeth predictor
        p = left + up - up_left
        pa = (p - left).abs
        pb = (p - up).abs
        pc = (p - up_left).abs
        pr = if pa <= pb && pa <= pc
               left
             elsif pb <= pc
               up
             else
               up_left
             end
        decoded = (row_data[col] + pr) & 0xFF
        output[row_cols + col] = decoded.to_u8
      end
      output[row_cols, columns]
    end

    private def apply_png_predictor(input : Bytes, columns : Int32, predictor : Int32) : Bytes
      # PNG predictor: each row has filter byte (0-4) followed by columns bytes
      row_length = columns + 1
      return input if input.size % row_length != 0
      row_count = input.size // row_length
      output_size = row_count.to_i64 * columns
      raise RuntimeError.new("PNG predictor output size overflow") if output_size > Int32::MAX || output_size < 0
      output = Bytes.new(output_size.to_i32)
      previous_row = Bytes.new(columns, 0)
      (0...row_count).each do |row|
        row_start = (row.to_i64 * (columns + 1)).to_i32
        row_cols = (row.to_i64 * columns).to_i32
        filter_type = input[row_start]
        row_data = input[row_start + 1, columns]
        case filter_type
        when 0 # None
          previous_row = apply_png_filter_none(output, row_cols, columns, row_data)
        when 1 # Sub
          previous_row = apply_png_filter_sub(output, row_cols, columns, row_data)
        when 2 # Up
          previous_row = apply_png_filter_up(output, row_cols, columns, row_data, previous_row)
        when 3 # Average
          previous_row = apply_png_filter_average(output, row_cols, columns, row_data, previous_row)
        when 4 # Paeth
          previous_row = apply_png_filter_paeth(output, row_cols, columns, row_data, previous_row)
        else
          raise SyntaxError.new("Unsupported PNG filter type #{filter_type}")
        end
      end
      output
    end

    # Parse all objects from object stream and return map of object keys to objects
    private def parse_all_objects_from_stream(obj_stream : Cos::Stream) : Hash(Cos::ObjectKey, Cos::Base)
      Log.debug { "parse_all_objects_from_stream: parsing all objects from stream" }

      # Get stream dictionary
      dict = obj_stream

      # Check type
      type_entry = dict[Cos::Name.new("Type")]
      unless type_entry.is_a?(Cos::Name) && type_entry.value == "ObjStm"
        raise SyntaxError.new("Not an object stream (Type should be ObjStm)")
      end

      # Get number of objects
      n_entry = dict[Cos::Name.new("N")]
      unless n_entry.is_a?(Cos::Integer)
        raise SyntaxError.new("/N entry missing or invalid in object stream")
      end
      n = n_entry.value.to_i

      # Get offset of first object
      first_entry = dict[Cos::Name.new("First")]
      unless first_entry.is_a?(Cos::Integer)
        raise SyntaxError.new("/First entry missing or invalid in object stream")
      end
      first = first_entry.value.to_i

      Log.debug { "parse_all_objects_from_stream: N=#{n}, First=#{first}" }

      # Get stream data (decompressed and decoded)
      data = decode_stream_data(obj_stream)
      Log.debug { "parse_all_objects_from_stream: stream data size = #{data.size}" }

      # Create RandomAccessRead from stream data
      memory_io = Pdfbox::IO::MemoryRandomAccessRead.new(data)
      scanner = PDFScanner.new(memory_io)

      # Read object number/offset pairs into a sorted map (by offset)
      # Use Array of tuples then sort by offset (second element)
      object_pairs = [] of Tuple(Int64, Int64) # (object_number, offset)
      n.times do |i|
        # Stop if we've consumed first bytes (position is 0-based)
        if scanner.position >= first
          Log.debug { "parse_all_objects_from_stream: reached first byte limit at pair #{i}, stopping" }
          break
        end
        obj_num = scanner.read_number.to_i64
        offset = scanner.read_number.to_i64
        object_pairs << {obj_num, offset}
        Log.debug { "parse_all_objects_from_stream: obj_num=#{obj_num}, offset=#{offset}" }
      end

      # Sort by offset (second element of tuple)
      object_pairs.sort_by! { |pair| pair[1] }

      # Check if index is needed (multiple objects with same object number)
      # Count unique object numbers
      unique_obj_numbers = object_pairs.map { |pair| pair[0] }.uniq!.size
      index_needed = object_pairs.size > unique_obj_numbers
      Log.debug { "parse_all_objects_from_stream: index_needed=#{index_needed} (total=#{object_pairs.size}, unique=#{unique_obj_numbers})" }

      # Parse objects in offset order
      all_objects = Hash(Cos::ObjectKey, Cos::Base).new

      # Jump to start of object data (after the pairs)
      memory_io.seek(first)
      scanner = PDFScanner.new(memory_io)

      object_pairs.each_with_index do |pair, index|
        obj_num, offset = pair
        # Calculate absolute position in stream data
        absolute_pos = first + offset

        # Skip to object position if needed
        current_pos = scanner.position
        if absolute_pos != current_pos
          memory_io.seek(absolute_pos)
          scanner = PDFScanner.new(memory_io)
        end

        # Parse the object
        object_parser = ObjectParser.new(scanner, self)
        object = object_parser.parse_object
        unless object
          raise SyntaxError.new("Failed to parse object at offset #{absolute_pos}")
        end

        # Create object key with stream index if needed
        stream_index = index_needed ? index : -1
        key = Cos::ObjectKey.new(obj_num, 0, stream_index)
        all_objects[key] = object

        Log.debug { "parse_all_objects_from_stream: parsed object #{obj_num} at offset #{offset}, key=#{key}" }
      end

      Log.debug { "parse_all_objects_from_stream: successfully parsed #{all_objects.size} objects" }
      all_objects
    end

    # Parse pages tree recursively
    private def parse_pages_tree(pages_dict : Cos::Dictionary, xref : XRef) : Array(Cos::Dictionary)
      result = [] of Cos::Dictionary

      # Get Type to verify this is a Pages node
      type_obj = pages_dict[Cos::Name.new("Type")]
      if type_obj.is_a?(Cos::Name) && type_obj.value == "Page"
        # Leaf page
        result << pages_dict
        return result
      end

      # Should be Type "Pages" or missing (assume Pages)
      kids_obj = pages_dict[Cos::Name.new("Kids")]
      if kids_obj.is_a?(Cos::Array)
        kids_obj.items.each do |kid|
          resolved_kid = resolve_object(kid, xref)
          if resolved_kid.is_a?(Cos::Dictionary)
            result.concat(parse_pages_tree(resolved_kid, xref))
          end
        end
      end

      result
    end

    # Resolve a COS object using the xref table
    def resolve(obj : Cos::Base) : Cos::Base
      xref = @xref
      raise "XRef table not available" unless xref
      resolve_object(obj, xref)
    end

    # Dereference the COS object which is referenced by the given Object
    def dereference_object(obj : Cos::Object) : Cos::Base
      xref = @xref
      raise "XRef table not available" unless xref
      resolve_object(obj, xref)
    end

    # Creates a random access read view starting at the given position with the given length
    def create_random_access_read_view(start_position : Int64, stream_length : Int64) : Pdfbox::IO::RandomAccessRead
      @source.create_view(start_position, stream_length)
    end

    private def collect_xref_sections(xref_offset : Int64) : Array(Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?))
      sections = [] of Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?)
      prev : Int64 = xref_offset.to_i64

      while prev > 0
        Log.debug { "parsing xref at offset #{prev}" }
        @source.seek(prev)
        section_xref = parse_xref
        Log.debug { "section_xref entries: #{section_xref.size}" }

        section_trailer = parse_trailer
        Log.debug { "got section_trailer: #{section_trailer != nil}" }

        sections << {prev, section_xref, section_trailer}

        # Get next Prev link from current section trailer
        if section_trailer
          next_prev_ref = section_trailer[Pdfbox::Cos::Name.new("Prev")]
          if next_prev_ref.is_a?(Pdfbox::Cos::Integer)
            prev = next_prev_ref.value.to_i64
            Log.debug { "next prev offset: #{prev}" }
          else
            prev = 0_i64
          end
        else
          prev = 0_i64
        end
      end

      sections
    end

    private def merge_xref_sections(sections : Array(Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?))) : Tuple(XRef, Pdfbox::Cos::Dictionary?)
      xref = XRef.new
      trailer = nil

      # Process sections from OLDEST to NEWEST (reverse of collection order)
      # so newer entries override older ones
      sections.reverse.each do |offset_val, xref_section, trailer_section|
        Log.debug { "applying xref section from offset #{offset_val} (#{xref_section.size} entries)" }

        # Merge xref entries (newer sections override older ones)
        xref_section.entries.each do |obj_num, entry|
          xref[obj_num] = entry
        end

        # Merge trailer dictionaries (newer overrides older)
        if trailer_section
          if trailer
            # Copy entries from trailer_section to trailer only if not already present
            # (older trailers should not override newer ones)
            trailer_section.entries.each do |key, value|
              trailer[key] = value unless trailer.has_key?(key)
            end
          else
            trailer = trailer_section
          end

          # Check for XRefStm (cross-reference stream) in trailer
          xref_stm_ref = trailer_section[Pdfbox::Cos::Name.new("XRefStm")]
          if xref_stm_ref && xref_stm_ref.is_a?(Pdfbox::Cos::Integer)
            xref_stm_offset = xref_stm_ref.value.to_i64
            Log.debug { "Found XRefStm at offset #{xref_stm_offset}, parsing xref stream" }
            begin
              xref_stream = parse_xref_stream(xref_stm_offset)
              Log.debug { "xref_stream size before merging: #{xref_stream.size}" }

              # Merge xref stream entries with main xref table
              xref_stream.entries.each do |obj_num, entry|
                xref[obj_num] = entry
              end
              Log.debug { "Merged #{xref_stream.size} entries from xref stream" }
            rescue ex
              Log.debug { "Failed to parse xref stream at offset #{xref_stm_offset}: #{ex.message}" }
              Log.debug(exception: ex) { "xref stream parsing error" }
            end
          end
        end
      end

      {xref, trailer}
    end

    private def parse_catalog_from_trailer(trailer : Pdfbox::Cos::Dictionary?, xref : XRef) : Pdfbox::Cos::Dictionary?
      return unless trailer

      root_ref = trailer[Pdfbox::Cos::Name.new("Root")]
      Log.debug { "root_ref: #{root_ref.inspect}" }

      obj_number = if root_ref.is_a?(Pdfbox::Cos::Object)
                     Log.debug { "root_ref is object, obj_number: #{root_ref.obj_number}" }
                     root_ref.obj_number
                   elsif root_ref.is_a?(Pdfbox::Cos::Integer)
                     Log.debug { "root_ref is integer, treating as object number: #{root_ref.value}" }
                     root_ref.value
                   end

      return unless obj_number

      xref_entry = xref[obj_number]
      return unless xref_entry

      Log.debug { "xref entry found for object #{obj_number}: offset #{xref_entry.offset}" }
      catalog_key = Pdfbox::Cos::ObjectKey.new(obj_number, xref_entry.generation)
      catalog_obj = parse_indirect_object_at_offset(xref_entry.offset, catalog_key)
      Log.debug { "catalog_obj type: #{catalog_obj.class}" }

      return unless catalog_obj.is_a?(Pdfbox::Cos::Dictionary)

      catalog_dict = catalog_obj
      Log.debug { "catalog dict keys: #{catalog_dict.entries.keys.map(&.value)}" }
      Log.debug { "catalog dict full: #{catalog_dict.inspect}" }

      # Check for PageLabels entry
      page_labels_entry = catalog_dict[Pdfbox::Cos::Name.new("PageLabels")]
      Log.debug { "PageLabels entry in catalog: #{page_labels_entry.inspect}" }

      # Resolve if it's an indirect reference
      if page_labels_entry.is_a?(Pdfbox::Cos::Object)
        Log.debug { "Resolving PageLabels indirect reference" }
        page_labels_entry = resolve(page_labels_entry)
        Log.debug { "Resolved PageLabels: #{page_labels_entry.inspect}" }
        # Update the dictionary with resolved value
        catalog_dict[Pdfbox::Cos::Name.new("PageLabels")] = page_labels_entry
      end

      catalog_dict
    end

    private def parse_pages_from_catalog(catalog_dict : Pdfbox::Cos::Dictionary, xref : XRef) : Array(Pdfbox::Pdmodel::Page)
      pages = [] of Pdfbox::Pdmodel::Page

      pages_ref = catalog_dict[Pdfbox::Cos::Name.new("Pages")]
      return pages unless pages_ref

      resolved_pages = resolve_object(pages_ref, xref)
      return pages unless resolved_pages.is_a?(Pdfbox::Cos::Dictionary)

      page_dicts = parse_pages_tree(resolved_pages, xref)
      page_dicts.each do |page_dict|
        pages << Pdfbox::Pdmodel::Page.new(page_dict)
      end

      pages
    end

    # Parse the PDF document
    def parse : Pdfbox::Pdmodel::Document
      version = parse_header
      pages = [] of Pdfbox::Pdmodel::Page

      xref_offset = locate_xref_offset
      Log.debug { "xref_offset: #{xref_offset}" }

      catalog_dict = if xref_offset
                       sections = collect_xref_sections(xref_offset)
                       xref, trailer = merge_xref_sections(sections)

                       @trailer = trailer
                       @xref = xref

                       # Debug logging for compressed entries
                       Log.debug { "final xref entries: #{xref.size}" }
                       compressed_count = xref.entries.count { |_, entry| entry.compressed? }
                       Log.debug { "compressed xref entries (count: #{compressed_count}):" }
                       xref.entries.each do |obj_num, entry|
                         if entry.compressed?
                           Log.debug { "  object #{obj_num}: obj_stream=#{entry.offset}, index=#{entry.generation}" }
                         end
                       end

                       # Debug: print xref entries for objects around 17 and PageLabels objects
                       Log.debug { "checking xref entries for objects 15-20 and PageLabels objects:" }
                       [15, 16, 17, 18, 19, 20, 1350, 1352, 1358, 1360].each do |obj_num|
                         if entry = xref[obj_num.to_i64]
                           Log.debug { "  object #{obj_num}: offset #{entry.offset}, type: #{entry.type}" }
                         else
                           Log.debug { "  object #{obj_num}: not found in xref" }
                         end
                       end
                       Log.debug { "trailer: #{trailer.inspect}" }

                       found_catalog_dict = parse_catalog_from_trailer(trailer, xref)
                       if found_catalog_dict
                         pages = parse_pages_from_catalog(found_catalog_dict, xref)
                       end
                       found_catalog_dict
                     end

      Log.debug { "catalog_dict = #{catalog_dict.inspect}" }
      doc = Pdfbox::Pdmodel::Document.new(catalog_dict, version)

      # Add parsed pages to document
      pages.each do |page|
        doc.add_page(page)
      end

      doc
    end

    private def parse_trailer : Pdfbox::Cos::Dictionary?
      # Save current position
      start_pos = @source.position
      Log.debug { "parse_trailer: starting at position #{start_pos}" }

      # Skip whitespace/comments
      loop do
        byte = @source.peek
        break unless byte
        ch = byte.chr
        if ch == '%'
          # Comment, skip to end of line
          while byte = @source.read
            break if byte.chr == '\n'
          end
        elsif ch.ascii_whitespace?
          @source.read # skip whitespace
        else
          break
        end
      end

      # Check for "trailer" keyword
      # Read next 7 bytes to check
      @source.seek(start_pos) # reset to start
      line = read_line
      Log.debug { "parse_trailer: first line: #{line.inspect}" }

      # Try to find "trailer" in line
      if line.includes?("trailer")
        # Position after "trailer"
        trailer_index = line.index("trailer")
        if trailer_index
          # Skip to after "trailer"
          @source.seek(start_pos + trailer_index + "trailer".size)
          # Skip whitespace
          while byte = @source.peek
            break unless byte.chr.ascii_whitespace?
            @source.read
          end
          # Now parse dictionary
          object_parser = ObjectParser.new(@source, self)
          dict = object_parser.parse_dictionary
          Log.debug { "parse_trailer: parsed dictionary: #{dict.inspect}" }
          return dict
        end
      end

      Log.debug { "parse_trailer: 'trailer' not found in line" }
      @source.seek(start_pos) # restore position
      nil
    end

    private def parse_xref_from_scanner(scanner : PDFScanner) : XRef
      # Expect "xref" keyword (already checked)
      scanner.scanner.scan(/xref/)
      scanner.skip_whitespace

      xref = XRef.new

      # Parse subsections until we hit "trailer" or other keyword
      loop do
        scanner.skip_whitespace
        # Check for next keyword (trailer, startxref) or end of input
        break if scanner.scanner.eos? || scanner.scanner.check(/trailer|startxref/i)

        # Read starting object number and count
        start_obj = scanner.read_number
        count = scanner.read_number

        # Ensure they are integers
        start_obj = start_obj.to_i64
        count = count.to_i64

        # Parse count entries
        count.times do |i|
          scanner.skip_whitespace
          offset_str = scanner.scanner.scan(/\d{10}/)
          unless offset_str
            raise SyntaxError.new("Expected 10-digit offset at position #{scanner.position}")
          end
          offset = offset_str.to_i64

          scanner.scanner.scan(/\s+/)
          gen_str = scanner.scanner.scan(/\d{5}/)
          unless gen_str
            raise SyntaxError.new("Expected 5-digit generation at position #{scanner.position}")
          end
          generation = gen_str.to_i64

          scanner.scanner.scan(/\s+/)
          type_char = scanner.scanner.scan(/[nf]/)
          unless type_char
            raise SyntaxError.new("Expected 'n' or 'f' at position #{scanner.position}")
          end
          type = type_char == "n" ? :in_use : :free

          # Add entry to xref table
          obj_num = start_obj + i
          xref[obj_num] = XRefEntry.new(offset, generation, type)

          # Skip optional whitespace/newline
          scanner.skip_whitespace
        end
      end

      xref
    end

    private def parse_simple_page_count : Int32
      # Save current position
      original_pos = @source.position
      begin
        page_count = 0
        while !@source.eof?
          line = read_line
          break if line == "%%EOF"

          if line.starts_with?("% Pages: ")
            page_count = line[9..].to_i? || 0
          end
        end
        page_count
      ensure
        @source.seek(original_pos)
      end
    end

    # Parse with password for encrypted PDFs
    def parse(password : String) : Pdfbox::Pdmodel::Document
      # For now, ignore password and parse normally
      parse
    end

    # Check if PDF is encrypted
    def encrypted? : Bool
      # TODO: Implement encryption detection
      false
    end

    # Get PDF version
    def version : String
      # TODO: Implement version detection
      "1.4"
    end

    # Get document information dictionary
    def document_information : Pdfbox::Cos::Dictionary?
      # TODO: Implement document info retrieval
      nil
    end

    # Get document catalog
    def catalog : Pdfbox::Cos::Dictionary?
      # TODO: Implement catalog retrieval
      nil
    end

    # Get trailer dictionary
    def trailer : Pdfbox::Cos::Dictionary?
      @trailer
    end
  end
end
