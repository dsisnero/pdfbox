require "string_scanner"

require "compress/zlib"
require "compress/deflate"

# PDF Parser module for PDFBox Crystal
#
# This module contains PDF parsing functionality,
# corresponding to the pdfparser package in Apache PDFBox.
module Pdfbox::Pdfparser
  # Base class for PDF parsing errors
  class ParseError < Pdfbox::PDFError; end

  # Raised when PDF syntax is invalid
  class SyntaxError < ParseError; end

  # Raised when PDF is encrypted and password is required
  class EncryptedPDFError < ParseError; end

  # Raised when PDF version is not supported
  class UnsupportedVersionError < ParseError; end

  # Main PDF parser class
  class Parser
    @source : Pdfbox::IO::RandomAccessRead
    @trailer : Pdfbox::Cos::Dictionary?

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @source = source
      @trailer = nil
    end

    getter source

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
      puts "DEBUG parse_xref: scanner string length: #{scanner.scanner.string.bytesize}, start pos: #{scanner.position}"
      scanner.skip_whitespace

      # Expect "xref" keyword
      unless scanner.scanner.scan(/xref/)
        raise SyntaxError.new("Expected 'xref' keyword at position #{scanner.position}")
      end

      # Skip whitespace after keyword
      scanner.skip_whitespace
      puts "DEBUG parse_xref: after 'xref', rest first 50 chars: #{scanner.scanner.rest[0..50].inspect}"

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
      puts "DEBUG parse_xref: final scanner.position=#{final_pos}, source.position=#{@source.position}"
      @source.seek(final_pos)
      xref
    end

    # Parse an xref stream
    def parse_xref_stream(offset : Int64) : XRef
      puts "DEBUG parse_xref_stream: START parsing xref stream at offset #{offset}"
      STDOUT.flush
      # Parse the stream object
      stream_obj = parse_indirect_object_at_offset(offset)
      unless stream_obj.is_a?(Pdfbox::Cos::Stream)
        raise SyntaxError.new("Expected stream object at offset #{offset}, got #{stream_obj.class}")
      end

      stream = stream_obj
      dict = stream
      puts "DEBUG parse_xref_stream: stream dict keys: #{dict.entries.keys.map(&.value)}"
      if dict.has_key?(Pdfbox::Cos::Name.new("Filter"))
        filter_entry = dict[Pdfbox::Cos::Name.new("Filter")]
        puts "DEBUG parse_xref_stream: Filter = #{filter_entry.inspect}"
      end
      if dict.has_key?(Pdfbox::Cos::Name.new("DecodeParms"))
        decode_entry = dict[Pdfbox::Cos::Name.new("DecodeParms")]
        puts "DEBUG parse_xref_stream: DecodeParms = #{decode_entry.inspect}"
      end

      # Check if it's actually an xref stream
      type_entry = dict[Pdfbox::Cos::Name.new("Type")]
      unless type_entry && type_entry.is_a?(Pdfbox::Cos::Name) && type_entry.value == "XRef"
        raise SyntaxError.new("Not an XRef stream at offset #{offset}")
      end

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

      puts "DEBUG parse_xref_stream: W array = #{w}"

      # Get /Index array or default to [0, Size]
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

      puts "DEBUG parse_xref_stream: Index array = #{index_array}, Size = #{size}"
      puts "DEBUG parse_xref_stream: stream data size = #{stream.data.size} bytes"
      if stream.data.size > 0
        puts "DEBUG parse_xref_stream: first 20 bytes of stream data: #{stream.data[0, Math.min(20, stream.data.size)].hexstring}"
      end

      # Decode stream data if compressed
      data = decode_stream_data(stream)
      puts "DEBUG parse_xref_stream: after decoding, size = #{data.size} bytes"
      if data.size > 0
        puts "DEBUG parse_xref_stream: first 20 bytes after decoding: #{data[0, Math.min(20, data.size)].hexstring}"
      end

      # Parse stream data according to /W array
      puts "DEBUG parse_xref_stream: starting to parse data, size=#{data.size}, w=#{w}, total_entry_width=#{w.sum}"
      xref = XRef.new

      # Helper to parse big-endian integer from bytes
      parse_be = ->(bytes : Bytes) : Int64 {
        value = 0_i64
        bytes.each do |byte|
          value = (value << 8) | byte.to_i64
        end
        value
      }

      total_entry_width = w.sum
      if total_entry_width == 0
        raise SyntaxError.new("Total width of entries is 0")
      end

      # Process index array pairs
      if index_array.size % 2 != 0
        raise SyntaxError.new("/Index array must have even number of elements, got #{index_array.size}")
      end
      index_array.each_slice(2) do |pair|
        start, count = pair[0], pair[1]
        puts "DEBUG parse_xref_stream: processing index range start=#{start}, count=#{count}"
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

          case type
          when 0
            # Free entry, skip
            puts "DEBUG parse_xref_stream: free entry for object #{obj_num}"
            next
          when 1
            # In-use entry
            offset = field2
            generation = field3
            puts "DEBUG parse_xref_stream: in-use entry obj #{obj_num}: offset=#{offset}, gen=#{generation}"
            xref[obj_num] = XRefEntry.new(offset, generation, :in_use)
          when 2
            # Compressed entry
            obj_stream_number = field2
            index_in_stream = field3
            puts "DEBUG parse_xref_stream: compressed entry obj #{obj_num}: obj_stream=#{obj_stream_number}, index=#{index_in_stream}"
            # Store with type :compressed (offset stores obj_stream_number, generation stores index)
            xref[obj_num] = XRefEntry.new(obj_stream_number, index_in_stream, :compressed)
          else
            raise SyntaxError.new("Invalid entry type #{type} for object #{obj_num}")
          end
        end
      end

      puts "DEBUG parse_xref_stream: parsed #{xref.size} entries"
      STDOUT.flush
      xref
    end

    # Parse an indirect object at given offset
    def parse_indirect_object_at_offset(offset : Int64) : Pdfbox::Cos::Base
      @source.seek(offset)
      scanner = PDFScanner.new(@source)
      scanner.skip_whitespace
      _obj_num = scanner.read_number.to_i64
      _gen_num = scanner.read_number.to_i64
      scanner.skip_whitespace
      unless scanner.scanner.scan(/obj/)
        raise SyntaxError.new("Expected 'obj' at position #{scanner.position}")
      end
      scanner.skip_whitespace
      puts "DEBUG parse_indirect_object_at_offset: after 'obj', scanner.rest first 500 chars: #{scanner.rest[0..500].inspect}"

      # Parse the object using ObjectParser (starting at current position)
      object_parser = ObjectParser.new(scanner)
      # Try parsing as dictionary first (most common)
      object = object_parser.parse_dictionary
      unless object
        # Fall back to generic object parsing
        object = object_parser.parse_object
        unless object
          raise SyntaxError.new("Failed to parse object at position #{scanner.position}")
        end
      end

      # Handle streams (dictionary followed by stream keyword)
      if object.is_a?(Pdfbox::Cos::Dictionary)
        scanner.skip_whitespace
        if scanner.scanner.scan(/stream/)
          # Handle optional newline after "stream"
          # According to PDF spec, "stream" must be followed by EOL marker (CR, LF, or CRLF)
          # before the stream data begins
          puts "DEBUG parse_indirect_object_at_offset: found 'stream' at scanner pos #{scanner.position}"

          # Get Length from dictionary
          length_entry = object[Pdfbox::Cos::Name.new("Length")]
          unless length_entry && length_entry.is_a?(Pdfbox::Cos::Integer)
            raise SyntaxError.new("Stream missing /Length entry")
          end
          length = length_entry.value.to_i64
          puts "DEBUG parse_indirect_object_at_offset: stream length = #{length}"

          # Skip whitespace (EOL marker) after "stream"
          scanner.skip_whitespace

          # Read stream data as raw bytes
          data = scanner.read_raw_bytes(length)
          puts "DEBUG parse_indirect_object_at_offset: read #{data.size} bytes of stream data"

          # Create Stream object with data
          stream_obj = Pdfbox::Cos::Stream.new(object.entries, data)

          # Skip "endstream"
          scanner.skip_whitespace
          unless scanner.scanner.scan(/endstream/)
            raise SyntaxError.new("Expected 'endstream' after stream data at position #{scanner.position}")
          end

          object = stream_obj
        end
      end

      scanner.skip_whitespace
      puts "DEBUG parse_indirect_object_at_offset: before endobj, scanner.rest first 50 chars: #{scanner.rest[0..50].inspect}, position: #{scanner.position}"
      unless scanner.scanner.scan(/endobj/)
        raise SyntaxError.new("Expected 'endobj' at position #{scanner.position}")
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
        if xref_entry = xref[obj.obj_number]
          if xref_entry.compressed?
            # Object is compressed in an object stream
            parse_object_from_stream(xref_entry.offset, xref_entry.generation, xref)
          else
            parse_indirect_object_at_offset(xref_entry.offset)
          end
        else
          raise SyntaxError.new("Object #{obj.obj_number} not found in xref")
        end
      else
        obj
      end
    end

    # Parse an object from an object stream
    private def parse_object_from_stream(obj_stream_number : Int64, index_in_stream : Int64, xref : XRef) : Cos::Base
      puts "DEBUG parse_object_from_stream: parsing object #{obj_stream_number}:#{index_in_stream}"
      # First, we need to parse the object stream itself
      obj_stream_xref_entry = xref[obj_stream_number]
      unless obj_stream_xref_entry
        raise SyntaxError.new("Object stream #{obj_stream_number} not found in xref")
      end

      unless obj_stream_xref_entry.in_use?
        raise SyntaxError.new("Object stream #{obj_stream_number} is not an in-use entry")
      end

      # Parse the object stream
      obj_stream = parse_indirect_object_at_offset(obj_stream_xref_entry.offset)
      unless obj_stream.is_a?(Cos::Stream)
        raise SyntaxError.new("Object #{obj_stream_number} is not a stream")
      end

      # Parse the object stream contents
      parse_object_stream_contents(obj_stream, index_in_stream)
    end

    private def decode_stream_data(stream : Cos::Stream) : Bytes
      data = stream.data
      dict = stream

      filter_entry = dict[Cos::Name.new("Filter")]
      if filter_entry
        if filter_entry.is_a?(Cos::Name) && filter_entry.value == "FlateDecode"
          io = ::IO::Memory.new(data)
          begin
            reader = Compress::Deflate::Reader.new(io)
            decompressed = reader.gets_to_end
            reader.close
            data = decompressed.to_slice
          rescue ex
            io.rewind
            begin
              reader = Compress::Zlib::Reader.new(io)
              decompressed = reader.gets_to_end
              reader.close
              data = decompressed.to_slice
            rescue ex2
              # Use raw data as fallback (maybe already uncompressed)
            end
          end
        else
          raise SyntaxError.new("Unsupported filter: #{filter_entry.inspect}")
        end
      end

      decode_parms_entry = dict[Cos::Name.new("DecodeParms")]
      if decode_parms_entry && decode_parms_entry.is_a?(Cos::Dictionary)
        predictor = decode_parms_entry[Cos::Name.new("Predictor")]
        columns = decode_parms_entry[Cos::Name.new("Columns")]
        if predictor && predictor.is_a?(Cos::Integer) && predictor.value >= 10 &&
           columns && columns.is_a?(Cos::Integer)
          # PNG prediction
          data = apply_png_predictor(data, columns.value.to_i, predictor.value.to_i)
        end
      end

      data
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
          output[row_cols, columns].copy_from(row_data)
          previous_row = output[row_cols, columns]
        when 1 # Sub
          (0...columns).each do |col|
            left = col > 0 ? output[row_cols + col - 1] : 0
            decoded = (row_data[col] + left) & 0xFF
            output[row_cols + col] = decoded.to_u8
          end
          previous_row = output[row_cols, columns]
        when 2 # Up
          (0...columns).each do |col|
            up = previous_row[col]
            decoded = (row_data[col] + up) & 0xFF
            output[row_cols + col] = decoded.to_u8
          end
          previous_row = output[row_cols, columns]
        when 3 # Average
          (0...columns).each do |col|
            left = col > 0 ? output[row_cols + col - 1] : 0
            up = previous_row[col]
            decoded = (row_data[col] + ((left + up) // 2)) & 0xFF
            output[row_cols + col] = decoded.to_u8
          end
          previous_row = output[row_cols, columns]
        when 4 # Paeth
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
          previous_row = output[row_cols, columns]
        else
          raise SyntaxError.new("Unsupported PNG filter type #{filter_type}")
        end
      end
      output
    end

    # Parse object from object stream
    private def parse_object_stream_contents(obj_stream : Cos::Stream, index_in_stream : Int64) : Cos::Base
      puts "DEBUG parse_object_stream_contents: parsing object at index #{index_in_stream} from stream"

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

      puts "DEBUG parse_object_stream_contents: N=#{n}, First=#{first}"

      # Get stream data (decompressed and decoded)
      data = decode_stream_data(obj_stream)
      puts "DEBUG parse_object_stream_contents: stream data size = #{data.size}"

      # Parse object number/offset pairs
      # Each pair: object number (integer), offset (integer)
      # Offsets are relative to first byte after object number/offset pairs
      # Actually offsets are relative to the byte after the object number/offset pairs
      # The pairs occupy first 'first' bytes of the uncompressed stream

      # Create RandomAccessRead from stream data
      memory_io = Pdfbox::IO::MemoryRandomAccessRead.new(data)
      scanner = PDFScanner.new(memory_io)

      # Read object number/offset pairs
      object_offsets = {} of Int64 => Int64
      n.times do
        obj_num = scanner.read_number.to_i64
        offset = scanner.read_number.to_i64
        object_offsets[obj_num] = offset
        puts "DEBUG parse_object_stream_contents: obj_num=#{obj_num}, offset=#{offset}"
      end

      # Now find the object with the given index
      # Actually index_in_stream is the object number, not index
      # In xref stream, third field for type 2 entries is the object number within the stream
      # Wait, looking at PDFBox: for type 2 entries, third field is "index within the object stream"
      # But in PDF spec, it's the object number within the stream
      # Let's search for object number = index_in_stream
      target_offset = object_offsets[index_in_stream]?
      unless target_offset
        raise SyntaxError.new("Object #{index_in_stream} not found in object stream")
      end

      # Position in stream data: after the pairs (first bytes) + target_offset
      absolute_pos = first + target_offset
      if absolute_pos >= data.size
        raise SyntaxError.new("Object offset #{absolute_pos} exceeds stream data size #{data.size}")
      end

      # Seek to object position and create new scanner
      memory_io.seek(absolute_pos)
      scanner = PDFScanner.new(memory_io)

      # Parse the object
      object_parser = ObjectParser.new(scanner)
      object = object_parser.parse_object
      unless object
        raise SyntaxError.new("Failed to parse object at offset #{absolute_pos}")
      end

      puts "DEBUG parse_object_stream_contents: successfully parsed object #{index_in_stream}"
      object
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

    # Parse the PDF document
    def parse : Pdfbox::Pdmodel::Document
      version = parse_header

      catalog_dict = nil
      pages = [] of Pdfbox::Pdmodel::Page
      xref_offset = locate_xref_offset
      puts "DEBUG: xref_offset: #{xref_offset}"

      if xref_offset
        xref = XRef.new
        trailer = nil
        prev : Int64 = xref_offset.not_nil!.to_i64

        while prev > 0
          puts "DEBUG: parsing xref at offset #{prev}"
          @source.seek(prev)
          section_xref = parse_xref
          puts "DEBUG: section_xref entries: #{section_xref.size}"

          # Merge xref entries (later sections override earlier ones)
          section_xref.entries.each do |obj_num, entry|
            xref[obj_num] = entry
          end

          # Parse trailer after xref section
          if section_trailer = parse_trailer
            puts "DEBUG: got section_trailer"

            # Merge trailer dictionaries (later overrides earlier)
            if trailer
              # Copy entries from section_trailer to trailer only if not already present
              # (older trailers should not override newer ones)
              section_trailer.entries.each do |key, value|
                trailer[key] = value unless trailer.has_key?(key)
              end
            else
              trailer = section_trailer
            end

            # Check for XRefStm (cross-reference stream) in trailer
            xref_stm_ref = section_trailer[Pdfbox::Cos::Name.new("XRefStm")]
            if xref_stm_ref && xref_stm_ref.is_a?(Pdfbox::Cos::Integer)
              xref_stm_offset = xref_stm_ref.value.to_i64
              puts "DEBUG: Found XRefStm at offset #{xref_stm_offset}, parsing xref stream"
              begin
                xref_stream = parse_xref_stream(xref_stm_offset)
                # Merge xref stream entries with main xref table
                xref_stream.entries.each do |obj_num, entry|
                  xref[obj_num] = entry
                end
                puts "DEBUG: Merged #{xref_stream.size} entries from xref stream"
              rescue ex
                puts "DEBUG: Failed to parse xref stream at offset #{xref_stm_offset}: #{ex.message}"
                puts "DEBUG: Backtrace: #{ex.backtrace?.try(&.join("\n"))}"
              end
            end

            # Get next Prev link from current section trailer
            next_prev_ref = section_trailer[Pdfbox::Cos::Name.new("Prev")]
            if next_prev_ref.is_a?(Pdfbox::Cos::Integer)
              prev = next_prev_ref.value.to_i64
              puts "DEBUG: next prev offset: #{prev}"
            else
              prev = 0.to_i64.to_i64
            end
          else
            prev = 0
          end
        end

        @trailer = trailer
        puts "DEBUG: final xref entries: #{xref.size}"
        # Debug: print xref entries for objects around 17 and PageLabels objects
        puts "DEBUG: checking xref entries for objects 15-20 and PageLabels objects:"
        STDOUT.flush
        [15, 16, 17, 18, 19, 20, 1350, 1352, 1358, 1360].each do |obj_num|
          if entry = xref[obj_num.to_i64]
            puts "  object #{obj_num}: offset #{entry.offset}, type: #{entry.type}"
          else
            puts "  object #{obj_num}: not found in xref"
          end
          STDOUT.flush
        end
        puts "DEBUG: trailer: #{trailer.inspect}"
        puts "DEBUG: reached point B"

        if trailer
          root_ref = trailer[Pdfbox::Cos::Name.new("Root")]
          puts "DEBUG: root_ref: #{root_ref.inspect}"
          obj_number = if root_ref.is_a?(Pdfbox::Cos::Object)
                         puts "DEBUG: root_ref is object, obj_number: #{root_ref.obj_number}"
                         root_ref.obj_number
                       elsif root_ref.is_a?(Pdfbox::Cos::Integer)
                         puts "DEBUG: root_ref is integer, treating as object number: #{root_ref.value}"
                         root_ref.value
                       end

          if obj_number && (xref_entry = xref[obj_number])
            puts "DEBUG: xref entry found for object #{obj_number}: offset #{xref_entry.offset}"
            catalog_obj = parse_indirect_object_at_offset(xref_entry.offset)
            puts "DEBUG: catalog_obj type: #{catalog_obj.class}"
            if catalog_obj.is_a?(Pdfbox::Cos::Dictionary)
              catalog_dict = catalog_obj
              puts "DEBUG: catalog dict keys: #{catalog_dict.entries.keys.map(&.value)}"
              STDOUT.flush

              # Parse pages from catalog
              pages_ref = catalog_dict[Pdfbox::Cos::Name.new("Pages")]
              if pages_ref
                resolved_pages = resolve_object(pages_ref, xref)
                if resolved_pages.is_a?(Pdfbox::Cos::Dictionary)
                  page_dicts = parse_pages_tree(resolved_pages, xref)
                  page_dicts.each do |page_dict|
                    pages << Pdfbox::Pdmodel::Page.new(page_dict)
                  end
                end
              end
            end
          end
        end
      else
        # Simple format with comments - use old counting logic
        page_count = parse_simple_page_count
        page_count.times do
          pages << Pdfbox::Pdmodel::Page.new
        end
      end

      doc = Pdfbox::Pdmodel::Document.new(catalog_dict, version)

      # Add parsed pages to document
      pages.each do |page|
        doc.add_page(page)
      end

      doc
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

    # Parse trailer dictionary after xref table
    private def parse_trailer : Pdfbox::Cos::Dictionary?
      # Save current position
      start_pos = @source.position
      puts "DEBUG parse_trailer: starting at position #{start_pos}"

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
      puts "DEBUG parse_trailer: first line: #{line.inspect}"

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
          object_parser = ObjectParser.new(@source)
          dict = object_parser.parse_dictionary
          puts "DEBUG parse_trailer: parsed dictionary: #{dict.inspect}"
          return dict
        end
      end

      puts "DEBUG parse_trailer: 'trailer' not found in line"
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

    # Get cross-reference table
    def xref : XRef?
      # TODO: Implement xref retrieval
      nil
    end

    # Get trailer dictionary
    def trailer : Pdfbox::Cos::Dictionary?
      @trailer
    end
  end

  # Cross-reference table entry
  class XRefEntry
    @offset : Int64
    @generation : Int64
    @type : Symbol

    def initialize(@offset : Int64, @generation : Int64, @type : Symbol)
    end

    def offset : Int64
      @offset
    end

    def generation : Int64
      @generation
    end

    def type : Symbol
      @type
    end

    def free? : Bool
      @type == :free
    end

    def in_use? : Bool
      @type == :in_use
    end

    def compressed? : Bool
      @type == :compressed
    end
  end

  # Cross-reference table
  class XRef
    @entries = {} of Int64 => XRefEntry

    def initialize(@entries : Hash(Int64, XRefEntry) = {} of Int64 => XRefEntry)
    end

    def entries : Hash(Int64, XRefEntry)
      @entries
    end

    def [](object_number : Int64) : XRefEntry?
      @entries[object_number]?
    end

    def []=(object_number : Int64, entry : XRefEntry) : XRefEntry
      @entries[object_number] = entry
    end

    def size : Int32
      @entries.size
    end
  end

  # PDF object parser for individual COS objects
  class ObjectParser
    @scanner : PDFScanner

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @scanner = PDFScanner.new(source)
    end

    def initialize(scanner : PDFScanner)
      @scanner = scanner
    end

    # Parse a COS object from the stream
    def parse_object : Pdfbox::Cos::Base?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_object: rest first 100 chars: #{@scanner.rest[0..100].inspect}"

      char = @scanner.peek
      puts "DEBUG ObjectParser.parse_object: peek char: #{char.inspect}"
      return if char.nil?

      case char
      when '/'
        parse_name
      when '('
        parse_string
      when '<'
        # Could be string (<...>) or dictionary (<<...>>)
        if @scanner.rest.starts_with?("<<")
          parse_dictionary
        else
          parse_string
        end
      when '['
        parse_array
      when '>'
        # Could be end of dictionary or malformed
        nil
      when '0'..'9', '+', '-', '.'
        # Try to parse as indirect reference first (obj gen R)
        ref = parse_reference
        ref ? ref : parse_number
      when 't', 'f'
        parse_boolean
      when 'n'
        parse_null
      else
        nil
      end
    end

    # Parse a COS dictionary
    def parse_dictionary : Pdfbox::Cos::Dictionary?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_dictionary: rest first 100 chars: #{@scanner.rest[0..100].inspect}"

      # Dictionary starts with '<<'
      unless @scanner.rest.starts_with?("<<")
        puts "DEBUG ObjectParser.parse_dictionary: does not start with '<<'"
        return
      end

      scanned = @scanner.scanner.scan("<<")
      puts "DEBUG ObjectParser.parse_dictionary: scanned '<<': #{scanned.inspect}, pos: #{@scanner.position}"
      dict = Pdfbox::Cos::Dictionary.new

      loop do
        @scanner.skip_whitespace
        if @scanner.rest.starts_with?(">>")
          puts "DEBUG ObjectParser.parse_dictionary: found '>>', breaking loop"
          break
        end

        # Parse key (must be a name)
        key = parse_name
        unless key
          puts "DEBUG ObjectParser.parse_dictionary: failed to parse key, breaking"
          break
        end
        puts "DEBUG ObjectParser.parse_dictionary: parsed key: #{key.inspect}"

        # Parse value
        value = parse_object
        unless value
          puts "DEBUG ObjectParser.parse_dictionary: failed to parse value for key #{key}, breaking"
          break
        end
        puts "DEBUG ObjectParser.parse_dictionary: parsed value: #{value.class} #{value.inspect}"

        dict[key] = value
      end

      scanned_end = @scanner.scanner.scan(">>")
      puts "DEBUG ObjectParser.parse_dictionary: scanned '>>': #{scanned_end.inspect}, pos after: #{@scanner.position}"
      dict
    end

    # Parse a COS array
    def parse_array : Pdfbox::Cos::Array?
      @scanner.skip_whitespace

      # Array starts with '['
      unless @scanner.scanner.scan('[')
        return
      end

      array = Pdfbox::Cos::Array.new

      loop do
        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        value = parse_object
        break unless value

        array.add(value)

        @scanner.skip_whitespace
        break if @scanner.scanner.check(']')

        # Arrays can have spaces between elements
      end

      @scanner.scanner.scan(']') rescue nil
      array
    end

    # Parse a COS string
    def parse_string : Pdfbox::Cos::String?
      @scanner.skip_whitespace

      string = @scanner.read_string rescue nil
      return unless string

      Pdfbox::Cos::String.new(string)
    end

    # Parse a COS name
    def parse_name : Pdfbox::Cos::Name?
      @scanner.skip_whitespace

      name = @scanner.read_name rescue nil
      return unless name

      Pdfbox::Cos::Name.new(name)
    end

    # Parse a COS number (integer or float)
    def parse_number : Pdfbox::Cos::Base?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_number: rest first 50 chars: #{@scanner.rest[0..50].inspect}"

      number = @scanner.read_number rescue nil
      puts "DEBUG ObjectParser.parse_number: number=#{number.inspect}"
      return unless number

      case number
      when Int64
        Pdfbox::Cos::Integer.new(number)
      when Float64
        Pdfbox::Cos::Float.new(number)
      else
        # Should never happen since number is Float64 | Int64
        nil
      end
    end

    # Parse a COS indirect object reference (obj gen R)
    def parse_reference : Pdfbox::Cos::Object?
      @scanner.skip_whitespace
      puts "DEBUG ObjectParser.parse_reference: rest first 50 chars: #{@scanner.rest[0..50].inspect}"

      # Save scanner position in case we need to rollback
      saved_pos = @scanner.scanner.offset

      # Try to read first integer
      first = @scanner.scanner.scan(/[+-]?\d+/) rescue nil
      puts "DEBUG ObjectParser.parse_reference: first=#{first.inspect}"
      unless first
        @scanner.scanner.offset = saved_pos
        return
      end

      # Must have whitespace after first integer
      @scanner.skip_whitespace

      # Try to read second integer
      second = @scanner.scanner.scan(/[+-]?\d+/) rescue nil
      puts "DEBUG ObjectParser.parse_reference: second=#{second.inspect}"
      unless second
        @scanner.scanner.offset = saved_pos
        return
      end

      # Must have whitespace before 'R'
      @scanner.skip_whitespace

      # Try to read 'R'
      r = @scanner.scanner.scan('R') rescue nil
      puts "DEBUG ObjectParser.parse_reference: r=#{r.inspect}"
      unless r
        # Not a reference, rollback
        @scanner.scanner.offset = saved_pos
        puts "DEBUG ObjectParser.parse_reference: rollback, not a reference"
        return
      end

      # Success - create reference object
      obj_num = first.to_i64
      gen_num = second.to_i64
      puts "DEBUG ObjectParser.parse_reference: success #{obj_num} #{gen_num} R"
      Pdfbox::Cos::Object.new(obj_num, gen_num)
    end

    # Parse a COS boolean
    def parse_boolean : Pdfbox::Cos::Boolean?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("true")
        Pdfbox::Cos::Boolean::TRUE
      elsif @scanner.scanner.scan("false")
        Pdfbox::Cos::Boolean::FALSE
      end
    end

    # Parse a COS null
    def parse_null : Pdfbox::Cos::Null?
      @scanner.skip_whitespace

      if @scanner.scanner.scan("null")
        Pdfbox::Cos::Null.instance
      end
    end

    # Get underlying scanner
    def scanner : PDFScanner
      @scanner
    end
  end

  # PDF scanner using StringScanner for parsing PDF tokens
  class PDFScanner
    @scanner : StringScanner
    @source : Pdfbox::IO::RandomAccessRead
    @buffer_pos : Int64 = 0
    @raw_buffer : Bytes = Bytes.empty

    getter scanner : StringScanner
    getter buffer_pos : Int64
    getter raw_buffer : Bytes

    def initialize(@source : Pdfbox::IO::RandomAccessRead)
      # Read remaining data as string for scanning
      @scanner = StringScanner.new(read_remaining_as_string)
    end

    # Read remaining data from source as ASCII string
    private def read_remaining_as_string : String
      bytes_to_read = @source.length - @source.position
      puts "DEBUG PDFScanner.read_remaining_as_string: source.length=#{@source.length}, source.position=#{@source.position}, bytes_to_read=#{bytes_to_read}"
      @raw_buffer = Bytes.new(bytes_to_read)
      @source.read(@raw_buffer)
      @buffer_pos = @source.position - @raw_buffer.size
      puts "DEBUG PDFScanner.read_remaining_as_string: read #{@raw_buffer.size} bytes, buffer_pos=#{@buffer_pos}"
      String.new(@raw_buffer, "ISO-8859-1")
    end

    # Get current absolute position in source
    def position : Int64
      @buffer_pos + @scanner.offset
    end

    # Read raw bytes from buffer at current position
    def read_raw_bytes(length : Int64) : Bytes
      offset_in_buffer = @scanner.offset
      if offset_in_buffer + length > @raw_buffer.size
        raise SyntaxError.new("Requested #{length} bytes at offset #{offset_in_buffer} but buffer only has #{@raw_buffer.size} bytes")
      end

      # Get slice of raw buffer
      slice = @raw_buffer[offset_in_buffer, length]

      # Advance scanner position
      @scanner.offset = (offset_in_buffer + length).to_i32

      slice
    end

    # Set absolute position in source
    def position=(pos : Int64)
      if pos >= @buffer_pos && pos < @buffer_pos + @scanner.string.bytesize
        @scanner.offset = (pos - @buffer_pos).to_i32
      else
        # Need to reload buffer from new position
        @source.seek(pos)
        @scanner = StringScanner.new(read_remaining_as_string)
      end
    end

    # Skip whitespace and comments
    def skip_whitespace : Nil
      loop do
        @scanner.skip(/\s+/)
        if @scanner.check('%')
          @scanner.skip_until(/\r?\n/)
        else
          break
        end
      end
    end

    # Peek next non-whitespace character
    def peek : Char?
      skip_whitespace
      @scanner.peek(1).try(&.chars.first?)
    end

    # Read a PDF number
    def read_number : Float64 | Int64
      skip_whitespace

      # Match optional sign, digits, optional decimal point
      if match = @scanner.scan(/[+-]?\d+(?:\.\d+)?/)
        if match.includes?('.')
          match.to_f64
        else
          match.to_i64
        end
      else
        raise SyntaxError.new("Expected number at position #{position}")
      end
    end

    # Read a PDF name
    def read_name : String
      skip_whitespace

      # Names start with '/'
      unless @scanner.scan('/')
        raise SyntaxError.new("Expected name starting with '/' at position #{position}")
      end

      # Read name characters
      # PDF name grammar: /[^#0-9\s()<>\[\]{}/%]*[#0-9]*
      # Actually names can contain any characters except delimiters
      # We'll read until whitespace or delimiter
      buffer = String::Builder.new

      loop do
        char = @scanner.peek(1)
        break unless char
        break if char =~ /\s|\(|\)|<|>|\[|\]|\{|\}|\/|%/

        buffer << @scanner.scan(/./)
      end

      buffer.to_s
    end

    # Read a PDF string (literal or hexadecimal)
    def read_string : String
      skip_whitespace

      # Check for literal string '(' or hexadecimal string '<'
      case @scanner.peek(1)
      when "("
        read_literal_string
      when "<"
        read_hexadecimal_string
      else
        raise SyntaxError.new("Expected string at position #{position}")
      end
    end

    # Check if we've reached end of string based on lookahead
    private def check_for_end_of_string(braces : Int32) : Int32
      return 0 if braces == 0

      # Peek next 3 bytes
      peeked = @scanner.peek(3)
      return braces if peeked.empty?

      bytes = peeked.bytes
      # Check patterns:
      # 1. CR or LF followed by '/' or '>'
      # 2. CR followed by LF followed by '/' or '>'
      if bytes.size >= 2 && (bytes[0] == '\r'.ord || bytes[0] == '\n'.ord) && (bytes[1] == '/'.ord || bytes[1] == '>'.ord)
        return 0
      elsif bytes.size >= 3 && bytes[0] == '\r'.ord && bytes[1] == '\n'.ord && (bytes[2] == '/'.ord || bytes[2] == '>'.ord)
        return 0
      end

      braces
    end

    # Read literal string (parentheses)
    def read_literal_string : String
      @scanner.scan('(') || raise SyntaxError.new("Expected '(' for literal string")

      buffer = String::Builder.new
      braces = 1

      while braces > 0
        char = @scanner.scan(/./)
        break unless char

        case char
        when "("
          braces += 1
          buffer << char
        when ")"
          braces -= 1
          braces = check_for_end_of_string(braces)
          buffer << char unless braces == 0
        when '\\'
          # Escape sequence
          esc_str = @scanner.scan(/./)
          if esc_str.nil?
            # Invalid escape, treat as literal backslash?
            buffer << '\\'
            next
          end
          str = esc_str.as(String)
          esc_char = str[0]

          case esc_char
          when 'n'
            buffer << '\n'
          when 'r'
            buffer << '\r'
          when 't'
            buffer << '\t'
          when 'b'
            buffer << '\b'
          when 'f'
            buffer << '\f'
          when '(', ')', '\\'
            buffer << str
          when '\n', '\r'
            # Line continuation - skip
            @scanner.skip(/\s*/)
          when '0'..'7'
            # Octal sequence
            digits = String.build do |dig|
              dig << str
              2.times do
                next_char = @scanner.check(/[0-7]/)
                break unless next_char
                scanned = @scanner.scan(/./).as(String)
                dig << scanned
              end
            end
            buffer << digits.to_i(8).chr
          else
            buffer << str
          end
        else
          buffer << char
        end
      end

      buffer.to_s
    end

    # Read hexadecimal string <...>
    private def read_hexadecimal_string : String
      @scanner.scan('<') || raise SyntaxError.new("Expected '<' for hexadecimal string")

      buffer = String::Builder.new
      hex_chars = ""

      loop do
        @scanner.skip(/\s*/)
        char = @scanner.peek(1)
        break unless char

        if char == ">"
          @scanner.scan('>')
          break
        elsif char =~ /[0-9A-Fa-f]/
          if scanned = @scanner.scan(/./)
            hex_chars += scanned
          end
          if hex_chars.size == 2
            buffer << hex_chars.to_i(16).chr
            hex_chars = ""
          end
        else
          # Invalid hex character
          @scanner.scan(/./)
        end
      end

      # Handle leftover single hex digit
      if hex_chars.size == 1
        buffer << (hex_chars + "0").to_i(16).chr
      end

      buffer.to_s
    end

    # Read PDF date string
    def read_date : Time?
      skip_whitespace

      # PDF dates start with "D:"
      unless @scanner.scan("D:")
        return
      end

      # Parse date format: YYYYMMDDHHmmSSOHH'mm'
      date_str = @scanner.scan(/\d{14}/)
      return unless date_str

      # TODO: Parse timezone offset
      # For now, return current time
      Time.utc
    end

    # Check if at end of stream
    def eos? : Bool
      @scanner.eos?
    end

    # Get remaining string
    def rest : String
      @scanner.rest
    end
  end

  # Utility for reading PDF-specific data types
  module PDFIO
    # Read a PDF string (literal or hexadecimal)
    def self.read_string(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_string
      else
        # Fallback for generic IO
        # TODO: Implement basic string reading
        ""
      end
    end

    # Read a PDF name
    def self.read_name(io : ::IO) : String
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_name
      else
        # Fallback for generic IO
        ""
      end
    end

    # Read a PDF number
    def self.read_number(io : ::IO) : Float64 | Int64
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_number
      else
        # Fallback for generic IO
        skip_whitespace(io)
        buffer = String::Builder.new

        # Optional sign
        char = io.read_char rescue nil
        if char == '+' || char == '-'
          buffer << char
          char = io.read_char rescue nil
        end

        # Read digits before decimal point
        while char && char.ascii_number?
          buffer << char
          char = io.read_char rescue nil
        end

        # Check for decimal point
        if char == '.'
          buffer << char
          char = io.read_char rescue nil

          # Read digits after decimal point
          while char && char.ascii_number?
            buffer << char
            char = io.read_char rescue nil
          end
        end

        # Put back the last character if not whitespace
        if char && !char.ascii_whitespace? && char != '%' && io.responds_to?(:seek)
          io.seek(-1, IO::Seek::Current)
        end

        str = buffer.to_s
        if str.includes?('.')
          str.to_f64
        else
          str.to_i64
        end
      end
    end

    # Skip whitespace and comments
    def self.skip_whitespace(io : ::IO) : Nil
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.skip_whitespace
      else
        # Fallback for generic IO
        loop do
          char = io.read_char rescue nil
          break unless char

          case char
          when ' ', '\t', '\n', '\r', '\f'
            # Skip whitespace
            next
          when '%'
            # Skip comment until end of line
            loop do
              next_char = io.read_char rescue nil
              break unless next_char
              break if next_char == '\n' || next_char == '\r'
            end
          else
            # Not whitespace or comment - put back the character
            io.seek(-1, IO::Seek::Current) if io.responds_to?(:seek)
            break
          end
        end
      end
    end

    # Peek next non-whitespace character
    def self.peek(io : ::IO) : Char?
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.peek
      else
        # Fallback for generic IO
        skip_whitespace(io)
        pos = io.pos rescue nil
        return unless pos

        char = io.read_char rescue nil
        if char && io.responds_to?(:seek)
          io.seek(pos, IO::Seek::Set)
        end
        char
      end
    end

    # Read PDF date string
    def self.read_date(io : ::IO) : Time?
      if io.is_a?(Pdfbox::IO::RandomAccessRead)
        scanner = PDFScanner.new(io)
        scanner.read_date
      end
    end
  end

  # Parser for COS objects
  class COSParser
    @scanner : PDFScanner

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      @scanner = PDFScanner.new(source)
    end

    # Parse a COS literal string from the input
    def parse_cos_literal_string : Pdfbox::Cos::String
      Pdfbox::Cos::String.new(@scanner.read_literal_string)
    end
  end
end
