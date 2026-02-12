# XrefTrailerResolver collects all XRef/trailer objects and creates correct
# xref/trailer information after all objects are read using startxref
# and 'Prev' information (unused XRef/trailer objects are discarded).
#
# In case of missing startxref or wrong startxref pointer all
# XRef/trailer objects are used to create xref table / trailer dictionary
# in order they occur.
#
# For each new xref object/XRef stream method #next_xref_obj must be called
# with start byte position. All following calls to #add_xref or #current_trailer=
# will add the data for this byte position.
#
# After all objects are parsed the startxref position must be provided
# using #startxref=. This is used to build the chain of active xref/trailer
# objects used for creating document trailer and xref table.
require "../cos"

module Pdfbox::Pdfparser
  Log = ::Log.for(self)

  # The XRefType of a trailer.
  enum XRefType
    # XRef table type
    Table
    # XRef stream type
    Stream
  end

  class XrefTrailerResolver
    # A class which represents a xref/trailer object.
    private class XrefTrailerObj
      property trailer : Cos::Dictionary?
      property xref_type : XRefType
      getter xref_table : Hash(Cos::ObjectKey, Int64)

      # Default constructor.
      def initialize
        @xref_type = XRefType::Table
        @xref_table = Hash(Cos::ObjectKey, Int64).new
        @trailer = nil
      end

      def reset : Nil
        @xref_table.clear
      end
    end

    @byte_pos_to_xref_map : Hash(Int64, XrefTrailerObj)
    @cur_xref_trailer_obj : XrefTrailerObj?
    @resolved_xref_trailer : XrefTrailerObj?

    # Log instance.
    Log = ::Log.for(self)

    PREV = Cos::Name.new("Prev")

    def initialize
      @byte_pos_to_xref_map = Hash(Int64, XrefTrailerObj).new
      @cur_xref_trailer_obj = nil
      @resolved_xref_trailer = nil
    end

    # Returns the first trailer if at least one exists.
    def first_trailer : Cos::Dictionary?
      return if @byte_pos_to_xref_map.empty?
      offsets = @byte_pos_to_xref_map.keys
      sorted_offset = offsets.sort
      @byte_pos_to_xref_map[sorted_offset.first].trailer
    end

    # Returns the last trailer if at least one exists.
    def last_trailer : Cos::Dictionary?
      return if @byte_pos_to_xref_map.empty?
      offsets = @byte_pos_to_xref_map.keys
      sorted_offset = offsets.sort
      @byte_pos_to_xref_map[sorted_offset.last].trailer
    end

    # Returns the count of trailers.
    def trailer_count : Int32
      @byte_pos_to_xref_map.size
    end

    # Signals that a new XRef object (table or stream) starts.
    # @param start_byte_pos the offset to start at
    # @param type the type of the Xref object
    def next_xref_obj(start_byte_pos : Int64, type : XRefType) : Nil
      obj = XrefTrailerObj.new
      @cur_xref_trailer_obj = obj
      @byte_pos_to_xref_map[start_byte_pos] = obj
      obj.xref_type = type
    end

    # Returns the XRefType of the resolved trailer.
    def xref_type : XRefType?
      @resolved_xref_trailer.try &.xref_type
    end

    # Populate XRef HashMap of current XRef object.
    # Will add an Xreftable entry that maps ObjectKeys to byte offsets in the file.
    # @param obj_key The objkey, with id and gen numbers
    # @param offset The byte offset in this file
    def add_xref(obj_key : Cos::ObjectKey, offset : Int64) : Nil
      cur_obj = @cur_xref_trailer_obj
      if cur_obj.nil?
        # should not happen...
        Log.warn { "Cannot add XRef entry for '#{obj_key.number}' because XRef start was not signalled." }
        return
      end
      # PDFBOX-3506 check before adding to the map, to avoid entries from the table being
      # overwritten by obsolete entries in hybrid files (/XRefStm entry)
      unless cur_obj.xref_table.has_key?(obj_key)
        cur_obj.xref_table[obj_key] = offset
        if obj_key.number == 141
          Log.debug { "XrefTrailerResolver.add_xref: added object 141, offset #{offset}, generation #{obj_key.generation}, stream_index #{obj_key.stream_index}" }
        end
      end
    end

    # Adds trailer information for current XRef object.
    #
    # @param trailer the current document trailer dictionary
    def current_trailer=(trailer : Cos::Dictionary) : Nil
      cur_obj = @cur_xref_trailer_obj
      if cur_obj.nil?
        # should not happen...
        Log.warn { "Cannot add trailer because XRef start was not signalled." }
        return
      end
      cur_obj.trailer = trailer
    end

    # Returns the trailer last set by #current_trailer=.
    def current_trailer : Cos::Dictionary?
      @cur_xref_trailer_obj.try &.trailer
    end

    # Sets the byte position of the first XRef
    # (has to be called after very last startxref was read).
    # This is used to resolve chain of active XRef/trailer.
    #
    # In case startxref position is not found we output a
    # warning and use all XRef/trailer objects combined
    # in byte position order.
    # Thus for incomplete PDF documents with missing
    # startxref one could call this method with parameter value -1.
    #
    # @param startxref_byte_pos_value starting position of the first XRef
    def startxref=(startxref_byte_pos_value : Int64) : Nil
      puts "XrefTrailerResolver.startxref= called with #{startxref_byte_pos_value}"
      puts "  byte_pos_to_xref_map size = #{@byte_pos_to_xref_map.size}"
      @byte_pos_to_xref_map.each do |pos, obj|
        puts "    pos #{pos}: xref_table size #{obj.xref_table.size}, trailer #{obj.trailer ? "present" : "nil"}"
      end
      if @resolved_xref_trailer
        Log.warn { "Method must be called only ones with last startxref value." }
        return
      end

      resolved = XrefTrailerObj.new
      resolved.trailer = Cos::Dictionary.new
      @resolved_xref_trailer = resolved

      cur_obj = @byte_pos_to_xref_map[startxref_byte_pos_value]?
      xref_seq_byte_pos = [] of Int64

      if cur_obj.nil?
        # no XRef at given position
        puts "  No XRef object at position #{startxref_byte_pos_value}"
        Log.warn { "Did not found XRef object at specified startxref position #{startxref_byte_pos_value}" }

        # use all objects in byte position order (last entries overwrite previous ones)
        xref_seq_byte_pos.concat(@byte_pos_to_xref_map.keys)
        xref_seq_byte_pos.sort!
      else
        # copy xref type
        resolved.xref_type = cur_obj.xref_type
        # found starting Xref object
        # add this and follow chain defined by 'Prev' keys
        xref_seq_byte_pos << startxref_byte_pos_value
        while cur_obj.trailer
          prev_byte_pos = long(cur_obj.trailer.as(Cos::Dictionary), PREV, -1_i64)
          if prev_byte_pos == -1
            break
          end

          cur_obj = @byte_pos_to_xref_map[prev_byte_pos]?
          if cur_obj.nil?
            Log.warn { "Did not found XRef object pointed to by 'Prev' key at position #{prev_byte_pos}" }
            break
          end
          xref_seq_byte_pos << prev_byte_pos

          # prevent infinite loops
          if xref_seq_byte_pos.size >= @byte_pos_to_xref_map.size
            break
          end
        end
        # have to reverse order so that later XRefs will overwrite previous ones
        xref_seq_byte_pos.reverse!
      end

      puts "  xref_seq_byte_pos = #{xref_seq_byte_pos}"
      # merge used and sorted XRef/trailer
      xref_seq_byte_pos.each do |b_pos|
        cur_obj = @byte_pos_to_xref_map[b_pos]
        puts "  merging xref object at pos #{b_pos}: xref_table size #{cur_obj.xref_table.size}"
        if trailer = cur_obj.trailer
          resolved_trailer = resolved.trailer.as(Cos::Dictionary)
          trailer.entries.each do |key, value|
            resolved_trailer[key] = value
          end
        end
        cur_obj.xref_table.each do |key, offset|
          resolved.xref_table[key] = offset
          if key.number == 141
            puts "    merged object 141: offset #{offset}, generation #{key.generation}, stream_index #{key.stream_index}"
          end
        end
      end
      puts "  resolved xref_table size = #{resolved.xref_table.size}"
    end

    # Gets the resolved trailer. Might return nil in case
    # #set_startxref was not called before.
    def trailer : Cos::Dictionary?
      @resolved_xref_trailer.try &.trailer
    end

    # Gets the resolved xref table. Might return nil in case
    # #set_startxref was not called before.
    def xref_table : Hash(Cos::ObjectKey, Int64)?
      table = @resolved_xref_trailer.try &.xref_table
      if table && !table.empty?
        compressed = table.count { |_key, offset| offset < 0 }
        puts "XrefTrailerResolver.xref_table: size=#{table.size}, compressed=#{compressed}"
        # Debug object 141
        table.each do |key, offset|
          if key.number == 141
            puts "XrefTrailerResolver.xref_table: object 141: offset #{offset}, generation #{key.generation}, stream_index #{key.stream_index}"
          end
        end
      else
        puts "XrefTrailerResolver.xref_table: table is #{table ? "empty" : "nil"}"
      end
      table
    end

    # Returns object numbers which are referenced as contained
    # in object stream with specified object number.
    #
    # This will scan resolved xref table for all entries having negated
    # stream object number as value.
    #
    # @param objstm_obj_nr object number of object stream for which contained object numbers
    #                     should be returned
    #
    # @return set of object numbers referenced for given object stream
    #         or nil if #set_startxref was not called before so that no resolved xref table exists
    def contained_object_numbers(objstm_obj_nr : Int32) : Set(Int64)?
      resolved = @resolved_xref_trailer
      return if resolved.nil?
      ref_obj_nrs = Set(Int64).new
      cmp_val = -objstm_obj_nr

      resolved.xref_table.each do |key, value|
        if value == cmp_val
          ref_obj_nrs.add(key.number)
        end
      end
      ref_obj_nrs
    end

    # Returns the long value for the given key in the dictionary, or default if missing/not a number.
    private def long(dict : Cos::Dictionary, key : Cos::Name, default : Int64 = -1_i64) : Int64
      value = dict[key]
      case value
      when Cos::Integer
        value.value
      when Cos::Float
        value.value.to_i64
      else
        default
      end
    end

    # Reset all data so that it can be used to rebuild the trailer.
    protected def reset : Nil
      @byte_pos_to_xref_map.each_value do |trailer_obj|
        trailer_obj.reset
      end
      @cur_xref_trailer_obj = nil
      @resolved_xref_trailer = nil
    end
  end
end
