require "log"
require "../cos"
require "../io"
require "./pdf_scanner"
require "./object_parser"
require "./xref"

module Pdfbox::Pdfparser
  # Brute force parser to be used as last resort if a malformed pdf can't be read.
  # Corresponds to BruteForceParser in Apache PDFBox.
  class BruteForceParser
    Log = ::Log.for(self)

    private XREF_TABLE              = "xref".chars
    private XREF_STREAM             = "/XRef".chars
    private MINIMUM_SEARCH_OFFSET   = 6_i64
    private EOF_MARKER              = "%%EOF".chars
    private OBJ_MARKER              = "obj".chars
    private TRAILER_MARKER          = "trailer".chars
    private OBJ_STREAM              = "/ObjStm".chars
    private ENDOBJ_STRING           = "ndo".chars
    private ENDOBJ_REMAINING_STRING = "bj".chars

    # Contains all found objects of a brute force search.
    @bf_search_cos_object_key_offsets = {} of Cos::ObjectKey => Int64

    @bf_search_triggered = false
    @parser : Parser
    @source : Pdfbox::IO::RandomAccessRead
    @scanner : PDFScanner? = nil

    # Constructor. Triggers a brute force search for all objects of the document.
    def initialize(@parser : Parser)
      @source = parser.source
    end

    # Get a reusable PDFScanner, seeking to the given position if provided
    private def get_scanner(position : Int64? = nil, max_bytes : Int64? = nil) : PDFScanner
      scanner = @scanner
      if scanner.nil?
        scanner = PDFScanner.new(@source, max_bytes)
        @scanner = scanner
      elsif position
        scanner.position = position
      end
      scanner
    end

    # Indicates whether the brute force search for objects was triggered.
    def bf_search_triggered? : Bool
      @bf_search_triggered
    end

    # Returns all found objects of a brute force search.
    def bf_cos_object_offsets : Hash(Cos::ObjectKey, Int64)
      unless @bf_search_triggered
        @bf_search_triggered = true
        bf_search_for_objects
      end
      @bf_search_cos_object_key_offsets
    end

    # Brute force search for every object in the pdf.
    # ameba:disable Metrics/CyclomaticComplexity
    private def bf_search_for_objects : Nil
      Log.warn { "BruteForceParser.bf_search_for_objects: START" }
      last_eof_marker = bf_search_for_last_eof_marker
      origin_offset = @source.position

      # Read the search range into memory for faster scanning
      start_offset = MINIMUM_SEARCH_OFFSET
      range_size = last_eof_marker - start_offset
      if range_size <= 0
        @source.seek(origin_offset)
        Log.warn { "BruteForceParser.bf_search_for_objects: empty range" }
        return
      end

      @source.seek(start_offset)
      data = @source.read_all
      @source.seek(origin_offset)

      # Create memory-based RandomAccessRead for the range
      memory_source = Pdfbox::IO::MemoryRandomAccessRead.new(data)
      original_source = @source

      iteration_count = 0
      max_iterations = 3_000_000 # safety limit for ~3MB file

      begin
        @scanner = nil
        @source = memory_source
        # Run original scanning algorithm on memory source
        # Offsets in memory source are 0-based, we'll add start_offset when storing

        current_offset = 0_i64 # MINIMUM_SEARCH_OFFSET relative to memory source
        last_object_id = Int64::MIN
        last_gen_id = Int64::MIN
        last_obj_offset = Int64::MIN
        end_of_obj_found = false

        begin
          while current_offset < range_size && !@source.eof? && iteration_count < max_iterations
            iteration_count += 1
            if iteration_count % 100_000 == 0
              Log.warn { "BruteForceParser.bf_search_for_objects: iteration #{iteration_count}, offset #{current_offset}" }
            end
            @source.seek(current_offset)
            next_char = @source.read
            current_offset += 1
            break if next_char.nil?

            ch = next_char.chr
            if whitespace?(ch) && string?(OBJ_MARKER)
              if result = handle_object_marker(current_offset, last_object_id, last_gen_id, last_obj_offset)
                new_current_offset, object_id, gen_id, obj_offset = result
                last_object_id = object_id
                last_gen_id = gen_id
                # Convert memory offset back to file offset
                last_obj_offset = obj_offset + start_offset
                current_offset = new_current_offset
                end_of_obj_found = false
              end
            elsif ch == 'e' && string?(ENDOBJ_STRING)
              new_current_offset, found = parse_endobj_marker(current_offset)
              current_offset = new_current_offset
              end_of_obj_found = found
            end
          end
        rescue ex
          Log.debug(exception: ex) { "Exception during brute force search for objects" }
        end

        if iteration_count >= max_iterations
          Log.warn { "BruteForceParser.bf_search_for_objects: hit iteration limit #{max_iterations}" }
        end

        if (last_eof_marker < Int64::MAX || end_of_obj_found) && last_obj_offset > 0
          # if the pdf wasn't cut off in the middle or if the last object ends with a "endobj" marker
          # the last object id has to be added here so that it can't get lost as there isn't any subsequent object id
          @bf_search_cos_object_key_offsets[Cos::ObjectKey.new(last_object_id, last_gen_id)] = last_obj_offset
        end
      ensure
        @scanner = nil
        @source = original_source
      end

      Log.warn { "BruteForceParser.bf_search_for_objects: END, found #{@bf_search_cos_object_key_offsets.size} objects, iterations: #{iteration_count}" }
    end

    # Helper methods from BaseParser/PDFScanner
    private def whitespace?(ch : Char) : Bool
      ch.ascii_whitespace?
    end

    private def digit?(ch : Char) : Bool
      ch.ascii_number?
    end

    private def min_search_offset : Int64
      # When using memory source (brute force search in memory), we can search from offset 0
      @source.is_a?(Pdfbox::IO::MemoryRandomAccessRead) ? 0_i64 : MINIMUM_SEARCH_OFFSET
    end

    private def string?(chars : Array(Char)) : Bool
      saved_pos = @source.position
      # Read all needed bytes at once
      bytes = Bytes.new(chars.size)
      bytes_read = @source.read(bytes)
      @source.seek(saved_pos)

      return false unless bytes_read == chars.size

      chars.each_with_index do |char, i|
        return false unless bytes[i] == char.ord
      end
      true
    end

    private def read_object_number(start_offset : Int64) : Int64
      scanner = get_scanner(position: start_offset)
      scanner.read_number.to_i64
    end

    # Attempt to parse object ID and generation number at given offset.
    # Returns tuple (object_id, gen_id, obj_offset) if successful, nil otherwise.
    private def try_parse_object_id_and_gen(temp_offset : Int64) : Tuple(Int64, Int64, Int64)?
      @source.seek(temp_offset)
      gen_id_byte = @source.peek
      return unless gen_id_byte && digit?(gen_id_byte.chr)

      gen_id = gen_id_byte.chr.to_i
      temp_offset -= 1
      @source.seek(temp_offset)
      peek_byte = @source.peek
      return unless peek_byte && whitespace?(peek_byte.chr)

      # skip whitespace backwards
      while temp_offset > min_search_offset
        peek_byte = @source.peek
        break unless peek_byte && whitespace?(peek_byte.chr)
        @source.seek(temp_offset -= 1)
      end

      object_id_found = false
      while temp_offset > min_search_offset
        peek_byte = @source.peek
        break unless peek_byte && digit?(peek_byte.chr)
        @source.seek(temp_offset -= 1)
        object_id_found = true
      end

      return unless object_id_found

      @source.read # consume digit
      object_id = read_object_number(temp_offset + 1)
      {object_id, gen_id.to_i64, temp_offset + 1}
    end

    # Process object marker at current_offset (position after whitespace char).
    # Returns tuple (object_id, gen_id, obj_offset, new_current_offset) if successful, nil otherwise.
    private def parse_object_marker(current_offset : Int64) : Tuple(Int64, Int64, Int64, Int64)?
      temp_offset = current_offset - 2
      if parsed = try_parse_object_id_and_gen(temp_offset)
        object_id, gen_id, obj_offset = parsed
        new_current_offset = current_offset + OBJ_MARKER.size - 1
        {object_id, gen_id, obj_offset, new_current_offset}
      end
    end

    # Process endobj marker at current_offset (position after 'e' char).
    # Returns tuple (new_current_offset, end_of_obj_found).
    private def parse_endobj_marker(current_offset : Int64) : Tuple(Int64, Bool)
      current_offset += ENDOBJ_STRING.size
      @source.seek(current_offset)
      if @source.eof?
        {current_offset, true}
      elsif string?(ENDOBJ_REMAINING_STRING)
        current_offset += ENDOBJ_REMAINING_STRING.size
        {current_offset, true}
      else
        {current_offset, false}
      end
    end

    # Handle object marker at current_offset.
    # Returns tuple (new_current_offset, object_id, gen_id, obj_offset) if successful, nil otherwise.
    # Also updates @bf_search_cos_object_key_offsets with previous object if applicable.
    private def handle_object_marker(current_offset : Int64, last_object_id : Int64, last_gen_id : Int64, last_obj_offset : Int64) : Tuple(Int64, Int64, Int64, Int64)?
      if parsed = parse_object_marker(current_offset)
        object_id, gen_id, obj_offset, new_current_offset = parsed
        if last_obj_offset > 0
          @bf_search_cos_object_key_offsets[Cos::ObjectKey.new(last_object_id, last_gen_id)] = last_obj_offset
        end
        {new_current_offset, object_id, gen_id, obj_offset}
      end
    end

    # Search for the offset of the given xref table/stream among those found by a brute force search.
    def bf_search_for_xref(xref_offset : Int64) : Int64
      new_offset = -1_i64

      # initialize bf_search_xref_tables_offsets -> not null
      bf_search_xref_tables_offsets = bf_search_for_xref_tables
      # initialize bf_search_xref_streams_offsets -> not null
      bf_search_xref_streams_offsets = bf_search_for_xref_streams

      # TODO to be optimized, this won't work in every case
      new_offset_table = search_nearest_value(bf_search_xref_tables_offsets, xref_offset)

      # TODO to be optimized, this won't work in every case
      new_offset_stream = search_nearest_value(bf_search_xref_streams_offsets, xref_offset)

      # choose the nearest value
      if new_offset_table > -1 && new_offset_stream > -1
        difference_table = xref_offset - new_offset_table
        difference_stream = xref_offset - new_offset_stream
        if difference_table.abs > difference_stream.abs
          new_offset = new_offset_stream
          bf_search_xref_streams_offsets.delete(new_offset_stream)
        else
          new_offset = new_offset_table
          bf_search_xref_tables_offsets.delete(new_offset_table)
        end
      elsif new_offset_table > -1
        new_offset = new_offset_table
        bf_search_xref_tables_offsets.delete(new_offset_table)
      elsif new_offset_stream > -1
        new_offset = new_offset_stream
        bf_search_xref_streams_offsets.delete(new_offset_stream)
      end
      new_offset
    end

    private def search_nearest_value(values : Array(Int64), offset : Int64) : Int64
      new_value = -1_i64
      current_difference = nil
      current_offset_index = -1
      values.each_with_index do |value, i|
        new_difference = offset - value
        # find the nearest offset
        if current_difference.nil? || (current_difference.abs > new_difference.abs)
          current_difference = new_difference
          current_offset_index = i
        end
      end
      if current_offset_index > -1
        new_value = values[current_offset_index]
      end
      new_value
    end

    # Search backwards from start_offset for " obj" pattern and return object start offset if found.
    # Returns -1 if not found.
    private def find_object_start_offset(start_offset : Int64) : Int64
      obj_string = " obj".chars
      (1..40).each do |i|
        current_offset = start_offset - (i * 10)
        next unless current_offset > 0

        @source.seek(current_offset)
        10.times do
          if string?(obj_string)
            temp_offset = current_offset - 1
            @source.seek(temp_offset)
            peek_byte = @source.peek
            return -1 unless peek_byte && digit?(peek_byte.chr)

            temp_offset -= 1
            @source.seek(temp_offset)
            peek_byte2 = @source.peek
            return -1 unless peek_byte2 && whitespace?(peek_byte2.chr)

            length = 0
            @source.seek(temp_offset -= 1)
            while temp_offset > MINIMUM_SEARCH_OFFSET
              peek_byte3 = @source.peek
              break unless peek_byte3 && digit?(peek_byte3.chr)
              @source.seek(temp_offset -= 1)
              length += 1
            end
            return current_offset if length > 0
          else
            current_offset += 1
            @source.read
          end
        end
      end
      -1
    end

    # Parse object key at given offset (where " obj" pattern starts).
    # Returns Cos::ObjectKey or nil if parsing fails.
    private def parse_object_key_at_offset(offset : Int64) : Cos::ObjectKey?
      temp_offset = offset - 1
      @source.seek(temp_offset)
      peek_byte = @source.peek
      return unless peek_byte && digit?(peek_byte.chr)

      temp_offset -= 1
      @source.seek(temp_offset)
      peek_byte2 = @source.peek
      return unless peek_byte2 && whitespace?(peek_byte2.chr)

      length = 0
      @source.seek(temp_offset -= 1)
      while temp_offset > MINIMUM_SEARCH_OFFSET
        peek_byte3 = @source.peek
        break unless peek_byte3 && digit?(peek_byte3.chr)
        @source.seek(temp_offset -= 1)
        length += 1
      end
      return unless length > 0

      @source.read # consume digit
      obj_number = read_object_number(@source.position)
      gen_number = read_generation_number(@source.position + obj_number.to_s.size + 1) # approximation
      Cos::ObjectKey.new(obj_number, gen_number)
    end

    # Brute force search for all objects streams of a pdf.
    private def bf_search_for_obj_stream_offsets : Hash(Int64, Cos::ObjectKey)
      start_time = Time.instant
      bf_search_obj_streams_offsets = {} of Int64 => Cos::ObjectKey

      # Load the entire file (from MINIMUM_SEARCH_OFFSET to end) into memory for faster scanning
      origin_offset = @source.position
      file_size = @source.length
      start_offset = MINIMUM_SEARCH_OFFSET
      range_size = file_size - start_offset

      if range_size <= 0
        @source.seek(origin_offset)
        Log.debug { "bf_search_for_obj_stream_offsets: empty range" }
        return bf_search_obj_streams_offsets
      end

      @source.seek(start_offset)
      data = @source.read_all
      @source.seek(origin_offset)

      Log.debug { "bf_search_for_obj_stream_offsets: loaded #{data.size} bytes into memory" }

      # Convert patterns to bytes
      pattern_bytes = OBJ_STREAM.map(&.ord.to_u8)
      pattern_size = pattern_bytes.size
      data_size = data.size

      # Helper functions for byte classification
      is_digit = ->(b : UInt8) { b >= 0x30 && b <= 0x39 }
      is_whitespace = ->(b : UInt8) { b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x00 }

      # " obj" pattern in bytes (space + 'o' + 'b' + 'j')
      obj_pattern = [0x20_u8, 0x6F_u8, 0x62_u8, 0x6A_u8]
      obj_pattern_size = obj_pattern.size

      # Use pointers for fast scanning
      data_ptr = data.to_unsafe
      pattern_ptr = pattern_bytes.to_unsafe

      i = 0
      max_i = data_size - pattern_size
      positions_found = 0

      # For statistics
      total_matches = 0

      while i <= max_i
        # Fast first character check
        if data_ptr[i] == pattern_ptr[0] # '/'
          # Compare remaining bytes
          j = 1
          while j < pattern_size && data_ptr[i + j] == pattern_ptr[j]
            j += 1
          end

          if j == pattern_size
            total_matches += 1

            # Found "/ObjStm" at memory offset i (relative to start_offset)
            # Search backward up to 400 bytes for " obj" pattern
            search_back_start = i - 1
            search_back_limit = Math.max(0, i - 400)
            obj_found = false
            back_pos = search_back_start

            while back_pos >= search_back_limit && !obj_found
              # Check for " obj" pattern at back_pos (back_pos is end of "obj")
              if back_pos >= obj_pattern_size - 1
                pattern_match = true
                (0...obj_pattern_size).each do |k|
                  if data_ptr[back_pos - (obj_pattern_size - 1) + k] != obj_pattern[k]
                    pattern_match = false
                    break
                  end
                end

                if pattern_match
                  # Found " obj" at position: start = back_pos - (obj_pattern_size - 1)
                  obj_start = back_pos - (obj_pattern_size - 1)

                  # Check character before " obj" is digit (generation number)
                  if obj_start > 0 && is_digit.call(data_ptr[obj_start - 1])
                    # Check character before digit is whitespace
                    if obj_start > 1 && is_whitespace.call(data_ptr[obj_start - 2])
                      # Parse generation number (digits before " obj")
                      gen_end = obj_start - 1 # last digit of generation
                      gen_start = gen_end
                      while gen_start > 0 && is_digit.call(data_ptr[gen_start - 1])
                        gen_start -= 1
                      end

                      # Parse generation number
                      gen_number = 0_i64
                      (gen_start..gen_end).each do |pos|
                        gen_number = gen_number * 10 + (data_ptr[pos] - 0x30).to_i64
                      end

                      # Parse object number (digits before whitespace that's before generation)
                      # The whitespace at obj_start - 2 separates object number from generation
                      obj_num_end = obj_start - 3 # last digit of object number (before whitespace)
                      next if obj_num_end < 0     # Not enough space for object number

                      obj_num_start = obj_num_end
                      while obj_num_start > 0 && is_digit.call(data_ptr[obj_num_start - 1])
                        obj_num_start -= 1
                      end

                      # Parse object number
                      obj_number = 0_i64
                      (obj_num_start..obj_num_end).each do |pos|
                        obj_number = obj_number * 10 + (data_ptr[pos] - 0x30).to_i64
                      end

                      # Calculate file offset for object start
                      file_offset = start_offset + obj_num_start
                      stream_object_key = Cos::ObjectKey.new(obj_number, gen_number)
                      bf_search_obj_streams_offsets[file_offset] = stream_object_key
                      Log.debug { "Dictionary start for object stream -> #{file_offset}, key #{stream_object_key}" }
                      positions_found += 1
                      obj_found = true

                      # Skip over this pattern for next search
                      i += pattern_size
                      next
                    end
                  end
                end
              end
              back_pos -= 1
            end
          end
        end
        i += 1
      end

      elapsed = Time.instant - start_time
      Log.warn { "bf_search_for_obj_stream_offsets: scanned #{data_size} bytes, found #{total_matches} pattern matches, parsed #{positions_found} streams in #{elapsed.total_milliseconds.round(2)}ms" }
      bf_search_obj_streams_offsets
    end

    private def bf_search_for_obj_streams(xref_table : Hash(Cos::ObjectKey, Int64)) : Nil
      origin_offset = @source.position
      offsets_map = bf_search_for_obj_stream_offsets
      object_offsets = bf_cos_object_offsets
      Log.warn { "bf_search_for_obj_streams: offsets_map size=#{offsets_map.size}, object_offsets size=#{object_offsets.size}" }
      original_xref_size = xref_table.size

      # collect all stream offsets where the stream object itself was found
      obj_stream_offsets = [] of Tuple(Int64, Cos::ObjectKey)
      offsets_map.each do |offset, key|
        obj_stream_offsets << {offset, key}
      end
      Log.warn { "bf_search_for_obj_streams: valid object streams count: #{obj_stream_offsets.size}" }

      # add all found compressed objects to the brute force search result
      obj_stream_offsets.each_with_index do |(offset, key), i|
        Log.warn { "bf_search_for_obj_streams: processing stream #{i + 1}/#{obj_stream_offsets.size} at offset #{offset}, key #{key}" }
        begin
          # Parse the object stream at offset
          stream = parse_object_stream_at_offset(offset)
          # Log.debug { "bf_search_for_obj_streams: parsed stream, object count: #{stream["N"]?}" }
          # stream is a Cos::Stream
          # Get object numbers from stream
          objects = @parser.parse_object_stream(stream)
          Log.warn { "bf_search_for_obj_streams: extracted #{objects.size} objects from stream" }
          stm_obj_number = key.number
          # For each object found in stream, add compressed entry
          objects.each do |obj_key, _|
            # obj_key has object number and generation (should be 0 for compressed objects)
            # Add to bf_cos_object_offsets with negative offset (compressed indicator)
            # In PDFBox, compressed objects are stored with negative offset = -stm_obj_number
            object_offsets[obj_key] = -stm_obj_number
            # Also add to xref_table (passed parameter)
            xref_table[obj_key] = -stm_obj_number
          end
        rescue ex
          Log.warn { "Skipped corrupt stream at offset #{offset}: #{ex.message}" }
        end
      end
      Log.warn { "bf_search_for_obj_streams: END, added #{xref_table.size - original_xref_size} compressed entries" }
      # restore origin offset
      @source.seek(origin_offset)
    end

    private def parse_object_stream_at_offset(offset : Int64) : Cos::Stream
      # Use parser to parse indirect object at offset
      obj = @parser.parse_indirect_object_at_offset(offset)
      unless obj.is_a?(Cos::Stream)
        raise "Object at offset #{offset} is not a stream"
      end
      obj
    end

    # Brute force search for object streams updating XRef directly
    def bf_search_for_obj_streams_xref(xref : XRef) : Nil
      Log.warn { "BruteForceParser.bf_search_for_obj_streams_xref: START" }
      # Convert xref to hash, call existing method, then update back
      hash = xref.to_hash
      bf_search_for_obj_streams(hash)
      xref.update_from_hash(hash)
      Log.warn { "BruteForceParser.bf_search_for_obj_streams_xref: END" }
    end

    private def read_generation_number(offset : Int64) : Int64
      scanner = get_scanner(position: offset)
      scanner.read_number.to_i64
    end

    # Brute force search for the last EOF marker.
    private def bf_search_for_last_eof_marker : Int64
      last_eof_marker = -1_i64
      origin_offset = @source.position
      @source.seek(MINIMUM_SEARCH_OFFSET)
      temp_marker = find_string(EOF_MARKER)
      while temp_marker != -1
        begin
          # check if the following data is some valid pdf content
          # which most likely indicates that the pdf is linearized,
          # updated or just cut off somewhere in the middle
          skip_spaces
          unless string?(XREF_TABLE)
            read_object_number(@source.position)
            read_generation_number(@source.position)
          end
        rescue ex
          # save the EOF marker as the following data is most likely some garbage
          Log.debug(exception: ex) { "An exception occurred during brute force for last EOF - ignoring" }
          last_eof_marker = temp_marker
        end
        temp_marker = find_string(EOF_MARKER)
      end
      @source.seek(origin_offset)
      # no EOF marker found
      if last_eof_marker == -1
        last_eof_marker = Int64::MAX
      end
      last_eof_marker
    end

    private def skip_spaces : Nil
      while byte = @source.peek
        break unless byte.chr.ascii_whitespace?
        @source.read
      end
    end

    # Find object stream start offset and key for a given OBJ_STREAM marker position.
    # Returns tuple (offset, key) or nil if not found.
    private def find_object_stream_start(position_obj_stream : Int64) : Tuple(Int64, Cos::ObjectKey)?
      obj_string = " obj".chars
      (1..40).each do |i|
        current_offset = position_obj_stream - (i * 10)
        next unless current_offset > 0

        @source.seek(current_offset)
        10.times do
          if string?(obj_string)
            temp_offset = current_offset - 1
            @source.seek(temp_offset)
            peek_byte = @source.peek
            next unless peek_byte && digit?(peek_byte.chr)

            temp_offset -= 1
            @source.seek(temp_offset)
            peek_byte2 = @source.peek
            next unless peek_byte2 && whitespace?(peek_byte2.chr)

            length = 0
            @source.seek(temp_offset -= 1)
            while temp_offset > MINIMUM_SEARCH_OFFSET
              peek_byte3 = @source.peek
              break unless peek_byte3 && digit?(peek_byte3.chr)
              @source.seek(temp_offset -= 1)
              length += 1
            end
            if length > 0
              @source.read # consume digit
              new_offset = @source.position
              obj_number = read_object_number(new_offset)
              gen_number = read_generation_number(new_offset + obj_number.to_s.size + 1) # approximation
              stream_object_key = Cos::ObjectKey.new(obj_number, gen_number)
              return {new_offset, stream_object_key}
            end
          else
            current_offset += 1
            @source.read
          end
        end
      end
      nil
    end

    # Brute force search for all xref entries (tables).
    private def bf_search_for_xref_tables : Array(Int64)
      bf_search_xref_tables_offsets = [] of Int64
      # a pdf may contain more than one xref entry
      @source.seek(MINIMUM_SEARCH_OFFSET)
      # search for xref tables
      new_offset = find_string(XREF_TABLE)
      while new_offset != -1
        @source.seek(new_offset - 1)
        # ensure that we don't read "startxref" instead of "xref"
        peek_byte = @source.peek
        if peek_byte && whitespace?(peek_byte.chr)
          bf_search_xref_tables_offsets << new_offset
        end
        @source.seek(new_offset + 4)
        new_offset = find_string(XREF_TABLE)
      end
      bf_search_xref_tables_offsets
    end

    # Find xref stream start offset for a given XREF_STREAM marker position.
    # Returns offset or -1 if not found.
    private def find_xref_stream_start(position_xref_stream : Int64) : Int64
      obj_string = " obj".chars
      (1..40).each do |i|
        current_offset = position_xref_stream - (i * 10)
        next unless current_offset > 0

        @source.seek(current_offset)
        10.times do
          if string?(obj_string)
            temp_offset = current_offset - 1
            @source.seek(temp_offset)
            peek_byte = @source.peek
            next unless peek_byte && digit?(peek_byte.chr)

            temp_offset -= 1
            @source.seek(temp_offset)
            peek_byte2 = @source.peek
            next unless peek_byte2 && whitespace?(peek_byte2.chr)

            length = 0
            @source.seek(temp_offset -= 1)
            while temp_offset > MINIMUM_SEARCH_OFFSET
              peek_byte3 = @source.peek
              break unless peek_byte3 && digit?(peek_byte3.chr)
              @source.seek(temp_offset -= 1)
              length += 1
            end
            if length > 0
              @source.read # consume digit
              return @source.position
            end
          else
            current_offset += 1
            @source.read
          end
        end
      end
      -1
    end

    # Brute force search for all /XRef entries (streams).
    private def bf_search_for_xref_streams : Array(Int64)
      bf_search_xref_streams_offsets = [] of Int64
      @source.seek(MINIMUM_SEARCH_OFFSET)
      xref_offset = find_string(XREF_STREAM)
      while xref_offset != -1
        new_offset = find_xref_stream_start(xref_offset)
        if new_offset > -1
          bf_search_xref_streams_offsets << new_offset
          Log.debug { "Fixed reference for xref stream #{xref_offset} -> #{new_offset}" }
        end
        @source.seek(xref_offset + 5)
        xref_offset = find_string(XREF_STREAM)
      end
      bf_search_xref_streams_offsets
    end

    # Search for the given string. The search starts at the current position and returns the start position if the
    # string was found. -1 is returned if there isn't any further occurrence of the given string. After returning the
    # current position is either the end of the string or the end of the input.
    private def find_string(chars : Array(Char)) : Int64
      position = -1_i64
      string_length = chars.size
      counter = 0
      while byte = @source.read
        read_char = byte.chr
        if read_char == chars[counter]
          if counter == 0
            position = @source.position - 1
          end
          counter += 1
          if counter == string_length
            return position
          end
        elsif counter > 0
          counter = 0
          position = -1_i64
          next
        end
      end
      position
    end

    # Check if dictionary is an info dictionary
    private def info?(dictionary : Cos::Dictionary) : Bool
      # These keys indicate it's NOT an info dictionary
      if dictionary.has_key?(Cos::Name.new("Parent")) ||
         dictionary.has_key?(Cos::Name.new("A")) ||
         dictionary.has_key?(Cos::Name.new("Dest"))
        return false
      end

      # These keys indicate it IS an info dictionary
      dictionary.has_key?(Cos::Name.new("ModDate")) ||
        dictionary.has_key?(Cos::Name.new("Title")) ||
        dictionary.has_key?(Cos::Name.new("Author")) ||
        dictionary.has_key?(Cos::Name.new("Subject")) ||
        dictionary.has_key?(Cos::Name.new("Keywords")) ||
        dictionary.has_key?(Cos::Name.new("Creator")) ||
        dictionary.has_key?(Cos::Name.new("Producer")) ||
        dictionary.has_key?(Cos::Name.new("CreationDate"))
    end

    # Check if dictionary is a PDF or FDF catalog
    private def catalog?(dictionary : Cos::Dictionary) : Bool
      type_entry = dictionary[Cos::Name.new("Type")]
      return false unless type_entry.is_a?(Cos::Name)

      type_entry.value == "Catalog" || dictionary.has_key?(Cos::Name.new("FDF"))
    end

    # Compare COS objects to determine which is newer
    private def compare_cos_objects(new_object : Cos::Object, new_offset : Int64, current_object : Cos::Object?) : Cos::Object?
      return new_object unless current_object

      if current_key = current_object.key
        new_key = new_object.key
        return new_object unless new_key

        # Check if the current object is an updated version of the previous found object
        if current_key.number == new_key.number
          return current_key.generation < new_key.generation ? new_object : current_object
        end

        # Most likely the object with the bigger offset is the newer one
        # In Java: document.getXrefTable().get(currentKey) but we don't have direct access
        # For now, assume newer object is better
        return new_object
      end

      new_object
    end

    # Brute force search for trailer dictionary
    # ameba:disable Metrics/CyclomaticComplexity
    private def bf_search_for_trailer(trailer : Cos::Dictionary) : Bool
      Log.warn { "BruteForceParser.bf_search_for_trailer: START" }
      origin_offset = @source.position
      @source.seek(MINIMUM_SEARCH_OFFSET)

      trailer_offset = find_string(TRAILER_MARKER)
      while trailer_offset != -1
        begin
          root_found = false
          info_found = false

          # Skip whitespace and parse dictionary
          scanner = get_scanner(position: trailer_offset + TRAILER_MARKER.size)
          scanner.skip_whitespace

          object_parser = ObjectParser.new(scanner, @parser)
          trailer_dict = object_parser.parse_dictionary
          next unless trailer_dict.is_a?(Cos::Dictionary)

          # Check for Root entry
          root_obj = trailer_dict[Cos::Name.new("Root")]
          if root_obj.is_a?(Cos::Object)
            # Try to dereference and check if it's a catalog
            begin
              resolved_root = @parser.resolve(root_obj)
              if resolved_root.is_a?(Cos::Dictionary) && catalog?(resolved_root)
                root_found = true
              end
            rescue
              # Ignore dereference errors
            end
          end

          # Check for Info entry
          info_obj = trailer_dict[Cos::Name.new("Info")]
          if info_obj.is_a?(Cos::Object)
            # Try to dereference and check if it's an info dictionary
            begin
              resolved_info = @parser.resolve(info_obj)
              if resolved_info.is_a?(Cos::Dictionary) && info?(resolved_info)
                info_found = true
              end
            rescue
              # Ignore dereference errors
            end
          end

          if root_found && info_found
            # Copy entries to trailer dictionary
            trailer[Cos::Name.new("Root")] = root_obj if root_obj
            trailer[Cos::Name.new("Info")] = info_obj if info_obj

            # Copy encryption if present
            enc_obj = trailer_dict[Cos::Name.new("Encrypt")]
            if enc_obj.is_a?(Cos::Object)
              begin
                resolved_enc = @parser.resolve(enc_obj)
                if resolved_enc.is_a?(Cos::Dictionary)
                  trailer[Cos::Name.new("Encrypt")] = enc_obj
                end
              rescue
                # Ignore
              end
            end

            # Copy ID if present
            id_obj = trailer_dict[Cos::Name.new("ID")]
            if id_obj.is_a?(Cos::Array)
              trailer[Cos::Name.new("ID")] = id_obj
            end

            @source.seek(origin_offset)
            Log.warn { "BruteForceParser.bf_search_for_trailer: FOUND valid trailer" }
            return true
          end
        rescue ex
          Log.debug { "Exception during brute force search for trailer: #{ex.message}" }
        end

        # Search for next trailer marker
        @source.seek(trailer_offset + TRAILER_MARKER.size)
        trailer_offset = find_string(TRAILER_MARKER)
      end

      @source.seek(origin_offset)
      Log.warn { "BruteForceParser.bf_search_for_trailer: NOT FOUND" }
      false
    end

    # Search for the different parts of the trailer dictionary
    private def search_for_trailer_items(trailer : Cos::Dictionary) : Bool
      Log.warn { "BruteForceParser.search_for_trailer_items: START" }
      root_object : Cos::Object? = nil
      info_object : Cos::Object? = nil

      object_offsets = bf_cos_object_offsets
      object_offsets.each do |key, offset|
        begin
          # Get object from parser's pool
          cos_object = @parser.get_object_from_pool(key)
          base_object = cos_object.object
          next unless base_object.is_a?(Cos::Dictionary)

          dictionary = base_object

          # Check if it's a document catalog
          if catalog?(dictionary)
            root_object = compare_cos_objects(cos_object, offset, root_object).as(Cos::Object?)
            # Check if it's an info dictionary
          elsif info?(dictionary)
            info_object = compare_cos_objects(cos_object, offset, info_object).as(Cos::Object?)
          end
        rescue ex
          Log.debug { "Error processing object #{key}: #{ex.message}" }
        end
      end

      found_root = false
      if root_object
        trailer[Cos::Name.new("Root")] = root_object
        found_root = true
        Log.warn { "BruteForceParser.search_for_trailer_items: found Root" }
      end

      if info_object
        trailer[Cos::Name.new("Info")] = info_object
        Log.warn { "BruteForceParser.search_for_trailer_items: found Info" }
      end

      Log.warn { "BruteForceParser.search_for_trailer_items: END, root_found=#{found_root}" }
      found_root
    end

    # Public method to find trailer using brute force
    def bf_find_trailer(trailer : Cos::Dictionary) : Bool
      Log.warn { "BruteForceParser.bf_find_trailer: START" }

      # First try direct trailer search
      if bf_search_for_trailer(trailer)
        Log.warn { "BruteForceParser.bf_find_trailer: found via direct search" }
        return true
      end

      # Fall back to searching individual items
      if search_for_trailer_items(trailer)
        Log.warn { "BruteForceParser.bf_find_trailer: found via item search" }
        return true
      end

      Log.warn { "BruteForceParser.bf_find_trailer: NOT FOUND" }
      false
    end

    # Convert brute force object offsets to XRef entries
    def bf_xref : XRef
      xref = XRef.new
      bf_cos_object_offsets.each do |key, offset|
        if offset < 0
          # compressed entry: negative offset indicates object stream number
          xref[key.number] = XRefEntry.new(-offset, key.generation, :compressed)
        else
          # regular in-use entry
          xref[key.number] = XRefEntry.new(offset, key.generation, :in_use)
        end
      end
      xref
    end

    # Rebuild trailer using brute force search (similar to Java rebuildTrailer)
    def rebuild_trailer(xref : XRef) : Cos::Dictionary?
      Log.warn { "BruteForceParser.rebuild_trailer: START" }

      # Get brute force offsets and populate xref
      bf_offsets = bf_cos_object_offsets
      bf_offsets.each do |key, offset|
        if offset < 0
          xref[key.number] = XRefEntry.new(-offset, key.generation, :compressed)
        else
          xref[key.number] = XRefEntry.new(offset, key.generation, :in_use)
        end
      end

      # Search for object streams and add compressed objects
      bf_search_for_obj_streams_xref(xref)

      # Create empty trailer dictionary
      trailer = Cos::Dictionary.new

      # Try to find trailer entries
      if bf_find_trailer(trailer)
        Log.warn { "BruteForceParser.rebuild_trailer: found trailer" }
        trailer
      else
        Log.warn { "BruteForceParser.rebuild_trailer: could not find trailer" }
        nil
      end
    end
  end
end
