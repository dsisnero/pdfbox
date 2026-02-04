# XrefParser - Parser to read the cross reference table of a PDF
# Similar to Apache PDFBox XrefParser
require "./xref_trailer_resolver"

module Pdfbox::Pdfparser
  class XrefParser
    Log = ::Log.for(self)

    private X                     = 'x'
    private XREF_TABLE            = ['x', 'r', 'e', 'f']
    private STARTXREF             = ['s', 't', 'a', 'r', 't', 'x', 'r', 'e', 'f']
    private MINIMUM_SEARCH_OFFSET = 6_i64

    # Collects all Xref/trailer objects and resolves them into single
    # object using startxref reference.
    @xref_trailer_resolver : XrefTrailerResolver

    @parser : COSParser
    @source : Pdfbox::IO::RandomAccessRead

    # Default constructor.
    #
    # @param cos_parser the parser to be used to read the pdf.
    def initialize(cos_parser : COSParser)
      @parser = cos_parser
      @source = cos_parser.source
      @xref_trailer_resolver = XrefTrailerResolver.new
    end

    # Parse the xref chain starting at the given offset.
    # Returns the resolved trailer dictionary.
    def parse_xref(start_xref_offset : Int64) : Cos::Dictionary?
      @source.seek(start_xref_offset)
      start_xref_offset = Math.max(0_i64, parse_startxref)

      # check the startxref offset
      fixed_offset = check_xref_offset(start_xref_offset)
      if fixed_offset > -1
        start_xref_offset = fixed_offset
      end

      prev = start_xref_offset
      # ---- parse whole chain of xref tables/object streams using PREV reference
      prev_set = Set(Int64).new
      trailer = nil

      while prev > 0
        # save expected position for loop detection
        prev_set.add(prev)
        # seek to xref table
        @source.seek(prev)
        # skip white spaces
        @parser.skip_spaces
        # save current position as well due to skipped spaces
        prev_set.add(@source.position)

        # -- parse xref
        if @source.peek == X.ord
          # xref table and trailer
          # use existing parser to parse xref table
          if !parse_xref_table(prev) || !parse_trailer
            raise ::IO::Error.new("Expected trailer object at offset #{@source.position}")
          end
          trailer = @xref_trailer_resolver.current_trailer
          # check for a XRef stream, it may contain some object ids of compressed objects
          if trailer && trailer.has_key?(Cos::Name.new("XRefStm"))
            stream_offset = trailer[Cos::Name.new("XRefStm")].as(Cos::Integer).value.to_i64
            # check the xref stream reference
            fixed_offset = check_xref_offset(stream_offset)
            if fixed_offset > -1 && fixed_offset != stream_offset
              Log.warn { "/XRefStm offset #{stream_offset} is incorrect, corrected to #{fixed_offset}" }
              stream_offset = fixed_offset
              trailer[Cos::Name.new("XRefStm")] = Cos::Integer.new(stream_offset)
            end
            if stream_offset > 0
              @source.seek(stream_offset)
              @parser.skip_spaces
              begin
                parse_xref_obj_stream(prev, false)
                # document.setHasHybridXRef() # TODO
              rescue ex
                Log.error { "Failed to parse /XRefStm at offset #{stream_offset}: #{ex.message}" }
              end
            else
              Log.error { "Skipped XRef stream due to a corrupt offset: #{stream_offset}" }
            end
          end
          prev = trailer.try(&.[](Cos::Name.new("Prev"))).try(&.as?(Cos::Integer)).try(&.value.to_i64) || 0_i64
        else
          # parse xref stream
          prev = parse_xref_obj_stream(prev, true)
          trailer = @xref_trailer_resolver.current_trailer
        end

        if prev > 0
          # check the xref table reference
          fixed_offset = check_xref_offset(prev)
          if fixed_offset > -1 && fixed_offset != prev
            prev = fixed_offset
            if trailer
              trailer[Cos::Name.new("Prev")] = Cos::Integer.new(prev)
            end
          end
        end

        if prev_set.includes?(prev)
          raise ::IO::Error.new("/Prev loop at offset #{prev}")
        end
      end

      # ---- build valid xrefs out of the xref chain
      @xref_trailer_resolver.startxref = start_xref_offset
      trailer = @xref_trailer_resolver.trailer
      # TODO: document.setTrailer(trailer)
      # TODO: document.setIsXRefStream
      # check the offsets of all referenced objects
      check_xref_offsets
      # TODO: copy xref table to document

      trailer
    end

    # Parse startxref keyword and offset
    private def parse_startxref : Int64
      start_xref = -1_i64
      if @parser.string?(STARTXREF)
        @parser.read_string
        @parser.skip_spaces
        # This integer is the byte offset of the first object referenced by the xref or xref stream
        start_xref = @parser.read_long
      end
      start_xref
    end

    # Check if the given offset points to a valid xref table or stream
    private def check_xref_offset(start_xref_offset : Int64) : Int64
      @source.seek(start_xref_offset)
      @parser.skip_spaces
      if @parser.string?(XREF_TABLE)
        return start_xref_offset
      end
      if start_xref_offset > 0
        if check_xref_stream_offset(start_xref_offset)
          return start_xref_offset
        else
          return calculate_xref_fixed_offset(start_xref_offset)
        end
      end
      # can't find a valid offset
      -1_i64
    end

    # Check if cross reference stream can be found at current offset
    private def check_xref_stream_offset(start_xref_offset : Int64) : Bool
      if start_xref_offset == 0
        return true
      end
      # seek to offset-1
      @source.seek(start_xref_offset - 1)
      next_value = @source.read
      # the first character has to be a whitespace, and then a digit
      if next_value && @parser.whitespace?(next_value)
        @parser.skip_spaces
        if @parser.digit?
          begin
            # it's a XRef stream
            @parser.read_object_number
            @parser.read_generation_number
            @parser.read_object_marker
            # check the dictionary to avoid false positives
            dict = @parser.parse_dictionary(false)
            @source.seek(start_xref_offset)
            type_name = dict[Cos::Name.new("Type")]
            if type_name.is_a?(Cos::Name) && type_name.value == "XRef"
              return true
            end
          rescue
            # ignore and fall through
          end
        end
      end
      false
    end

    # Try to find a fixed offset for the given xref table/stream.
    private def calculate_xref_fixed_offset(object_offset : Int64) : Int64
      if object_offset < 0
        Log.error { "Invalid object offset #{object_offset} when searching for a xref table/stream" }
        return 0_i64
      end
      # TODO: implement brute force search
      # For now, return 0 (not found)
      Log.error { "Can't find the object xref table/stream at offset #{object_offset}" }
      0_i64
    end

    # Get the parser as a Parser instance (since @parser is actually a Parser)
    private def parser_as_parser : Parser
      parser = @parser.as?(Parser)
      unless parser
        raise "XrefParser requires a Parser instance, got #{@parser.class}"
      end
      parser
    end

    # Parse xref table from stream and add it to the state
    private def parse_xref_table(start_byte_offset : Int64) : Bool
      if @source.peek != X.ord
        return false
      end

      xref = @parser.read_string
      unless xref.strip == "xref"
        return false
      end

      # check for trailer after xref
      str = @parser.read_string
      bytes = str.to_slice
      @source.seek(@source.position - bytes.size)

      # signal start of new XRef
      @xref_trailer_resolver.next_xref_obj(start_byte_offset, XRefType::Table)

      if str.starts_with?("trailer")
        Log.warn { "skipping empty xref table" }
        return false
      end

      # Xref tables can have multiple sections. Each starts with a starting object id and a count.
      loop do
        saved_pos = @source.position
        current_line = parser_as_parser.read_line
        split_string = current_line.strip.split(/\s+/)
        if split_string.size != 2
          # Check if we've reached the trailer
          if split_string.size == 1 && split_string[0] == "trailer"
            # Rewind to before the trailer line
            @source.seek(saved_pos)
            break
          end
          Log.warn { "Unexpected XRefTable Entry: #{current_line}" }
          return false
        end

        # first obj id
        begin
          curr_obj_id = split_string[0].to_i64
        rescue
          Log.warn { "XRefTable: invalid ID for the first object: #{current_line}" }
          return false
        end

        # the number of objects in the xref table
        begin
          count = split_string[1].to_i32
        rescue
          Log.warn { "XRefTable: invalid number of objects: #{current_line}" }
          return false
        end

        count.times do |i|
          break if @parser.eof?

          next_char = @source.peek
          break unless next_char
          if next_char.chr == 't' || @parser.end_of_name?(next_char)
            break
          end

          # Read xref entry line
          entry_line = parser_as_parser.read_line
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
                @xref_trailer_resolver.add_xref(key, curr_offset)
              end
            elsif entry_parts[2] == "f"
              # Free entry: store offset 0
              key = Cos::ObjectKey.new(curr_obj_id + i, curr_gen_id.to_i64)
              @xref_trailer_resolver.add_xref(key, 0_i64)
            else
              Log.warn { "Invalid xref entry type: #{entry_line}" }
              return false
            end
          rescue
            Log.warn { "Invalid xref entry: #{entry_line}" }
            return false
          end
        end
      end

      true
    end

    # Parse trailer from stream and add it to the state
    private def parse_trailer : Bool
      # parse the last trailer.
      trailer_offset = @source.position

      # PDFBOX-1739 skip extra xref entries in RegisSTAR documents
      next_character = @source.peek
      while next_character && next_character != 't'.ord && @parser.digit?(next_character.to_i32)
        if @source.position == trailer_offset
          # warn only the first time
          Log.warn { "Expected trailer object at offset #{trailer_offset}, keep trying" }
        end
        parser_as_parser.read_line
        next_character = @source.peek
      end
      char = @source.peek
      if char.nil? || char != 't'.ord
        return false
      end
      # read "trailer"
      current_offset = @source.position
      next_line = parser_as_parser.read_line
      unless next_line.strip == "trailer"
        # in some cases the EOL is missing and the trailer immediately
        # continues with "<<" or with a blank character
        # even if this does not comply with PDF reference we want to support as many PDFs as possible
        # Acrobat reader can also deal with this.
        if next_line.starts_with?("trailer")
          # we can't just unread a portion of the read data as we don't know if the EOL consist of 1 or 2 bytes
          len = "trailer".size
          # jump back right after "trailer"
          @source.seek(current_offset + len)
        else
          return false
        end
      end

      # in some cases the EOL is missing and the trailer continues with " <<"
      # even if this does not comply with PDF reference we want to support as many PDFs as possible
      # Acrobat reader can also deal with this.
      @parser.skip_spaces

      parsed_trailer = @parser.parse_dictionary(true)

      if parsed_trailer
        @xref_trailer_resolver.current_trailer = parsed_trailer
      end

      @parser.skip_spaces
      true
    end

    # Parse xref object stream
    private def parse_xref_obj_stream(obj_byte_offset : Int64, is_standalone : Bool) : Int64
      saved_pos = @source.position
      begin
        @source.seek(obj_byte_offset)
        @parser.skip_spaces
        # Parse indirect object head
        @parser.read_object_number
        @parser.read_generation_number
        @parser.read_object_marker
        # Parse dictionary
        dict = @parser.parse_dictionary(false)

        # Check if it's actually an xref stream
        type_entry = dict[Cos::Name.new("Type")]
        unless type_entry && type_entry.is_a?(Cos::Name) && type_entry.value == "XRef"
          Log.error { "Not an XRef stream at offset #{obj_byte_offset}" }
          return 0_i64
        end

        # Signal new xref object to resolver if standalone
        if is_standalone
          @xref_trailer_resolver.next_xref_obj(obj_byte_offset, XRefType::Stream)
          @xref_trailer_resolver.current_trailer = dict.as(Cos::Dictionary)
        end

        # Parse the stream
        stream = @parser.parse_cos_stream(dict)

        # Parse xref stream data
        parse_xref_stream_data(dict, stream, obj_byte_offset)

        # Get prev value if present
        prev_entry = dict[Cos::Name.new("Prev")]
        prev = if prev_entry.is_a?(Cos::Integer)
                 prev_entry.value.to_i64
               else
                 0_i64
               end
        Log.debug { "Xref stream at offset #{obj_byte_offset} parsed, prev=#{prev}" }
        prev
      rescue ex
        Log.error { "Failed to parse xref stream at offset #{obj_byte_offset}: #{ex.message}" }
        0_i64
      ensure
        @source.seek(saved_pos)
      end
    end

    # Parse xref stream data and add entries to resolver
    private def parse_xref_stream_data(dict : Cos::Dictionary, stream : Cos::Stream, offset : Int64) : Nil
      parser = parser_as_parser
      # Use parser's parse_xref_stream with our resolver
      # We ignore the returned XRef because entries are already added via resolver
      parser.parse_xref_stream(offset, standalone: false, resolver: @xref_trailer_resolver)
    end

    # Check if the given object can be found at the given offset. Returns the provided object key if everything is ok.
    # If the generation number differs it will be fixed and a new object key is returned.
    private def find_object_key(object_key : Cos::ObjectKey, offset : Int64, xref_offset : Hash(Cos::ObjectKey, Int64)) : Cos::ObjectKey?
      # there can't be any object at the very beginning of a pdf
      if offset < MINIMUM_SEARCH_OFFSET
        return
      end

      begin
        @source.seek(offset)
        @parser.skip_spaces
        if @source.position == offset
          # ensure that at least one whitespace is skipped in front of the object number
          @source.seek(offset - 1)
          if @source.position < offset
            if !@parser.digit?
              # anything else but a digit may be some garbage of the previous object -> just ignore it
              @source.read
            else
              current = @source.position
              # Move back one position to check if we're at a digit
              if current > 0
                @source.seek(current - 1)
                # Scan backwards while we find digits
                while @parser.digit? && @source.position > 0
                  @source.seek(@source.position - 1)
                end
              end
              new_obj_num = @parser.read_object_number
              new_gen_num = @parser.read_generation_number
              new_obj_key = Cos::ObjectKey.new(new_obj_num, new_gen_num)
              existing_offset = xref_offset[new_obj_key]?
              # the found object number belongs to another uncompressed object at the same or nearby offset
              # something has to be wrong
              if existing_offset && existing_offset > 0 && (offset - existing_offset).abs < 10
                Log.debug { "Found the object #{new_obj_key} instead of #{object_key} at offset #{offset} - ignoring" }
                return
              end
              # something seems to be wrong but it's hard to determine what exactly -> simply continue
              @source.seek(offset)
            end
          end
        end

        # try to read the given object/generation number
        found_object_number = @parser.read_object_number
        if object_key.number != found_object_number
          Log.warn { "found wrong object number. expected [#{object_key.number}] found [#{found_object_number}]" }
          object_key = Cos::ObjectKey.new(found_object_number, object_key.generation)
        end

        gen_number = @parser.read_generation_number
        # finally try to read the object marker
        @parser.read_object_marker
        if gen_number == object_key.generation
          return object_key
        elsif gen_number > object_key.generation
          return Cos::ObjectKey.new(object_key.number, gen_number)
        end
      rescue ex : ::IO::Error
        # Swallow the exception, obviously there isn't any valid object number
        Log.debug { "No valid object at given location #{offset} - ignoring: #{ex.message}" }
      end
      nil
    end

    # Validate xref offsets by checking if objects can be found at their offsets
    private def validate_xref_offsets(xref_offset : Hash(Cos::ObjectKey, Int64)) : Bool
      return true if xref_offset.empty?

      corrected_keys = {} of Cos::ObjectKey => Cos::ObjectKey
      valid_keys = Set(Cos::ObjectKey).new

      xref_offset.each do |object_key, object_offset|
        # a negative offset number represents an object number itself (type 2 entry in xref stream)
        if object_offset >= 0
          found_object_key = find_object_key(object_key, object_offset, xref_offset)
          if found_object_key.nil?
            Log.debug { "Stop checking xref offsets as at least one (#{object_key}) couldn't be dereferenced" }
            return false
          elsif found_object_key != object_key
            # Generation was fixed - need to update map later, after iteration
            corrected_keys[object_key] = found_object_key
          else
            valid_keys.add(object_key)
          end
        end
      end

      corrected_pointers = {} of Cos::ObjectKey => Int64
      corrected_keys.each do |old_key, new_key|
        if !valid_keys.includes?(new_key)
          # Only replace entries, if the original entry does not point to a valid object
          corrected_pointers[new_key] = xref_offset[old_key]
        end
      end

      # remove old invalid, as some might not be replaced
      corrected_keys.each_key do |key|
        xref_offset.delete(key)
      end
      xref_offset.merge!(corrected_pointers)

      true
    end

    # Check offsets of all referenced objects
    private def check_xref_offsets : Nil
      xref_offset = @xref_trailer_resolver.xref_table
      return if xref_offset.nil? || xref_offset.empty?

      unless validate_xref_offsets(xref_offset)
        parser = parser_as_parser
        bf_cos_object_offsets = parser.get_brute_force_parser.bf_cos_object_offsets
        unless bf_cos_object_offsets.empty?
          Log.debug { "Replaced read xref table with the results of a brute force search" }
          # Preserve compressed entries (negative offsets) from original xref table
          compressed_entries = xref_offset.select { |_key, offset| offset < 0 }
          xref_offset.clear
          xref_offset.merge!(bf_cos_object_offsets)
          # Add back compressed entries (overwrite any conflicts with brute force results)
          compressed_entries.each do |key, offset|
            xref_offset[key] = offset
          end
          Log.debug { "After merging compressed entries: xref_offset size=#{xref_offset.size}, compressed=#{compressed_entries.size}" }
        end
      end
    end

    # Returns the resulting cross reference table.
    def xref_table : Hash(Cos::ObjectKey, Int64)
      table = @xref_trailer_resolver.xref_table
      if table
        compressed = table.count { |_key, offset| offset < 0 }
        Log.debug { "XrefParser.xref_table: returning resolved table size=#{table.size}, compressed=#{compressed}" }
        table
      else
        Log.debug { "XrefParser.xref_table: resolved table is nil, returning empty hash" }
        Hash(Cos::ObjectKey, Int64).new
      end
    end

    # Returns the resolved trailer dictionary.
    def trailer : Cos::Dictionary?
      @xref_trailer_resolver.trailer
    end
  end
end
