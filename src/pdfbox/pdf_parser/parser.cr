require "log"
require "../cos"
require "../cos/icosparser"
require "../cos/object_key"
require "./brute_force_parser"
require "./base_parser"
require "./cos_parser"
require "./pdf_object_stream_parser"
require "./xref_trailer_resolver"
require "./xref_parser"

module Pdfbox::Pdfparser
  # Main PDF parser class
  class Parser < COSParser
    include Pdfbox::Cos::ICOSParser
    Log = ::Log.for(self)

    # Safety limits to prevent infinite loops with malformed PDFs
    MAX_OBJECTS_PER_STREAM =    10_000
    MAX_XREF_ENTRIES       = 1_000_000
    MAX_OBJECT_PARSE_SIZE  = 4_096_i64 # 4KB
    @trailer : Pdfbox::Cos::Dictionary?
    @xref : XRef?
    @xref_trailer_resolver : XrefTrailerResolver?
    @object_pool : Hash(Cos::ObjectKey, Cos::Object)
    @decompressed_objects : Hash(Int64, Hash(Cos::ObjectKey, Cos::Base))
    @brute_force_parser : BruteForceParser?
    @lenient : Bool

    def initialize(source : Pdfbox::IO::RandomAccessRead)
      super(source)
      @trailer = nil
      @xref = nil
      @xref_trailer_resolver = nil
      @object_pool = Hash(Cos::ObjectKey, Cos::Object).new
      @decompressed_objects = Hash(Int64, Hash(Cos::ObjectKey, Cos::Base)).new
      @brute_force_parser = nil
      @lenient = true
    end

    property xref
    getter object_pool
    getter decompressed_objects
    property lenient

    private def xref_resolver : XrefTrailerResolver
      @xref_trailer_resolver ||= XrefTrailerResolver.new
    end

    protected def get_brute_force_parser : BruteForceParser
      @brute_force_parser ||= BruteForceParser.new(self)
    end

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
      if source.peek == '%'.ord
        read_line # skip binary comment line
      end
      version
    end

    protected def read_line : String
      builder = String::Builder.new
      while byte = source.read
        ch = byte.chr
        break if ch == '\n'
        builder << ch
      end
      builder.to_s
    end

    # Parse cross-reference table
    # ameba:disable Metrics/CyclomaticComplexity
    def parse_xref(start_byte_pos : Int64? = nil) : XRef
      # puts "DEBUG: parse_xref called" if @lenient
      start_time = Time.instant
      xref = XRef.new
      # Skip whitespace/comments before "xref"

      # Some PDFs have incorrect startxref offsets. Try to find "xref" by seeking back a bit.
      original_pos = source.position

      # First check if we're at an xref stream (object number)
      source.seek(original_pos)
      skip_spaces
      c = source.peek
      if c && digit?(c)
        # Might be an xref stream (object header). Try parsing as xref stream.
        begin
          return parse_xref_stream(original_pos, standalone: false)
        rescue ex : SyntaxError
          # Not an xref stream, fall back to searching for "xref"
          Log.debug { "parse_xref: failed to parse xref stream at #{original_pos}: #{ex.message}" }
        end
      end
      # Reset position for xref table search
      source.seek(original_pos)

      max_seek_back = 1024_i64
      seek_back = Math.min(original_pos, max_seek_back)

      # Try seeking back incrementally to find "xref" using incremental parsing
      found_pos = nil

      (0..seek_back).step(1).each do |offset|
        test_pos = original_pos - offset
        source.seek(test_pos)

        # Skip whitespace and comments at test position (similar to skip_spaces but track position)
        current_pos = test_pos
        loop do
          c = source.peek
          break unless c

          if c == 37    # '%' - comment
            source.read # consume '%'
            current_pos += 1
            # Skip to end of line
            loop do
              c2 = source.read
              break unless c2
              current_pos += 1
              break if eol?(c2)
            end
          elsif whitespace?(c)
            source.read # consume whitespace
            current_pos += 1
          else
            break
          end
        end

        # Now check if next 4 characters are "xref"
        source.seek(current_pos)
        found = true
        4.times do |i|
          c = source.read
          unless c && c.chr == "xref"[i]
            found = false
            break
          end
        end

        if found
          found_pos = current_pos
          break
        end
      end

      # Seek to found position or original position
      if found_pos
        source.seek(found_pos)
      else
        source.seek(original_pos)
      end

      # Skip whitespace and read "xref" keyword
      skip_spaces
      xref_start_pos = source.position
      begin
        read_expected_string("xref")
      rescue ex : SyntaxError
        raise SyntaxError.new("Expected 'xref' keyword at position #{source.position}")
      end

      Log.debug { "parse_xref: parsing xref table at position #{xref_start_pos}" }

      # Signal new xref object to resolver
      xref_resolver.next_xref_obj(xref_start_pos, XRefType::Table)

      # Check for trailer after xref (empty xref table)
      next_str = read_string
      # Rewind to before the string we just read
      source.rewind(next_str.bytesize)

      if next_str.starts_with?("trailer")
        Log.warn { "skipping empty xref table" }
        elapsed = Time.instant - start_time
        Log.warn { "parse_xref: parsed #{xref.size} entries in #{elapsed.total_milliseconds.round(2)}ms" }
        return xref
      end

      # Xref tables can have multiple sections. Each starts with a starting object id and a count.
      loop do
        skip_spaces

        # Check for next keyword (trailer, startxref) or end of input
        c = source.peek
        break unless c
        ch = c.chr
        break if ch == 't' || ch == 's' || end_of_name?(c)

        # Read line with start object id and count
        line = read_line
        split_string = line.strip.split(/\s+/)
        if split_string.size != 2
          raise SyntaxError.new("Unexpected XRefTable Entry: #{line}")
        end

        # First obj id
        begin
          curr_obj_id = split_string[0].to_i64
        rescue
          raise SyntaxError.new("XRefTable: invalid ID for the first object: #{line}")
        end

        # The number of objects in the xref table
        begin
          count = split_string[1].to_i32
        rescue
          raise SyntaxError.new("XRefTable: invalid number of objects: #{line}")
        end

        skip_spaces

        count.times do |i|
          if eof?
            break
          end

          next_char = source.peek
          break unless next_char
          if next_char.chr == 't' || end_of_name?(next_char)
            break
          end

          # Read xref entry line
          entry_line = read_line
          entry_parts = entry_line.strip.split(/\s+/)
          if entry_parts.size < 3
            Log.warn { "invalid xref line: #{entry_line}" }
            break
          end

          # This supports the corrupt table as reported in PDFBOX-474 (XXXX XXX XX n)
          begin
            curr_offset = entry_parts[0].to_i64
            curr_gen_id = entry_parts[1].to_i32
            if entry_parts.last == "n"
              # skip 0 offsets for in-use entries (corrupt)
              if curr_offset > 0
                key = Cos::ObjectKey.new(curr_obj_id + i, curr_gen_id.to_i64)
                xref[key] = curr_offset
                xref_resolver.add_xref(key, curr_offset)
              end
            elsif entry_parts[2] == "f"
              # Free entry: store offset 0
              key = Cos::ObjectKey.new(curr_obj_id + i, curr_gen_id.to_i64)
              xref[key] = 0
              xref_resolver.add_xref(key, 0_i64)
            else
              raise SyntaxError.new("Invalid xref entry type: #{entry_line}")
            end
          rescue
            raise SyntaxError.new("Invalid xref entry: #{entry_line}")
          end
        end
      end

      elapsed = Time.instant - start_time
      Log.warn { "parse_xref: parsed #{xref.size} entries in #{elapsed.total_milliseconds.round(2)}ms" }
      xref
    end

    # Parse an xref stream
    def parse_xref_stream(offset : Int64, standalone : Bool = false, resolver : XrefTrailerResolver? = nil) : XRef
      Log.debug { "parse_xref_stream: START parsing xref stream at offset #{offset}, standalone=#{standalone}" }
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

      # Signal new xref object to resolver if standalone
      if standalone
        (resolver || xref_resolver).next_xref_obj(offset, XRefType::Stream)
        (resolver || xref_resolver).current_trailer = dict
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
      xref = parse_xref_stream_entries(data, w, index_array, resolver)

      Log.debug { "parse_xref_stream: parsed #{xref.size} entries" }
      xref
    end

    protected def parse_w_array_from_dict(dict : Pdfbox::Cos::Dictionary) : Array(Int32)
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

    protected def parse_index_array_from_dict(dict : Pdfbox::Cos::Dictionary) : Tuple(Array(Int64), Int64)
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

    # ameba:disable Metrics/CyclomaticComplexity
    protected def parse_xref_stream_entries(data : Bytes, w : Array(Int32), index_array : Array(Int64), resolver : XrefTrailerResolver? = nil) : XRef
      Log.debug { "parse_xref_stream_entries: START, data size=#{data.size}, w=#{w}, index_array=#{index_array}" }
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
      total_entries = index_array.each_slice(2).sum { |pair| pair[1] }
      if total_entries > MAX_XREF_ENTRIES
        raise SyntaxError.new("XRef stream claims #{total_entries} entries, exceeding limit #{MAX_XREF_ENTRIES}")
      end
      entries_processed = 0_i64
      index_array.each_slice(2) do |pair|
        start, count = pair[0], pair[1]
        Log.debug { "parse_xref_stream: processing index range start=#{start}, count=#{count}" }
        count.to_i64.times do |i|
          # Calculate position in data (cumulative across all slices)
          pos = (entries_processed + i) * total_entry_width
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
            # Free entry
            generation = field3
            Log.debug { "parse_xref_stream: free entry for object #{obj_num}, gen=#{generation}" }
            key = Cos::ObjectKey.new(obj_num, generation)
            xref[key] = 0_i64
            (resolver || xref_resolver).add_xref(key, 0_i64)
            next
          when 1
            # In-use entry
            offset = field2
            generation = field3
            Log.debug { "parse_xref_stream: in-use entry obj #{obj_num}: offset=#{offset}, gen=#{generation}" }
            key = Cos::ObjectKey.new(obj_num, generation)
            xref[key] = offset
            (resolver || xref_resolver).add_xref(key, offset)
          when 2
            # Compressed entry
            obj_stream_number = field2
            index_in_stream = field3
            Log.debug { "parse_xref_stream: compressed entry obj #{obj_num}: obj_stream=#{obj_stream_number}, index=#{index_in_stream}" }
            # Compressed objects have generation 0, index_in_stream is stream_index
            key = Cos::ObjectKey.new(obj_num, 0_i64, index_in_stream.to_i32)
            # Store negative offset to indicate compressed entry (object stream number)
            xref[key] = -obj_stream_number
            (resolver || xref_resolver).add_xref(key, -obj_stream_number)
          else
            raise SyntaxError.new("Invalid entry type #{type} for object #{obj_num}")
          end
        end
      end
      xref
    end

    # Find object header near given offset (max_distance bytes) matching key if provided
    private def find_object_header_near(start_offset : Int64, key : Cos::ObjectKey? = nil, max_distance : Int64 = 2048) : Int64?
      window_start = start_offset - max_distance
      window_start = 0_i64 if window_start < 0
      window_end = start_offset + max_distance
      file_size = source.length
      window_end = file_size if window_end > file_size
      window_size = window_end - window_start
      return if window_size <= 0

      # Save current position
      saved_pos = source.position
      begin
        source.seek(window_start)
        # Read window into memory
        window_data = Bytes.new(window_size)
        source.read(window_data)

        # Convert to string for regex scanning (ISO-8859-1 preserves bytes)
        window_str = String.new(window_data, "ISO-8859-1")

        # Search for pattern: digits, whitespace, digits, whitespace, "obj"
        regex = /\d+\s+\d+\s+obj/
        matches = [] of {Int32, Int32, Int64} # start index, end index, object number
        window_str.scan(regex) do |match|
          match_str = match[0]
          # Parse object number from match (first number)
          if num_match = match_str.match(/^\d+/)
            obj_num = num_match[0].to_i64
            matches << {match.begin, match.end, obj_num}
          end
        end

        # If key provided, find match with matching object number (and optionally generation)
        if key
          matches.each do |start_idx, _, obj_num|
            if obj_num == key.number
              # We could also verify generation, but skip for now
              return window_start + start_idx
            end
          end
        end

        # No matching key, return the match closest to start_offset
        if matches.empty?
          return
        end

        # Find match with start closest to start_offset
        best_match = matches.min_by do |start_idx, _, _|
          (window_start + start_idx - start_offset).abs
        end
        window_start + best_match[0]
      ensure
        source.seek(saved_pos)
      end
    end

    # Parse object header using BaseParser (incremental)
    # ameba:disable Metrics/CyclomaticComplexity
    private def parse_object_header_incremental(offset : Int64, key : Cos::ObjectKey?) : Int64
      source.seek(offset)

      skip_spaces

      # If key is provided, try to find matching object header nearby
      if key
        corrected_offset = find_object_header_near(source.position, key, 2048)
        if corrected_offset && corrected_offset != source.position
          source.seek(corrected_offset)
          skip_spaces
        end
      end

      # Check if we're at a digit, sign, or decimal point
      c = source.peek
      unless c && (c.chr.ascii_number? || c.chr == '+' || c.chr == '-' || c.chr == '.')
        # Not a number, try to find any object header nearby
        corrected_offset = find_object_header_near(source.position, nil, 1024)
        if corrected_offset
          source.seek(corrected_offset)
          skip_spaces
        else
          # No object header found
          raise SyntaxError.new("Expected object header at position #{source.position}")
        end
      end

      obj_num = read_number.to_i64

      gen_num = read_number.to_i64

      skip_spaces
      read_expected_string("obj")

      # Verify object number/generation matches key if provided
      if key && (obj_num != key.number || gen_num != key.generation)
        raise SyntaxError.new("Object at offset #{offset} has number/generation #{obj_num}/#{gen_num}, expected #{key.number}/#{key.generation}")
      end

      position
    end

    # Parse an indirect object at given offset
    def parse_indirect_object_at_offset(offset : Int64, key : Cos::ObjectKey? = nil) : Pdfbox::Cos::Base
      Log.debug { "parse_indirect_object_at_offset: offset=#{offset}, key=#{key}" }
      # Get object from pool if key provided
      start_time = Time.instant
      cos_object = key ? get_object_from_pool(key) : nil

      # Check if already dereferenced
      if cos_object && (obj = cos_object.object)
        elapsed = Time.instant - start_time
        Log.warn { "parse_indirect_object_at_offset: cached object #{obj.inspect} took #{elapsed.total_milliseconds.round(2)}ms" }
        return obj
      end

      # Parse header using BaseParser
      parse_object_header_incremental(offset, key)

      # Parse object body using COSParser
      object_parser = COSParser.new(source, self)
      # The source is already positioned after "obj"
      object = object_parser.parse_object
      unless object
        raise SyntaxError.new("Failed to parse object at position #{source.position}")
      end

      # Handle stream if object is a dictionary
      object = handle_stream_incremental(object)

      # Check for endobj
      check_endobj_incremental

      # Set the parsed object on the Cos::Object from pool
      if cos_object
        cos_object.object = object
      end

      elapsed = Time.instant - start_time
      Log.warn { "parse_indirect_object_at_offset: parsed object #{object.inspect} took #{elapsed.total_milliseconds.round(2)}ms" }
      object
    end

    # Handle stream incrementally
    private def handle_stream_incremental(object : Pdfbox::Cos::Base) : Pdfbox::Cos::Base
      return object unless object.is_a?(Pdfbox::Cos::Dictionary)

      Log.debug { "handle_stream_incremental: called, position=#{position}" }
      skip_spaces

      # Check for "stream" keyword
      saved_pos = position
      begin
        read_expected_string("stream")
      rescue
        seek(saved_pos)
        return object
      end

      # Get Length from dictionary
      length_entry = object[Pdfbox::Cos::Name.new("Length")]
      Log.debug { "handle_stream_incremental: length_entry type = #{length_entry.class}, value = #{length_entry.inspect}" }
      unless length_entry
        raise SyntaxError.new("Stream missing /Length entry")
      end

      # Resolve length (could be direct integer or indirect reference)
      length_value : Int64? = nil
      case length_entry
      when Pdfbox::Cos::Integer
        length_value = length_entry.value.to_i64
      when Pdfbox::Cos::Object
        # Dereference the object
        obj = length_entry.object
        if obj.is_a?(Pdfbox::Cos::Integer)
          length_value = obj.value.to_i64
        else
          raise SyntaxError.new("Length object does not contain an integer")
        end
      else
        raise SyntaxError.new("Length entry must be integer or indirect reference")
      end

      length = length_value || raise SyntaxError.new("Stream missing /Length entry")
      Log.debug { "handle_stream_incremental: resolved length = #{length}" }

      # Skip whitespace (EOL marker) after "stream"
      skip_spaces
      Log.debug { "handle_stream_incremental: after skip_spaces, position=#{position}" }

      # Read stream data as raw bytes
      data = Bytes.new(length)
      source.read(data)
      Log.debug { "handle_stream_incremental: read #{data.size} bytes, first 10: #{data[0, Math.min(10, data.size)].hexstring}" }

      # Create Stream object with data
      stream_obj = Pdfbox::Cos::Stream.new(object.entries, data)

      # Skip "endstream"
      skip_spaces
      begin
        read_expected_string("endstream")
      rescue
        raise SyntaxError.new("Expected 'endstream' after stream data at position #{position}")
      end

      stream_obj
    end

    # Check for endobj incrementally
    private def check_endobj_incremental : Nil
      skip_spaces
      begin
        read_expected_string("endobj")
      rescue
        if @lenient
          Log.warn { "Expected 'endobj' at position #{position}" }
          return
        end
        raise SyntaxError.new("Expected 'endobj' at position #{position}")
      end
    end

    # Locate xref table offset using startxref pointer
    def locate_xref_offset : Int64?
      # puts "DEBUG: locate_xref_offset called" if @lenient
      # Save current position
      original_pos = source.position
      begin
        file_size = source.length
        # puts "DEBUG: file_size=#{file_size}" if @lenient
        read_size = 1024
        start = file_size - read_size
        start = 0_i64 if start < 0
        # puts "DEBUG: reading from offset #{start}" if @lenient
        source.seek(start)
        data = source.read_all
        # puts "DEBUG: read #{data.size} bytes" if @lenient
        # Find "startxref" from end
        # puts "DEBUG: converting bytes to string" if @lenient
        str = String.new(data, "ISO-8859-1")
        # puts "DEBUG: string created, length=#{str.size}" if @lenient
        # puts "DEBUG: searching for 'startxref' in string" if @lenient
        if startxref_idx = str.index("startxref")
          # puts "DEBUG: found 'startxref' at index #{startxref_idx}" if @lenient
          # Return offset of "startxref" keyword (XrefParser expects this)
          return start + startxref_idx
        end
      ensure
        source.seek(original_pos)
      end
      nil
    end

    # Parse page count from xref table (count page objects)
    private def parse_page_count_from_xref(xref : XRef) : Int32
      # Count objects with object number >= 3 that are in-use (page objects)
      page_count = 0
      xref.entries.each do |key, offset|
        if key.number >= 3 && offset > 0
          page_count += 1
        end
      end
      page_count
    end

    # Resolve a COS object, handling indirect references
    # ameba:disable Metrics/CyclomaticComplexity
    private def resolve_object(obj : Cos::Base, xref : XRef) : Cos::Base
      if obj.is_a?(Cos::Object)
        # Handle case where Cos::Object is just a wrapper around already dereferenced object
        if key = obj.key
          obj_num = key.number
          # Debug logging for PageLabels objects
          if [1350_i64, 1352_i64, 1358_i64, 1360_i64].includes?(obj_num)
            Log.debug { "resolve_object: resolving PageLabels object #{obj_num}" }
          end

          if xref_entry = xref[obj_num]
            Log.warn { "resolve_object: obj #{obj_num}, type=#{xref_entry.type}, compressed?=#{xref_entry.compressed?}, offset=#{xref_entry.offset}, generation=#{xref_entry.generation}" }
            if xref_entry.compressed?
              # Object is compressed in an object stream
              # offset is negative object stream number, generation is 0, index is stored in key.stream_index
              parse_object_from_stream(-xref_entry.offset, key, key.stream_index.to_i64, xref)
            else
              parse_indirect_object_at_offset(xref_entry.offset, key)
            end
          else
            if @lenient
              # Try brute-force search for missing object
              bf_offsets = get_brute_force_parser.bf_cos_object_offsets
              if bf_offset = bf_offsets[key]?
                Log.debug { "resolve_object: found missing object #{obj_num} via brute-force at offset #{bf_offset}" }
                # Add to xref table for future reference
                if bf_offset < 0
                  # compressed entry: negative offset indicates object stream number
                  xref[obj_num] = XRefEntry.new(bf_offset, key.generation, :compressed)
                else
                  xref[obj_num] = XRefEntry.new(bf_offset, key.generation, :in_use)
                end
                # Now retry with updated xref entry
                xref_entry = xref[obj_num]
                if xref_entry && xref_entry.compressed?
                  parse_object_from_stream(-xref_entry.offset, key, key.stream_index.to_i64, xref)
                elsif xref_entry
                  parse_indirect_object_at_offset(xref_entry.offset, key)
                else
                  raise SyntaxError.new("Object #{obj_num} not found in xref after adding")
                end
              else
                # Lenient mode: treat missing objects as null, like Apache PDFBox
                obj.object = Cos::Null.instance
                Cos::Null.instance
              end
            else
              raise SyntaxError.new("Object #{obj_num} not found in xref")
            end
          end
        else
          # Object is already dereferenced wrapper, return the underlying object
          dereferenced = obj.object
          return dereferenced if dereferenced
          raise SyntaxError.new("Cos::Object has nil key and nil object")
        end
      else
        obj
      end
    end

    # Parse an object from an object stream (similar to Apache PDFBox parseObjectStreamObject)
    private def parse_object_from_stream(obj_stream_number : Int64, key : Cos::ObjectKey, index_in_stream : Int64, xref : XRef) : Cos::Base
      Log.warn { "parse_object_from_stream: parsing object #{key.number} from stream #{obj_stream_number} at index #{index_in_stream}" }
      start_time = Time.instant

      # Get or create cache for this object stream
      stream_objects = @decompressed_objects[obj_stream_number] ||= Hash(Cos::ObjectKey, Cos::Base).new

      # Check if object is already in cache
      cached_object = stream_objects.delete(key)
      if cached_object
        Log.debug { "parse_object_from_stream: found object #{key.number} in cache" }
        elapsed = Time.instant - start_time
        Log.warn { "parse_object_from_stream: cached object #{key.number} took #{elapsed.total_milliseconds.round(2)}ms" }
        return cached_object
      end

      # Object not in cache, need to parse the object stream
      puts "parse_object_from_stream: looking up object stream #{obj_stream_number} in xref (size #{xref.size})"
      xref.each_entry do |obj_num, entry|
        if obj_num == obj_stream_number
          puts "  found entry: offset #{entry.offset}, generation #{entry.generation}, type #{entry.type}"
        end
      end
      obj_stream_xref_entry = xref[obj_stream_number]
      unless obj_stream_xref_entry
        raise SyntaxError.new("Object stream #{obj_stream_number} not found in xref")
      end
      puts "parse_object_from_stream: obj_stream_xref_entry offset=#{obj_stream_xref_entry.offset}, generation=#{obj_stream_xref_entry.generation}, type=#{obj_stream_xref_entry.type}"

      unless obj_stream_xref_entry.in_use?
        raise SyntaxError.new("Object stream #{obj_stream_number} is not an in-use entry")
      end

      # Parse the object stream
      obj_stream_key = Pdfbox::Cos::ObjectKey.new(obj_stream_number, obj_stream_xref_entry.generation)
      Log.debug { "parse_object_from_stream: calling parse_indirect_object_at_offset with offset #{obj_stream_xref_entry.offset}, key #{obj_stream_key}" }
      obj_stream = parse_indirect_object_at_offset(obj_stream_xref_entry.offset, obj_stream_key)
      Log.debug { "parse_object_from_stream: parse_indirect_object_at_offset returned #{obj_stream.class}" }
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
      elapsed = Time.instant - start_time
      Log.warn { "parse_object_from_stream: parsed object #{key.number} from stream #{obj_stream_number} took #{elapsed.total_milliseconds.round(2)}ms" }
      requested_object
    end

    # Parse object from object stream (similar to Apache PDFBox COSParser.parseObjectStreamObject)
    protected def parse_object_stream_object(objstm_obj_nr : Int64, key : Cos::ObjectKey) : Cos::Base?
      # Get or create cache for this object stream
      stream_objects = @decompressed_objects[objstm_obj_nr] ||= Hash(Cos::ObjectKey, Cos::Base).new

      # Check if object is already in cache
      cached_object = stream_objects.delete(key)
      return cached_object if cached_object

      # Object not in cache, need to parse the object stream
      obj_stream_key = Cos::ObjectKey.new(objstm_obj_nr, 0)
      obj_stream_base = get_object_from_pool(obj_stream_key).object
      return unless obj_stream_base.is_a?(Cos::Stream)

      # Use PDFObjectStreamParser to parse all objects
      pdf_object_stream_parser = PDFObjectStreamParser.new(obj_stream_base, self)
      all_objects = pdf_object_stream_parser.parse_all_objects

      # Find the requested object
      requested_object = all_objects.delete(key)
      # Cache remaining objects
      all_objects.each do |obj_key, obj|
        stream_objects[obj_key] = obj
      end

      requested_object
    end

    # Parse object dynamically using COSParser (similar to Apache PDFBox parseObjectDynamically)
    protected def parse_object_dynamically(key : Cos::ObjectKey, require_existing_not_compressed_obj : Bool) : Cos::Base
      # Create COSParser instance to handle object parsing
      cos_parser = COSParser.new(source, self)
      result = cos_parser.parse_object_dynamically(key, require_existing_not_compressed_obj)
      # parse_object_dynamically should never return nil (returns Cos::Null.instance instead)
      result || Cos::Null.instance
    end

    private def decompress_flate(data : Bytes) : Bytes
      start_time = Time.instant
      Log.debug { "decompress_flate: input first 10 bytes: #{data[0, Math.min(10, data.size)].hexstring}" }
      Log.debug { "decompress_flate: input last 10 bytes: #{data[Math.max(0, data.size - 10), Math.min(10, data.size)].hexstring}" }
      io = ::IO::Memory.new(data)
      begin
        Log.debug { "decompress_flate: trying Deflate" }
        reader = Compress::Deflate::Reader.new(io)
        decompressed = reader.gets_to_end
        reader.close
        result = decompressed.to_slice
        Log.debug { "decompress_flate: Deflate succeeded, decompressed #{result.size} bytes" }
      rescue ex
        Log.debug { "decompress_flate: Deflate failed: #{ex.message}" }
        io.rewind
        begin
          Log.debug { "decompress_flate: trying Zlib" }
          reader = Compress::Zlib::Reader.new(io)
          decompressed = reader.gets_to_end
          reader.close
          result = decompressed.to_slice
          Log.debug { "decompress_flate: Zlib succeeded, decompressed #{result.size} bytes" }
        rescue ex
          Log.debug { "decompress_flate: Zlib failed: #{ex.message}" }
          # Try skipping two bytes (zlib header) and treat as raw deflate
          if data.size >= 2
            io.rewind
            io.skip(2)
            begin
              Log.debug { "decompress_flate: trying Deflate after skipping 2 bytes" }
              reader = Compress::Deflate::Reader.new(io)
              decompressed = reader.gets_to_end
              reader.close
              result = decompressed.to_slice
              Log.debug { "decompress_flate: Deflate after skip succeeded, decompressed #{result.size} bytes" }
            rescue ex
              Log.debug { "decompress_flate: Deflate after skip failed: #{ex.message}" }
              # Use raw data as fallback (maybe already uncompressed)
              result = data
              Log.debug { "decompress_flate: using raw data size #{result.size}" }
            end
          else
            result = data
            Log.debug { "decompress_flate: using raw data size #{result.size}" }
          end
        end
      end
      elapsed = Time.instant - start_time
      Log.warn { "decompress_flate: took #{elapsed.total_milliseconds.round(2)}ms, input #{data.size} -> #{result.size}" }
      result
    end

    # ameba:disable Metrics/CyclomaticComplexity
    protected def decode_stream_data(stream : Pdfbox::Cos::Stream) : Bytes
      start_time = Time.instant
      data = stream.data
      dict = stream
      Log.debug { "decode_stream_data: input size #{data.size}" }
      Log.debug { "decode_stream_data: stream dict keys: #{dict.entries.keys.map(&.value)}" }
      filter_entry = dict[Pdfbox::Cos::Name.new("Filter")]
      Log.debug { "decode_stream_data: filter_entry = #{filter_entry.inspect}" }
      if filter_entry
        if filter_entry.is_a?(Pdfbox::Cos::Name) && filter_entry.value == "FlateDecode"
          data = decompress_flate(data)
          Log.debug { "decode_stream_data: after decompression size #{data.size}" }
          Log.debug { "decode_stream_data: first 20 bytes after decompression: #{data[0, Math.min(20, data.size)].hexstring}" } if data.size > 0
        elsif filter_entry.is_a?(Pdfbox::Cos::Array)
          # TODO: handle multiple filters
          raise SyntaxError.new("Multiple filters not yet supported")
        else
          raise SyntaxError.new("Unsupported filter: #{filter_entry.inspect}")
        end
      else
        Log.debug { "decode_stream_data: no filter" }
      end

      decode_parms_entry = dict[Pdfbox::Cos::Name.new("DecodeParms")]
      Log.debug { "decode_stream_data: decode_parms_entry = #{decode_parms_entry.inspect}" }
      if decode_parms_entry && decode_parms_entry.is_a?(Pdfbox::Cos::Dictionary)
        predictor = decode_parms_entry[Pdfbox::Cos::Name.new("Predictor")]
        columns = decode_parms_entry[Pdfbox::Cos::Name.new("Columns")]
        if predictor && predictor.is_a?(Pdfbox::Cos::Integer) && predictor.value >= 10 &&
           columns && columns.is_a?(Pdfbox::Cos::Integer)
          # PNG prediction
          Log.debug { "decode_stream_data: applying PNG predictor, columns=#{columns.value}, predictor=#{predictor.value}" }
          data = apply_png_predictor(data, columns.value.to_i, predictor.value.to_i)
        end
      end

      elapsed = Time.instant - start_time
      Log.warn { "decode_stream_data: took #{elapsed.total_milliseconds.round(2)}ms, size #{data.size}" }
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
      start_time = Time.instant

      # Try optimized path for common case: UP filter (type 2) which is predictor 12
      if predictor == 12
        # Optimized UP filter implementation
        output = apply_png_predictor_up_fast(input, columns)
        elapsed = Time.instant - start_time
        Log.warn { "apply_png_predictor: optimized UP filter, rows=#{input.size // (columns + 1)}, columns=#{columns}, took #{elapsed.total_milliseconds.round(2)}ms" }
        return output
      end

      # PNG predictor: each row has filter byte (0-4) followed by columns bytes
      row_length = columns + 1
      return input if input.size % row_length != 0
      row_count = input.size // row_length
      Log.warn { "apply_png_predictor: rows=#{row_count}, columns=#{columns}, predictor=#{predictor}" }
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
      elapsed = Time.instant - start_time
      Log.warn { "apply_png_predictor: took #{elapsed.total_milliseconds.round(2)}ms" }
      output
    end

    # Optimized UP filter (type 2) implementation using pointers
    # ameba:disable Metrics/CyclomaticComplexity
    private def apply_png_predictor_up_fast(input : Bytes, columns : Int32) : Bytes
      row_length = columns + 1
      row_count = input.size // row_length
      output = Bytes.new(row_count * columns)

      input_ptr = input.to_unsafe
      output_ptr = output.to_unsafe

      # First row: filter byte should be 2 (UP), but we handle generally
      # Initialize previous_row to zeros
      previous_row = Pointer(UInt8).malloc(columns, 0_u8)

      row_count.times do |row|
        row_start = row * row_length
        filter_type = input_ptr[row_start]

        if filter_type == 2 # UP filter
          # Process UP filter with pointers
          columns.times do |col|
            filtered = input_ptr[row_start + 1 + col]
            up = previous_row[col]
            decoded = filtered &+ up # Use wrapping addition
            output_ptr[row * columns + col] = decoded
            previous_row[col] = decoded
          end
        elsif filter_type == 0 # None filter
          columns.times do |col|
            value = input_ptr[row_start + 1 + col]
            output_ptr[row * columns + col] = value
            previous_row[col] = value
          end
        else
          # Fall back to regular implementation for other filters
          # This shouldn't happen for predictor=12
          row_data = input[row_start + 1, columns]
          case filter_type
          when 1 # Sub
            columns.times do |col|
              left = col > 0 ? output_ptr[row * columns + col - 1] : 0_u8
              decoded = row_data[col] &+ left
              output_ptr[row * columns + col] = decoded
              previous_row[col] = decoded
            end
          when 3 # Average
            columns.times do |col|
              left = col > 0 ? output_ptr[row * columns + col - 1] : 0_u8
              up = previous_row[col]
              decoded = row_data[col] &+ ((left &+ up) // 2)
              output_ptr[row * columns + col] = decoded
              previous_row[col] = decoded
            end
          when 4 # Paeth
            columns.times do |col|
              left = col > 0 ? output_ptr[row * columns + col - 1] : 0_u8
              up = previous_row[col]
              up_left = col > 0 ? previous_row[col - 1] : 0_u8

              p = left.to_i16 &+ up.to_i16 &- up_left.to_i16
              pa_left = (p - left).abs
              pa_up = (p - up).abs
              pa_up_left = (p - up_left).abs

              predictor_val = if pa_left <= pa_up && pa_left <= pa_up_left
                                left
                              elsif pa_up <= pa_up_left
                                up
                              else
                                up_left
                              end

              decoded = row_data[col] &+ predictor_val
              output_ptr[row * columns + col] = decoded
              previous_row[col] = decoded
            end
          else
            raise SyntaxError.new("Unsupported PNG filter type #{filter_type}")
          end
        end
      end

      output
    end

    # Validate object stream dictionary and extract N and First values
    private def validate_object_stream_dict(dict : Cos::Dictionary) : Tuple(Int32, Int32)
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
      if n < 0
        raise SyntaxError.new("Illegal /N entry in object stream: #{n}")
      end
      if n > MAX_OBJECTS_PER_STREAM
        raise SyntaxError.new("Object stream /N too large: #{n} > #{MAX_OBJECTS_PER_STREAM}")
      end

      # Get offset of first object
      first_entry = dict[Cos::Name.new("First")]
      unless first_entry.is_a?(Cos::Integer)
        raise SyntaxError.new("/First entry missing or invalid in object stream")
      end
      first = first_entry.value.to_i
      if first < 0
        raise SyntaxError.new("Illegal /First entry in object stream: #{first}")
      end

      Log.debug { "validate_object_stream_dict: N=#{n}, First=#{first}" }
      {n, first}
    end

    # Read object number/offset pairs from object stream data
    private def read_object_offset_pairs(parser : BaseParser, first : Int32, n : Int32) : Hash(Int32, Int64)
      offset_to_obj_num = Hash(Int32, Int64).new
      first_object_position = parser.position + first - 1
      n.times do |i|
        # Stop if we've consumed first bytes (position is 0-based)
        # Don't read beyond the part of the stream reserved for the object numbers
        if parser.position >= first_object_position
          Log.debug { "read_object_offset_pairs: reached first byte limit at pair #{i}, stopping (position=#{parser.position}, first_object_position=#{first_object_position})" }
          break
        end
        obj_num = parser.read_number.to_i64
        offset = parser.read_number.to_i64.to_i32
        offset_to_obj_num[offset] = obj_num
        Log.debug { "read_object_offset_pairs: obj_num=#{obj_num}, offset=#{offset}" }
      end
      offset_to_obj_num
    end

    # Parse objects from stream data using sorted offsets
    private def parse_objects_from_sorted_offsets(
      memory_io : Pdfbox::IO::MemoryRandomAccessRead,
      offset_to_obj_num : Hash(Int32, Int64),
      sorted_offsets : Array(Int32),
      first : Int32,
      index_needed : Bool,
    ) : Hash(Cos::ObjectKey, Cos::Base)
      start_time = Time.instant
      all_objects = Hash(Cos::ObjectKey, Cos::Base).new
      index = 0
      total_objects = sorted_offsets.size

      sorted_offsets.each do |offset|
        obj_start_time = Time.instant
        obj_num = offset_to_obj_num[offset]
        final_position = first + offset

        # Get current position and seek if needed
        current_position = memory_io.position
        if final_position > 0 && current_position < final_position
          # jump to the offset of the object to be parsed
          memory_io.seek(final_position)
        end

        # Parse the object using incremental parser
        object_parser = COSParser.new(memory_io, self)
        object = object_parser.parse_object
        unless object
          raise SyntaxError.new("Failed to parse object at offset #{final_position}")
        end

        # Create object key with stream index if needed
        stream_index = index_needed ? index : -1
        key = Cos::ObjectKey.new(obj_num, 0, stream_index)
        all_objects[key] = object

        if total_objects > 100 && index % 1000 == 0
          obj_elapsed = Time.instant - obj_start_time
          Log.warn { "parse_objects_from_sorted_offsets: parsed object #{index + 1}/#{total_objects} (#{obj_num}) at offset #{offset} took #{obj_elapsed.total_milliseconds.round(2)}ms" }
        end

        Log.debug { "parse_objects_from_sorted_offsets: parsed object #{obj_num} at offset #{offset}, key=#{key}" }
        index += 1
      end

      elapsed = Time.instant - start_time
      Log.warn { "parse_objects_from_sorted_offsets: parsed #{total_objects} objects took #{elapsed.total_milliseconds.round(2)}ms" }
      all_objects
    end

    # Parse all objects from object stream and return map of object keys to objects
    private def parse_all_objects_from_stream(obj_stream : Cos::Stream) : Hash(Cos::ObjectKey, Cos::Base)
      Log.warn { "parse_all_objects_from_stream: START parsing all objects from stream" }
      Log.debug { "parse_all_objects_from_stream: stream class: #{obj_stream.class}" }
      start_time = Time.instant

      # Use PDFObjectStreamParser for parsing object streams
      begin
        parser = PDFObjectStreamParser.new(obj_stream, self)
        all_objects = parser.parse_all_objects
      rescue ex
        Log.error { "parse_all_objects_from_stream: failed to parse object stream: #{ex.message}" }
        Log.error { ex.backtrace.join("\n") }
        raise ex
      end

      Log.debug { "parse_all_objects_from_stream: successfully parsed #{all_objects.size} objects" }
      elapsed = Time.instant - start_time
      Log.warn { "parse_all_objects_from_stream: parsed #{all_objects.size} objects took #{elapsed.total_milliseconds.round(2)}ms" }
      all_objects
    end

    # Public wrapper for parse_all_objects_from_stream (used by BruteForceParser)
    def parse_object_stream(obj_stream : Cos::Stream) : Hash(Cos::ObjectKey, Cos::Base)
      parse_all_objects_from_stream(obj_stream)
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
      key = obj.key
      unless key
        raise "Object has no key and cannot be dereferenced"
      end

      # Save current position (similar to Apache PDFBox dereferenceCOSObject)
      current_pos = source.position
      result = parse_object_dynamically(key, false)

      if result
        result.set_direct(false)
        result.key = key
      end

      # Restore position
      if current_pos > 0
        source.seek(current_pos)
      end

      result
    end

    # Creates a random access read view starting at the given position with the given length
    def create_random_access_read_view(start_position : Int64, stream_length : Int64) : Pdfbox::IO::RandomAccessRead
      source.create_view(start_position, stream_length)
    end

    private def collect_xref_sections(xref_offset : Int64) : Array(Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?))
      Log.debug { "collect_xref_sections: start with xref_offset=#{xref_offset}" }

      # Use XrefParser to parse the entire xref chain
      xref_parser = XrefParser.new(self)
      trailer = xref_parser.parse_xref(xref_offset)

      if trailer
      end
      xref_table = xref_parser.xref_table
      Log.debug { "collect_xref_sections: xref_table size = #{xref_table.size}" }
      # Debug: list first 10 object numbers
      count = 0
      xref_table.each do |key, offset|
        if count < 10
          Log.debug { "collect_xref_sections: entry #{count}: obj #{key.number}, offset #{offset}, gen #{key.generation}, stream #{key.stream_index}" }
          count += 1
        end
      end
      # Debug: check for object 141
      found = false
      xref_table.each do |key, offset|
        if key.number == 141
          Log.debug { "collect_xref_sections: found object 141 in xref_table: offset #{offset}, generation #{key.generation}, stream_index=#{key.stream_index}" }
          found = true
        end
      end
      unless found
        Log.debug { "collect_xref_sections: object 141 NOT FOUND in xref_table" }
      end
      # Debug: count compressed entries
      compressed_count = 0
      xref_table.each do |key, offset|
        if offset < 0
          compressed_count += 1
          if key.number == 141
            Log.debug { "collect_xref_sections: compressed object 141 found!" }
          end
        end
      end
      Log.debug { "collect_xref_sections: total compressed entries = #{compressed_count}" }

      # Update our xref_resolver with the results from XrefParser
      # startxref already set by XrefParser, do not overwrite
      xref_resolver.startxref = xref_offset
      # Clear existing entries and add all from xref_table
      resolver_table = xref_resolver.xref_table
      if resolver_table
        resolver_table.clear
        resolver_table.merge!(xref_table)
      end
      if trailer
        # Merge trailer entries into resolved trailer
        resolved_trailer = xref_resolver.trailer
        if resolved_trailer
          trailer.entries.each do |key, value|
            resolved_trailer[key] = value
          end
        else
          # Should not happen if startxref= was called
          Log.warn { "Resolved trailer is nil, cannot merge trailer" }
        end
      end

      # Return a single section with merged results for compatibility
      sections = [] of Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?)
      # Convert hash to XRef object
      xref_obj = XRef.new
      xref_obj.update_from_hash(xref_table)
      sections << {xref_offset, xref_obj, trailer}

      Log.debug { "collect_xref_sections: collected 1 section via XrefParser, xref entries: #{xref_table.size}" }
      sections
    end

    private def merge_xref_sections(sections : Array(Tuple(Int64, XRef, Pdfbox::Cos::Dictionary?))) : Tuple(XRef, Pdfbox::Cos::Dictionary?)
      Log.debug { "merge_xref_sections: start with #{sections.size} sections" }

      # If we have only one section (from XrefParser), return it directly
      if sections.size == 1
        _offset_val, xref_section, trailer_section = sections[0]
        Log.debug { "merge_xref_sections: single section from XrefParser, returning directly" }
        return {xref_section, trailer_section}
      end

      # Fallback for multiple sections (should not happen with XrefParser but kept for compatibility)
      xref = XRef.new
      trailer = nil

      # Process sections from OLDEST to NEWEST (reverse of collection order)
      # so newer entries override older ones
      sections.reverse.each do |offset_val, section_xref, section_trailer|
        Log.debug { "merge_xref_sections: applying xref section from offset #{offset_val} (#{section_xref.size} entries)" }
        if section_trailer
          Log.debug { "merge_xref_sections: trailer_section keys: #{section_trailer.entries.keys.map(&.value)}" }
        end

        # Combine traditional xref entries with XRefStm entries for this section
        # Traditional entries take precedence over XRefStm entries within same section
        section_entries = {} of Cos::ObjectKey => Int64

        # Add traditional xref entries
        section_xref.entries.each do |key, offset|
          section_entries[key] = offset
        end

        # Merge trailer dictionaries (newer overrides older)
        if section_trailer
          if trailer
            # Copy entries from trailer_section to trailer only if not already present
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
            Log.debug { "merge_xref_sections: Found XRefStm at offset #{xref_stm_offset}, parsing xref stream" }
            begin
              xref_stream = parse_xref_stream(xref_stm_offset, standalone: false)
              Log.debug { "merge_xref_sections: xref_stream size before merging: #{xref_stream.size}" }

              # Merge xref stream entries with section entries
              # Don't overwrite existing entries (traditional xref takes precedence)
              xref_stream.entries.each do |key, offset|
                section_entries[key] = offset unless section_entries.has_key?(key)
              end
              Log.debug { "merge_xref_sections: Merged #{xref_stream.size} entries from xref stream" }
            rescue ex
              Log.debug { "merge_xref_sections: Failed to parse xref stream at offset #{xref_stm_offset}: #{ex.message}" }
              Log.debug(exception: ex) { "xref stream parsing error" }
            end
          end
        end

        # Merge combined section entries into final xref (newer sections override older ones)
        section_entries.each do |key, offset|
          xref[key] = offset
        end
      end

      {xref, trailer}
    end

    # ameba:disable Metrics/CyclomaticComplexity
    private def parse_catalog_from_trailer(trailer : Pdfbox::Cos::Dictionary?, xref : XRef) : Pdfbox::Cos::Dictionary?
      return unless trailer

      root_ref = trailer[Pdfbox::Cos::Name.new("Root")]

      obj_number = if root_ref.is_a?(Pdfbox::Cos::Object)
                     Log.debug { "root_ref is object, obj_number: #{root_ref.obj_number}" }
                     root_ref.obj_number
                   elsif root_ref.is_a?(Pdfbox::Cos::Integer)
                     Log.debug { "root_ref is integer, treating as object number: #{root_ref.value}" }
                     root_ref.value
                   end

      return unless obj_number

      # Determine generation and get offset
      generation = if root_ref.is_a?(Pdfbox::Cos::Object)
                     root_ref.generation
                   else
                     # Find entry by object number to get generation
                     entry = xref.get_entry_by_number(obj_number)
                     entry ? entry.generation : 0_i64
                   end

      # Get offset using key (for compressed entries, stream_index is stored in xref key)
      key = Cos::ObjectKey.new(obj_number, generation)
      offset = xref[key]?
      matched_key = key

      if offset.nil?
        xref.entries.each do |xref_key, xref_offset|
          if xref_key.number == obj_number && xref_key.generation == generation
            matched_key = xref_key
            offset = xref_offset
            break
          end
        end
      end

      if offset.nil? && @lenient
        bf_offsets = get_brute_force_parser.bf_cos_object_offsets
        if bf_offset = bf_offsets[matched_key]?
          offset = bf_offset
          xref[matched_key] = bf_offset
        else
          bf_offsets.each do |bf_key, bf_found_offset|
            if bf_key.number == obj_number && bf_key.generation == generation
              matched_key = bf_key
              offset = bf_found_offset
              xref[matched_key] = bf_found_offset
              break
            end
          end
        end
      end

      return unless offset

      Log.debug { "xref entry found for object #{obj_number}: offset #{offset}" }
      catalog_obj = if offset > 0
                      parse_indirect_object_at_offset(offset, matched_key)
                    else
                      parse_object_from_stream(-offset, matched_key, matched_key.stream_index.to_i64, xref)
                    end
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

    # Rebuild trailer using brute force when startxref missing or trailer incomplete
    private def rebuild_trailer_with_brute_force : Tuple(XRef, Cos::Dictionary?)?
      Log.warn { "Parser.rebuild_trailer_with_brute_force: START" }
      xref = XRef.new
      @xref = xref
      trailer = get_brute_force_parser.rebuild_trailer(xref)
      if trailer
        Log.warn { "Parser.rebuild_trailer_with_brute_force: SUCCESS, xref entries: #{xref.size}" }
        {xref, trailer}
      else
        Log.error { "Parser.rebuild_trailer_with_brute_force: FAILED" }
        nil
      end
    end

    private def parse_pages_from_catalog(catalog_dict : Pdfbox::Cos::Dictionary, xref : XRef) : Array(Pdfbox::Pdmodel::Page)
      Log.debug { "PARSER: parse_pages_from_catalog start" }
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
    # ameba:disable Metrics/CyclomaticComplexity
    def parse : Pdfbox::Pdmodel::Document
      Log.debug { "PARSER: START parsing PDF document" }
      # puts "DEBUG: Parser.parse started (lenient=#{@lenient})" if @lenient
      version = parse_header
      pages = [] of Pdfbox::Pdmodel::Page

      xref_offset = locate_xref_offset
      Log.debug { "xref_offset: #{xref_offset}" }

      catalog_dict = if xref_offset
                       Log.debug { "Before collect_xref_sections, xref_offset=#{xref_offset}" }
                       sections = collect_xref_sections(xref_offset)

                       # Try to use resolver's results first
                       resolver_xref_table = xref_resolver.xref_table
                       resolver_trailer = xref_resolver.trailer
                       Log.debug { "resolver_xref_table size: #{resolver_xref_table.try(&.size) || 0}, resolver_trailer keys: #{resolver_trailer.try(&.entries).try(&.keys).try(&.map(&.value)) || [] of String}" }

                       if resolver_xref_table && resolver_trailer && resolver_trailer.has_key?(Pdfbox::Cos::Name.new("Root"))
                         xref = XRef.new
                         xref.update_from_hash(resolver_xref_table)
                         trailer = resolver_trailer

                         Log.debug { "Using resolver xref table with #{xref.size} entries" }
                         # Debug: check for object 141
                         if resolver_xref_table
                           resolver_xref_table.each do |key, offset|
                             if key.number == 141
                               Log.debug { "Found object 141 in resolver xref table: offset #{offset}, generation #{key.generation}" }
                             end
                           end
                         end
                       else
                         xref, trailer = merge_xref_sections(sections)

                         Log.debug { "Using merged xref sections with #{xref.size} entries" }
                       end

                       @trailer = trailer
                       @xref = xref

                       # Brute-force search for object streams in lenient mode
                       if @lenient
                         Log.warn { "Parser lenient mode enabled, performing brute-force search for object streams" }
                         get_brute_force_parser.bf_search_for_obj_streams_xref(xref)
                         Log.warn { "After brute-force search, xref entries: #{xref.size}" }

                         # If trailer missing Root, try brute force to find it
                         if trailer.nil? || !trailer.has_key?(Pdfbox::Cos::Name.new("Root"))
                           Log.warn { "Trailer missing Root, attempting brute-force trailer search" }
                           if get_brute_force_parser.bf_find_trailer(trailer ||= Pdfbox::Cos::Dictionary.new)
                             Log.warn { "Brute-force trailer search succeeded" }
                             @trailer = trailer
                           else
                             Log.warn { "Brute-force trailer search failed" }
                           end
                         end
                       end

                       # Debug logging for compressed entries
                       Log.debug { "final xref entries: #{xref.size}" }
                       compressed_count = xref.entries.count { |_, offset| offset < 0 }
                       Log.debug { "compressed xref entries (count: #{compressed_count}):" }
                       xref.each_entry do |obj_num, entry|
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
                     else
                       # No startxref found, use brute force to rebuild trailer
                       Log.warn { "No startxref found, attempting brute-force trailer reconstruction" }
                       xref = XRef.new
                       @xref = xref
                       trailer = get_brute_force_parser.rebuild_trailer(xref)
                       if trailer
                         @trailer = trailer
                         found_catalog_dict = parse_catalog_from_trailer(trailer, xref)
                         if found_catalog_dict
                           pages = parse_pages_from_catalog(found_catalog_dict, xref)
                         end
                         found_catalog_dict
                       else
                         Log.error { "Failed to reconstruct trailer using brute force" }
                         nil
                       end
                     end

      Log.debug { "catalog_dict = #{catalog_dict.inspect}" }
      doc = Pdfbox::Pdmodel::Document.new(catalog_dict, version)

      # Add parsed pages to document
      pages.each do |page|
        doc.add_page(page)
      end
      @initial_parse_done = true
      doc
    end

    private def parse_trailer : Pdfbox::Cos::Dictionary?
      # Save current position
      start_pos = source.position
      Log.debug { "parse_trailer: starting at position #{start_pos}" }
      # puts "DEBUG: parse_trailer start_pos=#{start_pos}" if @lenient

      # Skip whitespace/comments
      # puts "DEBUG: parse_trailer skipping whitespace/comments" if @lenient
      loop do
        byte = source.peek
        # puts "DEBUG: parse_trailer peek byte=#{byte}, pos=#{source.position}" if @lenient && source.position % 100 == 0
        break unless byte
        ch = byte.chr
        if ch == '%'
          # puts "DEBUG: parse_trailer found comment at pos #{source.position}" if @lenient
          # Comment, skip to end of line
          while byte = source.read
            break if byte.chr == '\n'
          end
        elsif ch.ascii_whitespace?
          source.read # skip whitespace
        else
          # puts "DEBUG: parse_trailer non-whitespace char '#{ch}' at pos #{source.position}, breaking" if @lenient
          break
        end
      end
      # puts "DEBUG: parse_trailer after whitespace loop, pos=#{source.position}" if @lenient

      # Check for "trailer" keyword
      # Read next 7 bytes to check
      source.seek(start_pos) # reset to start
      line = read_line
      Log.debug { "parse_trailer: first line: #{line.inspect}" }

      # Try to find "trailer" in line
      if line.includes?("trailer")
        # Position after "trailer"
        trailer_index = line.index("trailer")
        if trailer_index
          # Skip to after "trailer"
          source.seek(start_pos + trailer_index + "trailer".size)
          # Skip whitespace
          while byte = source.peek
            break unless byte.chr.ascii_whitespace?
            source.read
          end
          # Now parse dictionary
          object_parser = COSParser.new(source, self)
          dict = object_parser.parse_dictionary
          Log.debug { "parse_trailer: parsed dictionary: #{dict.inspect}" }
          # Set trailer in resolver
          xref_resolver.current_trailer = dict
          return dict
        end
      end

      Log.debug { "parse_trailer: 'trailer' not found in line" }
      source.seek(start_pos) # restore position
      nil
    end

    private def parse_simple_page_count : Int32
      # Save current position
      original_pos = source.position
      begin
        page_count = 0
        while !source.eof?
          line = read_line
          break if line == "%%EOF"

          if line.starts_with?("% Pages: ")
            page_count = line[9..].to_i? || 0
          end
        end
        page_count
      ensure
        source.seek(original_pos)
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
