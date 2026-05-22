# PDF Writer module for PDFBox Crystal
#
# This module contains PDF writing functionality,
# corresponding to the pdfwriter package in Apache PDFBox.
require "./cos"
require "./content_stream/operator"
require "./content_stream/operator_name"
require "./pdfwriter/compress"

module Pdfbox::Pdfwriter
  # Base class for PDF writing errors
  class WriteError < Pdfbox::PDFError; end

  # Raised when PDF cannot be written
  class IOException < WriteError; end

  # Raised when encryption fails
  class EncryptionError < WriteError; end

  # Main PDF writer class
  # Port of Apache PDFBox COSWriter, simplified: writes all indirect COS objects
  # reachable from the document catalog via BFS, then xref + trailer.
  class Writer
    Log = ::Log.for(self)

    @destination : ::IO
    @document : Pdfbox::Pdmodel::Document
    @parameters : Pdfbox::Pdfwriter::Compress::CompressParameters
    @will_encrypt : Bool = false
    @security_handler : Pdfbox::Pdmodel::Encryption::SecurityHandler?
    @use_xref_streams : Bool = true

    def initialize(@destination : ::IO, @document : Pdfbox::Pdmodel::Document, @parameters : Pdfbox::Pdfwriter::Compress::CompressParameters = Pdfbox::Pdfwriter::Compress::CompressParameters::DEFAULT_COMPRESSION)
      if encryption = @document.encryption
        @security_handler = encryption.security_handler
        @will_encrypt = !@security_handler.nil?
        @security_handler.try(&.prepare_document_for_encryption(@document))
      end
    end

    def write_header(version : String) : Nil
      @destination << "%PDF-#{version}\n"
      @destination << "%\xE2\xE3\xCF\xD3\n"
    end

    def write : Nil
      header = header_version_for_write
      if @parameters.compress? || (v = header.to_f32?) && v >= 1.6_f32
        @document.set_version(header.to_f32)
      end
      write_header(header)
      cos_writer = COSWriter.new(@destination, @will_encrypt, @security_handler)

      trailer = @document.trailer
      catalog = @document.document_catalog

      if @use_xref_streams && @parameters.compress?
        write_compressed(cos_writer, catalog, trailer)
      else
        write_standard(cos_writer, catalog, trailer)
      end
    end

    # Write using compressed object streams (PDF 1.5+).
    private def write_compressed(cos_writer : COSWriter,
                                 catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                 trailer : Pdfbox::Cos::Dictionary?) : Nil
      # Use compression pool for object classification and traversal
      compression_pool = Compress::COSWriterCompressionPool.new(@document, @parameters)

      # Collect and assign object numbers
      object_keys = {} of UInt64 => Pdfbox::Cos::ObjectKey
      key_objects = {} of Pdfbox::Cos::ObjectKey => Pdfbox::Cos::Base
      object_wrapper = {} of UInt64 => UInt64
      roots = build_roots(catalog)
      collect_objects(roots, object_keys, key_objects, object_wrapper)
      object_wrapper.each do |wrapper_id, inner_id|
        if inner_key = object_keys[inner_id]?
          object_keys[wrapper_id] = inner_key
        end
      end

      # Register objects with compression pool
      key_objects.each do |key, obj|
        compression_pool.register_object(key, obj)
      end

      # Create object streams for compressible objects
      object_streams = compression_pool.create_object_streams

      xref_entries = [] of XRefEntry
      xref_entries << XRefEntry.new(0_i64, 65535_i64, :free)
      next_obj = key_objects.size.to_i64 + 1_i64

      # Write object streams first
      object_streams.each do |obj_stream|
        stream = Pdfbox::Cos::Stream.new
        obj_stream.write_objects_to_stream(stream)

        stream_key = Pdfbox::Cos::ObjectKey.new(next_obj, 0_i64)
        next_obj += 1
        pos = @destination.pos.to_i64
        xref_entries << XRefEntry.new(pos, 0_i64, :in_use)
        @destination << stream_key.number << " 0 obj\n"
        cos_writer.write_stream(stream, stream_key.number, stream_key.generation)
        @destination << "\nendobj\n"

        # Add compressed xref entries for objects in this stream
        obj_stream.prepared_keys.each do |prep_key|
          xref_entries << XRefEntry.new(stream_key.number, prep_key.number)
        end
      end

      # Write top-level objects (not in object streams)
      sorted = key_objects.keys.sort_by!(&.number)
      top_level_keys = sorted.reject { |k| compression_pool.object_stream_objects.includes?(k) }
      top_level_keys.each do |key|
        obj = key_objects[key]
        next unless obj
        pos = @destination.pos.to_i64
        xref_entries << XRefEntry.new(pos, 0_i64, :in_use)
        @destination << key.number << " 0 obj\n"
        write_indirect_object(obj, cos_writer, object_keys, object_wrapper, key)
        @destination << "\nendobj\n"
      end

      write_xref_stream(xref_entries, catalog, trailer, object_keys)
    end

    # Write using standard xref table (PDF 1.4 compatible).
    private def write_standard(cos_writer : COSWriter,
                               catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                               trailer : Pdfbox::Cos::Dictionary?) : Nil
      # Collect all indirect objects via BFS
      object_keys = {} of UInt64 => Pdfbox::Cos::ObjectKey
      key_objects = {} of Pdfbox::Cos::ObjectKey => Pdfbox::Cos::Base
      object_wrapper = {} of UInt64 => UInt64

      roots = build_roots(catalog)
      collect_objects(roots, object_keys, key_objects, object_wrapper)
      object_wrapper.each do |wrapper_id, inner_id|
        if inner_key = object_keys[inner_id]?
          object_keys[wrapper_id] = inner_key
        end
      end

      xref_entries = [] of XRefEntry
      xref_entries << XRefEntry.new(0_i64, 65535_i64, :free)

      # Write objects sorted by object number
      sorted = key_objects.keys.sort_by!(&.number)
      sorted.each do |key|
        obj = key_objects[key]
        next unless obj
        pos = @destination.pos.to_i64
        xref_entries << XRefEntry.new(pos, 0_i64, :in_use)
        @destination << key.number << " 0 obj\n"
        write_indirect_object(obj, cos_writer, object_keys, object_wrapper, key)
        @destination << "\nendobj\n"
      end

      # Write xref and trailer
      write_xref_and_trailer(xref_entries, catalog, trailer, object_keys, cos_writer)
    end

    private def build_roots(catalog : Pdfbox::Pdmodel::DocumentCatalog?) : Array(Pdfbox::Cos::Base)
      roots = [] of Pdfbox::Cos::Base
      if catalog
        roots << catalog.cos_object
      end
      @document.pages.each do |page|
        if page_dict = page.cos_object
          roots << page_dict
        end
      end
      roots
    end

    private def collect_objects(roots : Array(Pdfbox::Cos::Base),
                                object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                key_objects : Hash(Pdfbox::Cos::ObjectKey, Pdfbox::Cos::Base),
                                object_wrapper : Hash(UInt64, UInt64)) : Nil
      next_obj = 1_i64
      queue = Deque(Pdfbox::Cos::Base).new
      roots.each { |root_item| queue << root_item }

      until queue.empty?
        current = queue.shift
        if current.is_a?(Pdfbox::Cos::Object)
          if inner = current.object
            object_wrapper[current.object_id.to_u64] = inner.object_id.to_u64
            actual = inner
          else
            next
          end
        else
          actual = current
        end

        case actual
        when Pdfbox::Cos::Name, Pdfbox::Cos::String, Pdfbox::Cos::Integer,
             Pdfbox::Cos::Float, Pdfbox::Cos::Boolean, Pdfbox::Cos::Null
          next
        end

        id = actual.object_id.to_u64
        if object_keys.has_key?(id)
          next
        end

        obj_key = Pdfbox::Cos::ObjectKey.new(next_obj, 0_i64)
        object_keys[id] = obj_key
        key_objects[obj_key] = actual
        next_obj += 1

        case actual
        when Pdfbox::Cos::Dictionary
          actual.entries.each_value { |val| queue << val }
        when Pdfbox::Cos::Array
          actual.items.each { |item| queue << item }
        when Pdfbox::Cos::Stream
          actual.entries.each_value { |val| queue << val }
        end
      end
    end

    private def write_indirect_object(obj : Pdfbox::Cos::Base,
                                      cos_writer : COSWriter,
                                      object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                      object_wrapper : Hash(UInt64, UInt64),
                                      key : Pdfbox::Cos::ObjectKey) : Nil
      case obj
      when Pdfbox::Cos::Stream
        cos_writer.write_stream(obj, key.number, key.generation)
      when Pdfbox::Cos::Dictionary
        write_dictionary_with_refs(obj, object_keys, object_wrapper)
      when Pdfbox::Cos::Array
        write_array_with_refs(obj, object_keys, object_wrapper)
      else
        cos_writer.write(obj)
      end
    end

    private def write_xref_and_trailer(xref_entries : Array(XRefEntry),
                                       catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                       trailer : Pdfbox::Cos::Dictionary?,
                                       object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                       cos_writer : COSWriter) : Nil
      if @use_xref_streams && @parameters.compress?
        write_xref_stream(xref_entries, catalog, trailer, object_keys)
      elsif @use_xref_streams
        write_xref_table(xref_entries, catalog, trailer, object_keys, cos_writer)
      else
        write_xref_table(xref_entries, catalog, trailer, object_keys, cos_writer)
      end
    end

    # PDF 1.5+ cross-reference stream (enables compressed object streams).
    private def write_xref_stream(xref_entries : Array(XRefEntry),
                                  catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                  trailer : Pdfbox::Cos::Dictionary?,
                                  object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey)) : Nil
      xref_dict = Pdfbox::Cos::Dictionary.new
      xref_dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("XRef")
      xref_dict.set_int(Pdfbox::Cos::Name.new("Size"), xref_entries.size.to_i64)

      w_array = Pdfbox::Cos::Array.new
      w_array << Pdfbox::Cos::Integer.new(1_i64)
      w_array << Pdfbox::Cos::Integer.new(4_i64)
      w_array << Pdfbox::Cos::Integer.new(1_i64)
      xref_dict[Pdfbox::Cos::Name.new("W")] = w_array

      if catalog
        if cat_key = object_keys[catalog.cos_object.object_id.to_u64]?
          xref_dict[Pdfbox::Cos::Name.new("Root")] = ref_obj(cat_key)
        end
      end

      if trailer
        if info_val = trailer[Pdfbox::Cos::Name.new("Info")]?
          info_base = info_val.is_a?(Pdfbox::Cos::Object) ? info_val.object : info_val
          if info_base && (info_key = object_keys[info_base.object_id.to_u64]?)
            xref_dict[Pdfbox::Cos::Name.new("Info")] = ref_obj(info_key)
          end
        end
        if id_val = trailer[Pdfbox::Cos::Name.new("ID")]?
          xref_dict[Pdfbox::Cos::Name.new("ID")] = id_val
        end
      end

      data_io = ::IO::Memory.new
      xref_entries.each do |entry|
        case entry.type
        when :free
          data_io.write_byte(0_u8)
          xref_write_u32(data_io, entry.offset)
          xref_write_u8(data_io, entry.generation)
        when :in_use
          data_io.write_byte(1_u8)
          xref_write_u32(data_io, entry.offset)
          xref_write_u8(data_io, entry.generation)
        when :compressed
          data_io.write_byte(2_u8)
          xref_write_u32(data_io, entry.offset)      # object stream number
          xref_write_u8(data_io, entry.objstm_index) # index within stream
        end
      end

      xref_stream = Pdfbox::Cos::Stream.new
      xref_stream.entries.merge!(xref_dict.entries)
      xref_stream.data = data_io.to_slice

      stream_key = Pdfbox::Cos::ObjectKey.new(xref_entries.size.to_i64, 0_i64)
      pos = @destination.pos.to_i64
      @destination << stream_key.number << " 0 obj\n"
      @destination << "<<\n"
      xref_dict.entries.each do |key, value|
        @destination << '/' << key.value << ' '
        if value.is_a?(Pdfbox::Cos::Name) || value.is_a?(Pdfbox::Cos::Integer)
          value.write_pdf(@destination)
        elsif value.is_a?(Pdfbox::Cos::Array)
          @destination << '['
          value.items.each_with_index do |item, idx|
            item.write_pdf(@destination)
            @destination << ' ' if idx < value.size - 1
          end
          @destination << ']'
        elsif value.is_a?(Pdfbox::Cos::Object)
          @destination << value.object_number << ' ' << value.generation_number << " R"
        else
          value.write_pdf(@destination)
        end
        @destination << "\n"
      end
      @destination << ">>\n"
      @destination << "stream\n"
      @destination.write(data_io.to_slice)
      @destination << "\nendstream\n"
      @destination << "endobj\n"
      @destination << "startxref\n"
      @destination << pos << "\n"
      @destination << "%%EOF\n"
    end

    # Traditional PDF xref table + trailer.
    private def write_xref_table(xref_entries : Array(XRefEntry),
                                 catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                 trailer : Pdfbox::Cos::Dictionary?,
                                 object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                 cos_writer : COSWriter) : Nil
      xref_start = @destination.pos.to_i64
      @destination << "xref\n"
      @destination << "0 " << xref_entries.size << "\n"
      xref_entries.each do |entry|
        @destination << entry.offset.to_s.rjust(10, '0') << ' '
        @destination << entry.generation.to_s.rjust(5, '0') << ' '
        @destination << (entry.type == :in_use ? "n" : "f") << " \n"
      end

      @destination << "trailer\n"
      @destination << "<<\n"
      @destination << "/Size " << xref_entries.size << "\n"

      if catalog
        if cat_key = object_keys[catalog.cos_object.object_id.to_u64]?
          @destination << "/Root " << cat_key.number << " 0 R\n"
        end
      end

      if trailer
        if info_val = trailer[Pdfbox::Cos::Name.new("Info")]?
          info_base = info_val.is_a?(Pdfbox::Cos::Object) ? info_val.object : info_val
          if info_base && (info_key = object_keys[info_base.object_id.to_u64]?)
            @destination << "/Info " << info_key.number << " 0 R\n"
          end
        end
        if id_val = trailer[Pdfbox::Cos::Name.new("ID")]?
          @destination << "/ID "
          cos_writer.write(id_val)
          @destination << "\n"
        end
      end

      @destination << ">>\n"
      @destination << "startxref\n"
      @destination << xref_start << "\n"
      @destination << "%%EOF\n"
    end

    # BFS over the COS graph starting from root, collecting objects that should
    # be written as indirect objects. Skips scalars (names, strings, numbers, booleans, null).
    # Write a COS dictionary, converting tracked objects to indirect references.
    private def write_dictionary_with_refs(dict : Pdfbox::Cos::Dictionary,
                                           object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                           object_wrapper : Hash(UInt64, UInt64)) : Nil
      @destination << "<<\n"
      dict.entries.each do |key, value|
        @destination << '/' << key.value << ' '
        write_value_with_refs(value, object_keys, object_wrapper)
        @destination << "\n"
      end
      @destination << ">>"
    end

    # Write a COS array, converting tracked objects to indirect references.
    private def write_array_with_refs(array : Pdfbox::Cos::Array,
                                      object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                      object_wrapper : Hash(UInt64, UInt64)) : Nil
      @destination << '['
      array.items.each_with_index do |item, idx|
        write_value_with_refs(item, object_keys, object_wrapper)
        @destination << ' ' if idx < array.size - 1
      end
      @destination << ']'
    end

    # Write a COS value, checking object_keys for indirect reference resolution.
    private def write_value_with_refs(value : Pdfbox::Cos::Base,
                                      object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                      object_wrapper : Hash(UInt64, UInt64)) : Nil
      case value
      when Pdfbox::Cos::Object
        inner = value.object
        if inner
          lookup_id = inner.object_id.to_u64
          if key = object_keys[lookup_id]?
            @destination << key.number << " 0 R"
            return
          end
        end
        # Fallback to writing the inner value inline
        if inner
          write_value_with_refs(inner, object_keys, object_wrapper)
        else
          @destination << "null"
        end
      when Pdfbox::Cos::Dictionary
        # Check if this dictionary has an object number
        lookup_id = value.object_id.to_u64
        if key = object_keys[lookup_id]?
          @destination << key.number << " 0 R"
        else
          write_dictionary_with_refs(value, object_keys, object_wrapper)
        end
      when Pdfbox::Cos::Array
        lookup_id = value.object_id.to_u64
        if key = object_keys[lookup_id]?
          @destination << key.number << " 0 R"
        else
          write_array_with_refs(value, object_keys, object_wrapper)
        end
      when Pdfbox::Cos::Stream
        lookup_id = value.object_id.to_u64
        if key = object_keys[lookup_id]?
          @destination << key.number << " 0 R"
        else
          raise WriteError.new("Stream should have been collected")
        end
      when Pdfbox::Cos::String
        write_pdf_string(@destination, value.bytes, value.force_hex_form?)
      when Pdfbox::Cos::Name
        @destination << '/' << value.value
      when Pdfbox::Cos::Integer
        @destination << value.value
      when Pdfbox::Cos::Float
        @destination << value.value
      when Pdfbox::Cos::Boolean
        @destination << (value.value ? "true" : "false")
      when Pdfbox::Cos::Null
        @destination << "null"
      else
        @destination << "null"
      end
    end

    private def write_pdf_string(io : ::IO, bytes : Bytes, hex : Bool = false) : Nil
      is_ascii = !hex && bytes.all? { |b| b < 0x80_u8 && b != 0x0d_u8 && b != 0x0a_u8 }
      if hex || !is_ascii
        io << '<'
        bytes.each { |b| io << b.to_s(16).upcase.rjust(2, '0') }
        io << '>'
      else
        io << '('
        bytes.each do |b|
          case b
          when '('.ord, ')'.ord, '\\'.ord then io << '\\' << b.chr
          else                                 io.write_byte(b)
          end
        end
        io << ')'
      end
    end

    private def header_version_for_write : String
      current_header = @document.header_version.to_f32? || 1.4_f32
      return format_version(Math.max(current_header, 1.6_f32)) if @parameters.compress?
      @document.header_version
    end

    private def format_version(value : Float32) : String
      "%.1f" % value
    end

    def write(password : String) : Nil
    end

    def write_incremental : Nil
    end

    def compression=(level : Int32) : Int32
      level
    end

    def encryption=(enabled : Bool) : Bool
      enabled
    end

    private def ref_obj(key : Pdfbox::Cos::ObjectKey) : Pdfbox::Cos::Object
      Pdfbox::Cos::Object.new(key.number, key.generation, nil)
    end

    private def xref_write_u32(io : ::IO, value : Int64) : Nil
      io.write_bytes(value.to_u32, ::IO::ByteFormat::BigEndian)
    end

    private def xref_write_u8(io : ::IO, value : Int64) : Nil
      io.write_byte((value & 0xFF).to_u8)
    end
  end

  # COS object writer
  class COSWriter
    # PDF token byte sequences (Java COSWriter constants)
    DICT_OPEN   = "<<".to_slice
    DICT_CLOSE  = ">>".to_slice
    SPACE       = Bytes[32_u8]
    ARRAY_OPEN  = "[".to_slice
    ARRAY_CLOSE = "]".to_slice
    REFERENCE   = "R".to_slice
    OBJ         = "obj".to_slice
    ENDOBJ      = "endobj".to_slice
    STREAM      = "stream".to_slice
    ENDSTREAM   = "endstream".to_slice
    XREF        = "xref".to_slice
    TRAILER     = "trailer".to_slice
    STARTXREF   = "startxref".to_slice
    EOF         = "%%EOF".to_slice

    @destination : ::IO
    @will_encrypt : Bool = false
    @security_handler : Pdfbox::Pdmodel::Encryption::SecurityHandler?

    def initialize(@destination : ::IO, @will_encrypt : Bool = false, @security_handler : Pdfbox::Pdmodel::Encryption::SecurityHandler? = nil)
    end

    # Write a COS object
    def write(object : Pdfbox::Cos::Base) : Nil
      case object
      when Pdfbox::Cos::Stream
        write_stream(object)
      when Pdfbox::Cos::Dictionary
        write_dictionary(object)
      when Pdfbox::Cos::Array
        write_array(object)
      when Pdfbox::Cos::String
        write_string(object)
      when Pdfbox::Cos::Name
        write_name(object)
      when Pdfbox::Cos::Integer, Pdfbox::Cos::Float
        write_number(object)
      when Pdfbox::Cos::Boolean
        write_boolean(object)
      when Pdfbox::Cos::Null
        write_null(object)
      when Pdfbox::Cos::Object
        write_object_reference(object)
      else
        raise WriteError.new("Unsupported COS object type: #{object.class}")
      end
    end

    # Write a COS dictionary
    def write_dictionary(dict : Pdfbox::Cos::Dictionary) : Nil
      @destination << "<<"
      dict.entries.each do |key, value|
        write_name(key)
        PDFIO.write_whitespace(@destination)
        write(value)
        PDFIO.write_whitespace(@destination)
      end
      @destination << ">>"
    end

    # Write a COS array
    def write_array(array : Pdfbox::Cos::Array) : Nil
      @destination << '['
      array.items.each_with_index do |item, index|
        write(item)
        if index < array.size - 1
          PDFIO.write_whitespace(@destination)
        end
      end
      @destination << ']'
    end

    # Write a COS string
    def write_string(string : Pdfbox::Cos::String) : Nil
      PDFIO.write_string(@destination, string.bytes, string.force_hex_form?)
    end

    # Write a COS name
    def write_name(name : Pdfbox::Cos::Name) : Nil
      PDFIO.write_name(@destination, name.value)
    end

    # Write a COS number
    def write_number(number : Pdfbox::Cos::Integer | Pdfbox::Cos::Float) : Nil
      PDFIO.write_number(@destination, number.value)
    end

    # Write a COS boolean
    def write_boolean(boolean : Pdfbox::Cos::Boolean) : Nil
      @destination << (boolean.value ? "true" : "false")
    end

    # Write a COS null
    def write_null(null : Pdfbox::Cos::Null) : Nil
      @destination << "null"
    end

    # Write a COS stream
    def write_stream(stream : Pdfbox::Cos::Stream, obj_num : Int64 = 0_i64, gen_num : Int64 = 0_i64) : Nil
      # Encrypt stream if needed
      if @will_encrypt && (handler = @security_handler)
        handler.encrypt_stream(stream, obj_num, gen_num)
      end

      stream[Pdfbox::Cos::Name::LENGTH] = Pdfbox::Cos::Integer.new(stream.data.size)

      # Write stream dictionary
      write_dictionary(stream)
      @destination << '\n' << "stream" << '\n'
      @destination.write(stream.data)
      @destination << '\n' << "endstream"
    end

    # Write a COS object reference, resolving from object_keys if possible
    def write_object_reference(ref : Pdfbox::Cos::Object) : Nil
      obj_num = ref.object_number
      gen_num = ref.generation_number
      # If the COSObject has a real object_number (from parsing), use it.
      # Otherwise try to resolve from object_keys_map if available
      @destination << obj_num << ' ' << gen_num << " R"
    end
  end

  # Writes parsed content stream tokens back into a content stream.
  # Ported from Apache PDFBox ContentStreamWriter.
  class ContentStreamWriter
    include Pdfbox::ContentStream::OperatorName

    SPACE = Bytes[32_u8]
    EOL   = Bytes[0x0A_u8]

    def initialize(@output : ::IO)
    end

    def write_token(token : Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator) : Nil
      write_object(token)
    end

    def write_tokens(*tokens : Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator) : Nil
      tokens.each { |token| write_object(token) }
      @output.write(EOL)
    end

    def write_tokens(tokens : Array(Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)) : Nil
      tokens.each { |token| write_object(token) }
    end

    private def write_object(token : Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator) : Nil
      case token
      in Pdfbox::Cos::Base
        write_operand(token)
      in Pdfbox::ContentStream::Operator
        write_operator(token)
      end
    end

    private def write_operator(op : Pdfbox::ContentStream::Operator) : Nil
      if op.name == BEGIN_INLINE_IMAGE
        @output << BEGIN_INLINE_IMAGE
        @output.write(EOL)
        parameters = op.image_parameters || Pdfbox::Cos::Dictionary.new
        parameters.entries.each do |key, value|
          key.write_pdf(@output)
          @output.write(SPACE)
          write_operand(value)
          @output.write(EOL)
        end
        @output << BEGIN_INLINE_IMAGE_DATA
        @output.write(EOL)
        @output.write(op.image_data || Bytes.empty)
        @output.write(EOL)
        @output << END_INLINE_IMAGE
        @output.write(EOL)
      else
        @output << op.name
        @output.write(EOL)
      end
    end

    private def write_operand(operand : Pdfbox::Cos::Base) : Nil
      operand.write_pdf(@output)
      @output.write(SPACE)
    end
  end

  # Cross-reference table writer
  class XRefWriter
    @destination : ::IO
    @entries = [] of XRefEntry

    def initialize(@destination : ::IO)
    end

    # Add an entry to the xref table
    def add_entry(offset : Int64, generation : Int64, type : Symbol) : XRefEntry
      entry = XRefEntry.new(offset, generation, type)
      @entries << entry
      entry
    end

    # Write the xref table
    def write : Nil
      @destination << "xref\n"

      # Group entries by consecutive object numbers starting from 0
      # We assume entries were added in order of object numbers
      start = 0
      count = @entries.size

      # Write subsection header
      @destination << start << ' ' << count << '\n'

      @entries.each do |entry|
        # Format offset as 10-digit zero-padded
        @destination << entry.offset.to_s.rjust(10, '0')
        @destination << ' '
        # Format generation as 5-digit zero-padded
        @destination << entry.generation.to_s.rjust(5, '0')
        @destination << ' '
        @destination << (entry.type == :in_use ? 'n' : 'f')
        @destination << '\n'
      end
    end

    # Get number of entries
    def size : Int32
      @entries.size
    end
  end

  # Cross-reference table entry
  class XRefEntry
    @offset : Int64
    @generation : Int64
    @type : Symbol
    @objstm_index : Int64

    # Create a normal xref entry (type :free or :in_use)
    def initialize(@offset : Int64, @generation : Int64, @type : Symbol)
      @objstm_index = 0_i64
    end

    # Create a compressed xref entry (type :compressed)
    def initialize(objstm_number : Int64, objstm_index : Int64)
      @offset = objstm_number
      @generation = 0_i64
      @type = :compressed
      @objstm_index = objstm_index
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

    def objstm_index : Int64
      @objstm_index
    end
  end

  # Utility for writing PDF-specific data types
  module PDFIO
    # Write a PDF string (literal or hexadecimal)
    def self.write_string(io : ::IO, string : String, hex : Bool = false) : Nil
      write_string(io, string.to_slice, hex)
    end

    def self.write_string(io : ::IO, bytes : Bytes, hex : Bool = false) : Nil
      is_ascii = !hex && bytes.all? { |byte| byte < 0x80_u8 && byte != 0x0d_u8 && byte != 0x0a_u8 }

      if hex || !is_ascii
        io << '<'
        bytes.each do |byte|
          io << byte.to_s(16).upcase.rjust(2, '0')
        end
        io << '>'
      else
        io << '('
        bytes.each do |byte|
          case byte
          when '('.ord
            io << '\\' << '('
          when ')'.ord
            io << '\\' << ')'
          when '\\'.ord
            io << '\\' << '\\'
          else
            io.write_byte(byte)
          end
        end
        io << ')'
      end
    end

    # Write a PDF name
    def self.write_name(io : ::IO, name : String) : Nil
      io << '/'
      # Escape special characters in names
      name.each_char do |char|
        case char
        when ' ', '\t', '\n', '\r', '\f', '(', ')', '<', '>', '[', ']', '{', '}', '/', '%', '#'
          # Write as hex escape
          io << '#' << char.ord.to_s(16).upcase.rjust(2, '0')
        else
          io << char
        end
      end
    end

    # Write a PDF number
    def self.write_number(io : ::IO, number : Float64 | Int64) : Nil
      io << number
    end

    # Write a PDF date
    def self.write_date(io : ::IO, date : Time) : Nil
      io << "(D:" << date.to_s("%Y%m%d%H%M%S") << ")"
    end

    # Write PDF whitespace
    def self.write_whitespace(io : ::IO) : Nil
      io << ' '
    end

    # Write PDF comment
    def self.write_comment(io : ::IO, comment : String) : Nil
      io << '%' << comment << '\n'
    end
  end

  # Document information writer
  class DocumentInformationWriter
    @destination : ::IO
    @info : Pdfbox::Cos::Dictionary?

    def initialize(@destination : ::IO, @info : Pdfbox::Cos::Dictionary? = nil)
    end

    # Write document information dictionary
    def write : Nil
      return unless info = @info

      @destination << info.to_s << "\n"
    end

    # Set document title
    def title=(title : String) : String
      if info = @info
        info[Cos::Name.new("Title")] = Cos::String.new(title)
      end
      title
    end

    # Set document author
    def author=(author : String) : String
      if info = @info
        info[Cos::Name.new("Author")] = Cos::String.new(author)
      end
      author
    end

    # Set document subject
    def subject=(subject : String) : String
      if info = @info
        info[Cos::Name.new("Subject")] = Cos::String.new(subject)
      end
      subject
    end

    # Set document keywords
    def keywords=(keywords : String) : String
      if info = @info
        info[Cos::Name.new("Keywords")] = Cos::String.new(keywords)
      end
      keywords
    end

    # Set document creator
    def creator=(creator : String) : String
      if info = @info
        info[Cos::Name.new("Creator")] = Cos::String.new(creator)
      end
      creator
    end

    # Set document producer
    def producer=(producer : String) : String
      if info = @info
        info[Cos::Name.new("Producer")] = Cos::String.new(producer)
      end
      producer
    end

    # Set creation date
    def creation_date=(date : Time) : Time
      if info = @info
        date_str = "D:" + date.to_s("%Y%m%d%H%M%S")
        info[Cos::Name.new("CreationDate")] = Cos::String.new(date_str)
      end
      date
    end

    # Set modification date
    def modification_date=(date : Time) : Time
      if info = @info
        date_str = "D:" + date.to_s("%Y%m%d%H%M%S")
        info[Cos::Name.new("ModDate")] = Cos::String.new(date_str)
      end
      date
    end
  end
end
