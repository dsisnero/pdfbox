# An object stream that compresses a number of COSObjects into a Flate-compressed stream.
# Port of org.apache.pdfbox.pdfwriter.compress.COSWriterObjectStream.
module Pdfbox::Pdfwriter::Compress
  class COSWriterObjectStream
    getter prepared_keys : Array(Pdfbox::Cos::ObjectKey)
    getter prepared_objects : Array(Pdfbox::Cos::Base)

    @compression_pool : COSWriterCompressionPool
    @prepared_keys : Array(Pdfbox::Cos::ObjectKey)
    @prepared_objects : Array(Pdfbox::Cos::Base)

    def initialize(@compression_pool : COSWriterCompressionPool)
      @prepared_keys = [] of Pdfbox::Cos::ObjectKey
      @prepared_objects = [] of Pdfbox::Cos::Base
    end

    # Prepare an object to be written to this object stream.
    def prepare_stream_object(key : Pdfbox::Cos::ObjectKey, object : Pdfbox::Cos::Base) : Nil
      @prepared_keys << key
      @prepared_objects << (object.is_a?(Pdfbox::Cos::Object) ? object.object : object)
    end

    # Write all prepared objects to the given COSStream.
    def write_objects_to_stream(stream : Pdfbox::Cos::Stream) : Pdfbox::Cos::Stream
      object_count = @prepared_keys.size
      stream[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("ObjStm")
      stream.set_int(Pdfbox::Cos::Name.new("N"), object_count.to_i64)

      # Prepare object numbers and serialized object buffers
      object_numbers = [] of Int64
      object_buffers = [] of Bytes
      object_count.times do |i|
        partial = ::IO::Memory.new
        object_numbers << @prepared_keys[i].number
        write_object(partial, @prepared_objects[i], true)
        object_buffers << partial.to_slice
      end

      # Build offset map
      next_offset = 0_i64
      offsets_io = ::IO::Memory.new
      object_numbers.each_with_index do |obj_num, i|
        offsets_io << obj_num.to_s
        offsets_io.write_byte(32_u8)
        offsets_io << next_offset.to_s
        offsets_io.write_byte(32_u8)
        next_offset += object_buffers[i].size
      end
      offsets_bytes = offsets_io.to_slice

      # Write Flate-compressed data
      compressed = ::IO::Memory.new
      compressed.write(offsets_bytes)
      stream.set_int(Pdfbox::Cos::Name.new("First"), offsets_bytes.size.to_i64)
      object_buffers.each do |buf|
        compressed.write(buf)
      end

      stream.data = compressed.to_slice
      stream
    end

    # Recursive writer for COS objects within the object stream.
    private def write_object(output : ::IO, object : Pdfbox::Cos::Base?, top_level : Bool) : Nil
      return unless object

      base = object
      if object.is_a?(Pdfbox::Cos::Object)
        if !top_level
          actual_key = object.key
          if actual_key
            write_object_reference(output, actual_key)
            return
          end
        end
        base = object.object
        return write_cos_null(output) unless base
      end

      if !top_level && @compression_pool.contains?(base)
        key = @compression_pool.key_for(base)
        return write_object_reference(output, key) if key
      end

      case base
      when Pdfbox::Cos::String     then write_cos_string(output, base)
      when Pdfbox::Cos::Float      then write_cos_float(output, base)
      when Pdfbox::Cos::Integer    then write_cos_integer(output, base)
      when Pdfbox::Cos::Boolean    then write_cos_boolean(output, base)
      when Pdfbox::Cos::Name       then write_cos_name(output, base)
      when Pdfbox::Cos::Array      then write_cos_array(output, base)
      when Pdfbox::Cos::Dictionary then write_cos_dictionary(output, base)
      when Pdfbox::Cos::Null       then write_cos_null(output)
      when Pdfbox::Cos::Object     then write_object(output, base, top_level)
      end
    end

    private def write_cos_string(output, str) : Nil
      str.write_pdf(output)
      output.write_byte(32_u8)
    end

    private def write_cos_float(output, flt) : Nil
      flt.write_pdf(output)
      output.write_byte(32_u8)
    end

    private def write_cos_integer(output, int) : Nil
      int.write_pdf(output)
      output.write_byte(32_u8)
    end

    private def write_cos_boolean(output, bool) : Nil
      bool.write_pdf(output)
      output.write_byte(32_u8)
    end

    private def write_cos_name(output, name) : Nil
      name.write_pdf(output)
      output.write_byte(32_u8)
    end

    private def write_cos_array(output, arr) : Nil
      output.write_byte(91_u8) # [
      arr.items.each do |item|
        if item
          write_object(output, item, false)
        else
          write_cos_null(output)
        end
      end
      output.write_byte(93_u8) # ]
      output.write_byte(32_u8)
    end

    private def write_cos_dictionary(output, dict) : Nil
      output.write("<<".to_slice)
      dict.entries.each do |key, value|
        next unless value
        # Keys are always top-level to avoid indirect object references (PDFBOX-5927)
        write_object(output, key, true)
        write_object(output, value, false)
      end
      output.write(">>".to_slice)
      output.write_byte(32_u8)
    end

    private def write_cos_null(output) : Nil
      output.write("null".to_slice)
      output.write_byte(32_u8)
    end

    private def write_object_reference(output, key) : Nil
      output << key.number.to_s
      output.write_byte(32_u8)
      output << key.generation.to_s
      output.write_byte(32_u8)
      output.write_byte(82_u8) # R
      output.write_byte(32_u8)
    end
  end
end
