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
          prev = trailer.try(&.[]?(Cos::Name.new("Prev"))).try(&.as?(Cos::Integer)).try(&.value.to_i64) || 0_i64
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
      if @parser.is_string(STARTXREF)
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
      if @parser.is_string(XREF_TABLE)
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
            type_name = dict[Cos::Name.new("Type")]?
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
        return 0
      end
      # TODO: implement brute force search
      # For now, return 0 (not found)
      Log.error { "Can't find the object xref table/stream at offset #{object_offset}" }
      0
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
        current_line = @parser.read_line
        split_string = current_line.strip.split(/\s+/)
        if split_string.size != 2
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
          entry_line = @parser.read_line
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
      while next_character != 't'.ord && @parser.digit?(next_character)
        if @source.position == trailer_offset
          # warn only the first time
          Log.warn { "Expected trailer object at offset #{trailer_offset}, keep trying" }
        end
        @parser.read_line
        next_character = @source.peek
      end
      if @source.peek != 't'.ord
        return false
      end
      # read "trailer"
      current_offset = @source.position
      next_line = @parser.read_line
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
      @xref_trailer_resolver.current_trailer = parsed_trailer

      @parser.skip_spaces
      true
    end

    # Parse xref object stream
    private def parse_xref_obj_stream(obj_byte_offset : Int64, is_standalone : Bool) : Int64
      # TODO: implement similar to Java parseXrefObjStream
      0_i64
    end

    # Check offsets of all referenced objects
    private def check_xref_offsets : Nil
      # TODO: implement similar to Java checkXrefOffsets
    end

    # Returns the resulting cross reference table.
    def xref_table : Hash(Cos::ObjectKey, Int64)
      @xref_trailer_resolver.xref_table || Hash(Cos::ObjectKey, Int64).new
    end

    # Returns the resolved trailer dictionary.
    def trailer : Cos::Dictionary?
      @xref_trailer_resolver.trailer
    end
  end
end
