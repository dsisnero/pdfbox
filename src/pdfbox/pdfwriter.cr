# PDF Writer module for PDFBox Crystal
#
# This module contains PDF writing functionality,
# corresponding to the pdfwriter package in Apache PDFBox.
require "./cos"
require "./content_stream/operator"
require "./content_stream/missing_operand_exception"
require "./content_stream/empty_graphics_stack_exception"
require "./content_stream/operator_name"
require "./pdfwriter/compress"

module Pdfbox::Pdfwriter
  # Base class for PDF writing errors
  class WriteError < Pdfbox::PDFError; end

  # Raised when PDF cannot be written
  class IOException < WriteError; end

  # Raised when encryption fails
  class EncryptionError < WriteError; end

  # Simple output stream with some minor features for generating "pretty" PDF
  # files. Port of org.apache.pdfbox.pdfwriter.COSStandardOutputStream.
  class COSStandardOutputStream < ::IO
    # To be used when a 2-byte sequence is enforced.
    CRLF = Bytes[0x0D, 0x0A]
    # Line feed character.
    LF = Bytes[0x0A]
    # Standard line separator.
    EOL = Bytes[0x0A]

    @out : ::IO
    @position : Int64
    @on_new_line : Bool

    def initialize(@out : ::IO, @position : Int64 = 0_i64)
      @on_new_line = false
    end

    # The current position in the stream.
    def position : Int64
      @position
    end

    # Whether we are on a newline.
    def on_new_line? : Bool
      @on_new_line
    end

    # Set the newline flag.
    def on_new_line=(new_on_new_line : Bool) : Bool
      @on_new_line = new_on_new_line
    end

    def read(slice : Bytes) : Int32
      raise ::IO::Error.new("COSStandardOutputStream is write-only")
    end

    def write(slice : Bytes) : Nil
      @on_new_line = false
      @out.write(slice)
      @position += slice.size
    end

    def write(slice : Bytes, offset : Int32, length : Int32) : Nil
      @on_new_line = false
      @out.write(slice[offset, length])
      @position += length
    end

    def write_byte(byte : UInt8) : Nil
      @on_new_line = false
      @out.write_byte(byte)
      @position += 1
    end

    # Writes a CRLF to the stream.
    def write_crlf : Nil
      write(CRLF)
    end

    # Writes an EOL to the stream, unless already on a newline.
    def write_eol : Nil
      unless on_new_line?
        write(EOL)
        @on_new_line = true
      end
    end

    # Writes a LF to the stream.
    def write_lf : Nil
      write(LF)
    end
  end

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
    @current_object_key : Pdfbox::Cos::ObjectKey?
    @encryption_object_ids : Set(UInt64)?
    @use_xref_streams : Bool = true

    # External-signature bookkeeping, ported from COSWriter's signatureOffset,
    # signatureLength, byteRangeOffset, byteRangeLength, byteRangeArray,
    # incrementPart and incrementalInput. Positions are absolute offsets in the
    # final file (the source bytes plus the appended revision).
    @signature_tracking = false
    @reached_signature = false
    @signature_base = 0_i64
    @signature_offset = 0_i64
    @signature_length = 0_i64
    @byte_range_offset = 0_i64
    @byte_range_length = 0_i64
    @byte_range_array : Pdfbox::Cos::Array?
    @signing_source : Bytes?
    @signing_increment : Bytes?
    @signing_start_xref = 0_i64
    @signing_highest_number = 0_i64

    def initialize(@destination : ::IO, @document : Pdfbox::Pdmodel::Document, @parameters : Pdfbox::Pdfwriter::Compress::CompressParameters = Pdfbox::Pdfwriter::Compress::CompressParameters::DEFAULT_COMPRESSION)
      if @document.all_security_to_be_removed?
        # Matching Java COSWriter: when security is to be removed, do not
        # encrypt and do not write an /Encrypt entry.
        @will_encrypt = false
        @security_handler = nil
      elsif encryption = @document.encryption
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

      trailer = @document.trailer || Pdfbox::Cos::Dictionary.new
      catalog = @document.document_catalog

      ensure_document_id(trailer)

      if @use_xref_streams && @parameters.compress?
        write_compressed(cos_writer, catalog, trailer)
      else
        write_standard(cos_writer, catalog, trailer)
      end
    end

    # Generate a document ID for the trailer if missing, matching the behavior
    # of Apache PDFBox COSWriter. Reuses the document's existing ID (e.g. one
    # computed during encryption preparation or loaded from the source trailer);
    # otherwise generates a SHA-256 of the current time plus the values of the
    # Info dictionary, if present.
    private def ensure_document_id(trailer : Pdfbox::Cos::Dictionary) : Nil
      id_val = trailer[Pdfbox::Cos::Name.new("ID")]
      return if id_val.is_a?(Pdfbox::Cos::Array) && id_val.size == 2

      if doc_id = @document.document_id
        id_array = Pdfbox::Cos::Array.new
        id_array << Pdfbox::Cos::String.new(doc_id)
        id_array << Pdfbox::Cos::String.new(doc_id)
        trailer[Pdfbox::Cos::Name.new("ID")] = id_array
        return
      end

      digest = document_id_digest(trailer)
      id_array = Pdfbox::Cos::Array.new
      id_array << Pdfbox::Cos::String.new(digest)
      id_array << Pdfbox::Cos::String.new(digest)
      trailer[Pdfbox::Cos::Name.new("ID")] = id_array
    end

    # SHA-256 of the current time plus the values of the /Info dictionary, as
    # used by Java COSWriter for both the initial /ID and the second /ID value of
    # an incremental update.
    private def document_id_digest(trailer : Pdfbox::Cos::Dictionary) : Bytes
      sha256 = Digest::SHA256.new
      # Java COSWriter uses pdDocument.getDocumentId() when set, so that repeated
      # saves of the same document produce a stable /ID.
      seed = @document.document_id_seed
      sha256.update((seed || Time.utc.to_unix_ms).to_s)

      if info_val = trailer[Pdfbox::Cos::Name.new("Info")]?
        info_base = info_val.is_a?(Pdfbox::Cos::Object) ? info_val.object : info_val
        if info_base.is_a?(Pdfbox::Cos::Dictionary)
          info_base.entries.each_value do |cos_base|
            sha256.update(cos_base.to_s)
          end
        end
      end

      sha256.final
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
      roots = build_roots(catalog, trailer)
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

      roots = build_roots(catalog, trailer)
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

    private def build_roots(catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                            trailer : Pdfbox::Cos::Dictionary? = nil) : Array(Pdfbox::Cos::Base)
      roots = [] of Pdfbox::Cos::Base
      if catalog
        roots << catalog.cos_object
      end
      @document.pages.each do |page|
        if page_dict = page.cos_object
          roots << page_dict
        end
      end
      if (encryption = @document.encryption) && !@document.all_security_to_be_removed?
        roots << encryption.dictionary
      end
      if trailer && (info_val = trailer[Pdfbox::Cos::Name.new("Info")]?)
        info_base = info_val.is_a?(Pdfbox::Cos::Object) ? info_val.object : info_val
        roots << info_base if info_base
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

    # Object ids reachable from the document's encryption dictionary. These are
    # written without encryption (the encryption dictionary itself, plus values
    # such as the public key /Recipients array that may be hoisted into their
    # own indirect objects by `collect_objects`).
    private def encryption_object_ids : Set(UInt64)
      @encryption_object_ids ||= begin
        ids = Set(UInt64).new
        if encryption = @document.encryption
          stack = [encryption.dictionary.as(Pdfbox::Cos::Base)]
          until stack.empty?
            node = stack.pop
            next unless ids.add?(node.object_id.to_u64)

            case node
            when Pdfbox::Cos::Dictionary
              node.entries.each_value { |value| stack << value }
            when Pdfbox::Cos::Array
              node.items.each { |item| stack << item }
            when Pdfbox::Cos::Stream
              node.entries.each_value { |value| stack << value }
            end
          end
        end
        ids
      end
    end

    private def write_indirect_object(obj : Pdfbox::Cos::Base,
                                      cos_writer : COSWriter,
                                      object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                      object_wrapper : Hash(UInt64, UInt64),
                                      key : Pdfbox::Cos::ObjectKey) : Nil
      # The encryption dictionary and everything reachable from it (e.g. the
      # /Recipients array for public key encryption) is written without
      # encrypting its strings/streams, matching Java COSWriter which sets
      # willEncrypt = false for the encryption dictionary.
      is_encryption_dict = encryption_object_ids.includes?(obj.object_id.to_u64)
      object_key = @will_encrypt && !is_encryption_dict ? key : nil
      @current_object_key = object_key
      cos_writer.current_object_key = object_key

      case obj
      when Pdfbox::Cos::Stream
        write_stream_with_refs(obj, cos_writer, object_keys, object_wrapper, key)
      when Pdfbox::Cos::Dictionary
        write_dictionary_with_refs(obj, object_keys, object_wrapper)
      when Pdfbox::Cos::Array
        write_array_with_refs(obj, object_keys, object_wrapper)
      else
        cos_writer.write(obj)
      end

      @current_object_key = nil
      cos_writer.current_object_key = nil
    end

    # Write a stream, remapping its dictionary's indirect references through
    # object_keys. Non-reference values are written via the COSWriter in the
    # same single-line format as COSWriter.write_stream, so that the output is
    # byte-identical to the previous behavior except for references, which are
    # now remapped to the reassigned object numbers.
    private def write_stream_with_refs(stream : Pdfbox::Cos::Stream,
                                       cos_writer : COSWriter,
                                       object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                       object_wrapper : Hash(UInt64, UInt64),
                                       key : Pdfbox::Cos::ObjectKey) : Nil
      if @will_encrypt && (handler = @security_handler)
        handler.encrypt_stream(stream, key.number, key.generation)
      end

      stream[Pdfbox::Cos::Name::LENGTH] = Pdfbox::Cos::Integer.new(stream.data.size)

      @destination << "<<"
      stream.entries.each do |dict_key, value|
        cos_writer.write_name(dict_key)
        PDFIO.write_whitespace(@destination)
        write_stream_value_with_refs(value, cos_writer, object_keys, object_wrapper)
        PDFIO.write_whitespace(@destination)
      end
      @destination << ">>"
      @destination << '\n' << "stream" << '\n'
      @destination.write(stream.data)
      @destination << '\n' << "endstream"
    end

    # Write a stream dictionary value, remapping indirect references through
    # object_keys. Non-reference values are delegated to the COSWriter so the
    # output matches COSWriter.write_stream exactly.
    private def write_stream_value_with_refs(value : Pdfbox::Cos::Base,
                                             cos_writer : COSWriter,
                                             object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                             object_wrapper : Hash(UInt64, UInt64)) : Nil
      case value
      when Pdfbox::Cos::Object
        inner = value.object
        if inner
          lookup_id = inner.object_id.to_u64
          if key = object_keys[lookup_id]?
            @destination << key.number << ' ' << key.generation << " R"
            return
          end
        end
        # Fall back to the original reference number
        @destination << value.object_number << ' ' << value.generation_number << " R"
      when Pdfbox::Cos::Dictionary, Pdfbox::Cos::Array
        # A direct dictionary/array nested in a stream dictionary (e.g. a form
        # XObject's /Resources) still has an object key, so it must be written
        # as an indirect reference: streams may never be direct objects.
        write_value_with_refs(value, object_keys, object_wrapper)
      else
        cos_writer.write(value)
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

      if (encryption = @document.encryption) && !@document.all_security_to_be_removed?
        enc_id = encryption.dictionary.object_id.to_u64
        if enc_key = object_keys[enc_id]?
          xref_dict[Pdfbox::Cos::Name.new("Encrypt")] = ref_obj(enc_key)
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

      # The stream has no /Filter, so /Length is the decoded size. Required for
      # readers to find the end of the cross-reference stream (an incremental
      # save chains off documents written by this writer).
      xref_dict.set_int(Pdfbox::Cos::Name.new("Length"), data_io.size)

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

      if (encryption = @document.encryption) && !@document.all_security_to_be_removed?
        enc_id = encryption.dictionary.object_id.to_u64
        if enc_key = object_keys[enc_id]?
          @destination << "/Encrypt " << enc_key.number << " 0 R\n"
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
      detect_possible_signature(dict) if @signature_tracking
      @destination << "<<\n"
      dict.entries.each do |key, value|
        @destination << '/' << key.value << ' '
        if @signature_tracking && @reached_signature
          # While writing the signature dictionary itself, remember where the
          # /Contents value and the /ByteRange array land (Java visitFromDictionary).
          if key.value == "Contents"
            @signature_offset = absolute_position
            write_value_with_refs(value, object_keys, object_wrapper)
            @signature_length = absolute_position - @signature_offset
            @destination << "\n"
            next
          elsif key.value == "ByteRange" && value.is_a?(Pdfbox::Cos::Array)
            @byte_range_array = value
            @byte_range_offset = absolute_position
            # Written inline: the reserved /ByteRange must be patched in place, so
            # it may not become an indirect reference.
            write_array_with_refs(value, object_keys, object_wrapper)
            @byte_range_length = absolute_position - @byte_range_offset
            @reached_signature = false
            @destination << "\n"
            next
          end
        end
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
            @destination << key.number << ' ' << key.generation << " R"
            return
          end
        end
        # Fallback to writing the inner value inline
        if inner
          write_value_with_refs(inner, object_keys, object_wrapper)
        else
          @destination << "null"
        end
      when Pdfbox::Cos::Stream
        # Must come before Dictionary: a Stream is a Dictionary, and a stream may
        # never be written as a direct object.
        lookup_id = value.object_id.to_u64
        if key = object_keys[lookup_id]?
          @destination << key.number << " 0 R"
        else
          raise WriteError.new("Stream should have been collected")
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
      when Pdfbox::Cos::String
        write_encrypted_string(value)
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

    # Write a COS string, encrypting it when writing an encrypted document.
    private def write_encrypted_string(string : Pdfbox::Cos::String) : Nil
      if @will_encrypt && (handler = @security_handler) && (key = @current_object_key)
        string = handler.encrypt_string(string, key.number, key.generation)
      end
      write_pdf_string(@destination, string.bytes, string.force_hex_form?)
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

    # Appends an incremental update to the bytes the document was loaded from,
    # following Java COSWriter's incremental constructor (no compressed object
    # streams, output positioned right after the source) and doWriteXRefInc (a
    # new cross-reference section whose /Prev points at the source startxref,
    # written as an xref stream when the source used one and as a classic xref
    # table otherwise).
    #
    # The objects of the appended revision are collected the same way Java does
    # it (COSWriter#write):
    #   trailer.toIncrement().exclude(trailer)
    # so only the structures flagged through COSUpdateState are rewritten.
    #
    # Divergences (documented in plans/parity.md):
    #  - Java writes the increment and lets COSWriter emit direct structures
    #    inline; this writer allocates an object number for every structure, so
    #    the objects created in this session are written as top level objects
    #    too instead of being inlined.
    #  - documents that are still encrypted, and documents that were not loaded
    #    from bytes, fall back to a full save.
    def write_incremental : Nil
      write_incremental([] of Pdfbox::Cos::Dictionary)
    end

    # Incremental save that also writes the given dictionaries, even when nothing
    # is flagged with COSUpdateInfo#setNeedToBeUpdated (Java
    # PDDocument#saveIncremental(OutputStream, Set<COSDictionary>) /
    # COSWriter(OutputStream, RandomAccessRead, Set<COSDictionary>)). Java adds
    # them to the queue of objects to write; this writer adds their ids to the
    # computed write set, which is the same result without a queue.
    def write_incremental(objects_to_write : Enumerable(Pdfbox::Cos::Dictionary)) : Nil
      # Positions are relative to the destination unless a buffered signing save
      # set a source-based base.
      @signature_base = 0_i64
      source = @document.source_bytes
      previous_xref = @document.start_xref
      if source.nil? || previous_xref.nil?
        Log.warn { "Document has no source bytes to append to, falling back to a full save" }
        write
        return
      end
      if @will_encrypt
        Log.warn { "Incremental save of an encrypted document is not supported, falling back to a full save" }
        write
        return
      end

      # Keep the source file verbatim, then append the new revision.
      @destination.write(source)
      # Java COSWriter always writes an EOL here so the appended object can never
      # share a line with the source's %%EOF (PDFBOX-1051).
      @destination << '\n'

      new_start_xref, highest_number = write_incremental_revision(source, previous_xref, objects_to_write)

      # A subsequent incremental save from this in-memory document must chain
      # onto this revision instead of the original one.
      @document.start_xref = new_start_xref
      @document.highest_object_number = highest_number
    end

    # Prepares an incremental revision for external signing (Java
    # PDDocument#saveIncrementalForExternalSigning, which uses COSWriter's
    # incremental constructor). The revision is written into a buffer so that the
    # /ByteRange and /Contents positions can be patched before anything reaches
    # the real output: SigningSupport#content returns the data to sign and
    # SigningSupport#set_signature finishes the file.
    #
    # Unlike #write_incremental this never falls back to a full save: signing a
    # rewritten file would invalidate the byte ranges.
    def write_incremental_for_external_signing : Pdfbox::Pdmodel::Interactive::DigitalSignature::SigningSupport
      source = @document.source_bytes
      previous_xref = @document.start_xref
      if source.nil? || previous_xref.nil?
        raise Pdfbox::Pdmodel::IllegalStateError.new("document was not loaded from a file or a stream")
      end
      if @will_encrypt
        raise Pdfbox::Pdmodel::IllegalStateError.new("incremental signing of an encrypted document is not supported")
      end

      buffer = ::IO::Memory.new
      saved_destination = @destination
      # The revision is written into a buffer, starting with the EOL that Java
      # writes before an appended revision (visitFromDocument, PDFBOX-1051).
      # Absolute positions are the source length plus the buffer position.
      @signature_base = source.size.to_i64
      @signature_tracking = true
      @destination = buffer
      new_start_xref, highest_number = begin
        buffer << '\n'
        write_incremental_revision(source, previous_xref)
      ensure
        @destination = saved_destination
        @signature_tracking = false
        @reached_signature = false
      end

      if @signature_offset.zero? || @byte_range_offset.zero?
        raise Pdfbox::Pdmodel::IllegalStateError.new("PDF not prepared for signing")
      end

      increment = buffer.to_slice.dup
      after_offset = @signature_offset + @signature_length
      after_length = @signature_base + increment.size - after_offset

      # Java doWriteSignature assigns the computed values to the actual COSArray
      # so that the caller can read them back (and restore the reserve value).
      if array = @byte_range_array
        array[0] = Pdfbox::Cos::Integer.new(0_i64)
        array[1] = Pdfbox::Cos::Integer.new(@signature_offset)
        array[2] = Pdfbox::Cos::Integer.new(after_offset)
        array[3] = Pdfbox::Cos::Integer.new(after_length)
      end

      byte_range = "[0 #{@signature_offset} #{after_offset} #{after_length}]"
      if byte_range.bytesize > @byte_range_length
        raise ::IO::Error.new(
          "Can't write new byteRange '#{byte_range}' not enough space: " \
          "byteRange.length(): #{byte_range.bytesize}, byteRangeLength: #{@byte_range_length}, " \
          "byteRangeOffset: #{@byte_range_offset}, inLength: #{source.size}"
        )
      end
      copy_into_increment(increment, @byte_range_offset - @signature_base, byte_range.to_slice,
        @byte_range_length)

      @signing_source = source
      @signing_increment = increment
      @signing_start_xref = new_start_xref
      @signing_highest_number = highest_number
      Pdfbox::Pdmodel::Interactive::DigitalSignature::SigningSupport.new(self)
    end

    # The data a signer has to sign: the whole file with the /Contents hex string
    # cut out (Java COSWriter#getDataToSign).
    def data_to_sign : Bytes
      source = @signing_source
      increment = @signing_increment
      if source.nil? || increment.nil?
        raise Pdfbox::Pdmodel::IllegalStateError.new("PDF not prepared for signing")
      end

      signature_start = (@signature_offset - @signature_base).to_i
      signature_end = signature_start + @signature_length.to_i
      data = ::IO::Memory.new(source.size + increment.size - @signature_length.to_i)
      data.write(source)
      data.write(increment[0, signature_start])
      data.write(increment[signature_end, increment.size - signature_end])
      data.to_slice
    end

    # Writes an externally created CMS signature into the reserved /Contents
    # entry and then emits the file: the source bytes followed by the patched
    # revision (Java COSWriter#writeExternalSignature).
    def write_external_signature(cms_signature : Bytes) : Nil
      source = @signing_source
      increment = @signing_increment
      if source.nil? || increment.nil?
        raise Pdfbox::Pdmodel::IllegalStateError.new("PDF not prepared for setting signature")
      end

      hex = cms_signature.hexstring.upcase
      if hex.bytesize > @signature_length - 2
        raise ::IO::Error.new(
          "Can't write signature, not enough space; " \
          "adjust it with SignatureOptions.setPreferredSignatureSize"
        )
      end

      # /Contents is written as <HEX>, so the digits start one byte after the
      # value itself.
      signature_start = (@signature_offset - @signature_base).to_i + 1
      patched = increment.dup
      hex.to_slice.copy_to(patched.to_unsafe + signature_start, hex.bytesize)

      @destination.write(source)
      @destination.write(patched)

      # The document now carries this revision; a further use of the prepared
      # increment is rejected (Java sets incrementPart = null).
      @document.start_xref = @signing_start_xref
      @document.highest_object_number = @signing_highest_number
      @signing_increment = nil
    end

    # Copies *bytes* into the prepared increment at *offset* and pads the rest of
    # the reserved *region* with spaces, like Java doWriteSignature does for the
    # /ByteRange placeholder.
    private def copy_into_increment(increment : Bytes, offset : Int64,
                                    bytes : Bytes, region : Int64) : Nil
      index = 0
      while index < region
        increment[offset.to_i + index] = index < bytes.size ? bytes[index] : 0x20_u8
        index += 1
      end
    end

    # Java COSWriter#detectPossibleSignature: the signature of the revision being
    # written is a /Type /Sig (or /Type /DocTimeStamp) dictionary whose /ByteRange
    # points past the end of the source. Older signatures reachable from the
    # document keep their final byte range and are ignored (PDFBOX-5521).
    private def detect_possible_signature(dict : Pdfbox::Cos::Dictionary) : Nil
      return if @reached_signature

      source = @document.source_bytes
      return unless source
      return unless signature_dictionary?(dict, source)

      @reached_signature = true
    end

    # Whether *dict* is the signature dictionary of the revision being written:
    # /Type /Sig (or /Type /DocTimeStamp) with a four-entry /ByteRange whose third
    # value points past the end of the source (PDFBOX-5521).
    private def signature_dictionary?(dict : Pdfbox::Cos::Dictionary, source : Bytes) : Bool
      type = resolve(dict[Pdfbox::Cos::Name.new("Type")])
      return false unless type.is_a?(Pdfbox::Cos::Name)
      return false unless type.value == "Sig" || type.value == "DocTimeStamp"

      byte_range = dictionary_byte_range(dict)
      return false unless byte_range

      third = resolve(byte_range[2])
      third.is_a?(Pdfbox::Cos::Integer) && third.value > source.size
    end

    # The /ByteRange array of *dict*, or nil.
    private def dictionary_byte_range(dict : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Array?
      byte_range = resolve(dict[Pdfbox::Cos::Name.new("ByteRange")])
      byte_range.as?(Pdfbox::Cos::Array).try do |array|
        array.size == 4 ? array : nil
      end
    end

    # Dereferences a COS object if needed.
    private def resolve(base : Pdfbox::Cos::Base?) : Pdfbox::Cos::Base?
      base.is_a?(Pdfbox::Cos::Object) ? base.object : base
    end

    # Absolute position in the final file of the next byte written.
    private def absolute_position : Int64
      @signature_base + @destination.pos.to_i64
    end

    # Writes the objects, cross-reference section and trailer of the appended
    # revision, returning the new startxref and the highest object number in use.
    private def write_incremental_revision(source : Bytes,
                                           previous_xref : Int64,
                                           objects_to_write : Enumerable(Pdfbox::Cos::Dictionary) = [] of Pdfbox::Cos::Dictionary) : Tuple(Int64, Int64)
      cos_writer = COSWriter.new(@destination, false, nil)
      trailer = @document.trailer || Pdfbox::Cos::Dictionary.new
      catalog = @document.document_catalog

      object_keys = {} of UInt64 => Pdfbox::Cos::ObjectKey
      key_objects = {} of Pdfbox::Cos::ObjectKey => Pdfbox::Cos::Base
      object_wrapper = {} of UInt64 => UInt64
      roots = build_roots(catalog, trailer)
      next_number = collect_objects_incremental(roots, object_keys, key_objects, object_wrapper,
        @document.highest_object_number + 1)
      object_wrapper.each do |wrapper_id, inner_id|
        if inner_key = object_keys[inner_id]?
          object_keys[wrapper_id] = inner_key
        end
      end

      # Only the updated structures and the objects created in this session end
      # up in the appended revision.
      write_ids = incremental_write_ids(trailer.to_increment.exclude(trailer))
      # ... plus the dictionaries the caller listed explicitly (Java adds them to
      # objectsToWrite, so an unchanged object can still be rewritten).
      objects_to_write.each { |dictionary| write_ids.add(dictionary.object_id.to_u64) }

      # The signature's /ByteRange is written inline in its dictionary so that its
      # bytes can be patched; it must not be emitted as an object of its own.
      if @signature_tracking
        key_objects.each_value do |obj|
          next unless obj.is_a?(Pdfbox::Cos::Dictionary)
          next unless signature_dictionary?(obj, source)
          next unless (array = dictionary_byte_range(obj)).is_a?(Pdfbox::Cos::Array)

          write_ids.delete(array.object_id.to_u64)
        end
      end

      written = [] of Tuple(Int64, XRefEntry)
      key_objects.keys.sort_by!(&.number).each do |key|
        obj = key_objects[key]
        next unless obj
        next unless write_ids.includes?(obj.object_id.to_u64)
        position = absolute_position
        written << {key.number, XRefEntry.new(position, key.generation, :in_use)}
        @destination << key.number << ' ' << key.generation << " obj\n"
        write_indirect_object(obj, cos_writer, object_keys, object_wrapper, key)
        @destination << "\nendobj\n"
      end

      highest_number = Math.max(next_number - 1, written.max_of? { |(number, _)| number } || 0_i64)
      new_start_xref = if source_uses_xref_stream?(source, previous_xref)
                         write_incremental_xref_stream(written, catalog, trailer, object_keys,
                           previous_xref, highest_number)
                       else
                         write_incremental_xref_table(written, catalog, trailer, object_keys, cos_writer,
                           previous_xref, highest_number)
                       end

      {new_start_xref, highest_number}
    end

    # The ids of the objects an incremental revision has to carry: the objects of
    # the COSIncrement rooted at the trailer, plus the structures created in this
    # session. A created structure has no object number in the source revision,
    # so the reference this writer emits for it would dangle unless the structure
    # is written as well. (Java gets away without them because COSWriter writes
    # direct structures inline; see the divergence note on #write_incremental.)
    private def incremental_write_ids(increment : Pdfbox::Cos::Increment) : Set(UInt64)
      ids = Set(UInt64).new
      queue = Deque(Pdfbox::Cos::Base).new
      increment.objects.each do |base|
        ids << base.object_id.to_u64
        queue << base
      end

      until queue.empty?
        current = queue.shift
        actual = current.is_a?(Pdfbox::Cos::Object) ? current.object : current
        next unless actual

        children = case actual
                   when Pdfbox::Cos::Dictionary then actual.entries.each_value.to_a
                   when Pdfbox::Cos::Array      then actual.items
                   else                              [] of Pdfbox::Cos::Base
                   end
        children.each do |child|
          inner = child.is_a?(Pdfbox::Cos::Object) ? child.object : child
          next unless inner.is_a?(Pdfbox::Cos::Dictionary) || inner.is_a?(Pdfbox::Cos::Array)
          # A structure that already had an object number in the source revision
          # can be referenced from the new one as it is.
          next if inner.key

          id = inner.object_id.to_u64
          next if ids.includes?(id)

          ids << id
          queue << inner
        end
      end
      ids
    end

    # True when the source cross-reference section (at *start_xref*) is an xref
    # stream instead of a classic `xref` table.
    private def source_uses_xref_stream?(source : Bytes, start_xref : Int64) : Bool
      offset = start_xref.to_i
      return true if offset < 0 || offset >= source.size

      while offset < source.size && source[offset].unsafe_chr.ascii_whitespace?
        offset += 1
      end
      remaining = source.size - offset
      return true if remaining < 4

      String.new(source[offset, Math.min(4, remaining)]) != "xref"
    end

    # Collects the objects to write for an incremental update. Objects parsed
    # from the source keep their original object number (so the new revision can
    # reference them); everything created in this session gets a number above
    # the source document's highest object number.
    private def collect_objects_incremental(roots : Array(Pdfbox::Cos::Base),
                                            object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                            key_objects : Hash(Pdfbox::Cos::ObjectKey, Pdfbox::Cos::Base),
                                            object_wrapper : Hash(UInt64, UInt64),
                                            next_number : Int64) : Int64
      objects = [] of Pdfbox::Cos::Base
      seen = Set(UInt64).new
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
        next if seen.includes?(id)

        seen << id
        objects << actual

        case actual
        when Pdfbox::Cos::Dictionary # includes Stream
          actual.entries.each_value { |val| queue << val }
        when Pdfbox::Cos::Array
          actual.items.each { |item| queue << item }
        end
      end

      # Parsed objects first, so their numbers are reserved before new objects
      # are numbered (a new object must never take a source object number).
      objects.each do |object|
        key = object.key
        next unless key
        next if key_objects.has_key?(key)

        object_keys[object.object_id.to_u64] = key
        key_objects[key] = object
        next_number = Math.max(next_number, key.number + 1)
      end

      objects.each do |object|
        id = object.object_id.to_u64
        next if object_keys.has_key?(id)

        key = Pdfbox::Cos::ObjectKey.new(next_number, 0_i64)
        next_number += 1
        object_keys[id] = key
        key_objects[key] = object
      end

      next_number
    end

    # Classic xref table for the appended revision: object 0, then one
    # subsection per contiguous run of written object numbers.
    private def write_incremental_xref_table(written : Array(Tuple(Int64, XRefEntry)),
                                             catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                             trailer : Pdfbox::Cos::Dictionary?,
                                             object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                             cos_writer : COSWriter,
                                             previous_xref : Int64,
                                             highest_number : Int64) : Int64
      # Absolute: the buffered revision of an external-signing save starts after
      # the source bytes (see Writer#absolute_position).
      xref_start = absolute_position
      @destination << "xref\n"
      @destination << "0 1\n"
      @destination << "0000000000 65535 f \n"

      entries = written.sort_by { |(number, _)| number }
      index = 0
      while index < entries.size
        first_number = entries[index][0]
        count = 1
        while index + count < entries.size && entries[index + count][0] == first_number + count
          count += 1
        end

        @destination << first_number << ' ' << count << "\n"
        count.times do |offset|
          entry = entries[index + offset][1]
          @destination << entry.offset.to_s.rjust(10, '0') << ' '
          @destination << entry.generation.to_s.rjust(5, '0') << ' ' << "n \n"
        end
        index += count
      end

      @destination << "trailer\n<<\n"
      @destination << "/Size " << (highest_number + 1) << "\n"
      @destination << "/Prev " << previous_xref << "\n"
      write_incremental_trailer_references(catalog, trailer, object_keys, cos_writer)
      @destination << ">>\n"
      @destination << "startxref\n"
      @destination << xref_start << "\n"
      @destination << "%%EOF\n"
      xref_start
    end

    # Cross-reference stream for the appended revision. Only the written object
    # numbers are indexed (via /Index): an xref stream entry of type 0 would
    # mark an unchanged source object as free.
    private def write_incremental_xref_stream(written : Array(Tuple(Int64, XRefEntry)),
                                              catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                              trailer : Pdfbox::Cos::Dictionary?,
                                              object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                              previous_xref : Int64,
                                              highest_number : Int64) : Int64
      xref_number = highest_number + 1
      position = absolute_position
      # A cross-reference stream must list itself (PDF 32000-1 7.5.8.3), so the
      # entry for this stream is part of the section it describes.
      entries = written.map { |(number, entry)| {number, entry} }
      entries << {xref_number, XRefEntry.new(position, 0_i64, :in_use)}
      entries.sort_by! { |(number, _)| number }

      index_array = Pdfbox::Cos::Array.new
      data = ::IO::Memory.new
      index = 0
      while index < entries.size
        first_number = entries[index][0]
        count = 1
        while index + count < entries.size && entries[index + count][0] == first_number + count
          count += 1
        end

        index_array << Pdfbox::Cos::Integer.new(first_number)
        index_array << Pdfbox::Cos::Integer.new(count.to_i64)
        count.times do |offset|
          entry = entries[index + offset][1]
          data.write_byte(1_u8)
          xref_write_u32(data, entry.offset)
          xref_write_u8(data, entry.generation)
        end
        index += count
      end

      xref_dict = Pdfbox::Cos::Dictionary.new
      xref_dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("XRef")
      xref_dict.set_int(Pdfbox::Cos::Name.new("Size"), xref_number + 1)
      w_array = Pdfbox::Cos::Array.new
      w_array << Pdfbox::Cos::Integer.new(1_i64)
      w_array << Pdfbox::Cos::Integer.new(4_i64)
      w_array << Pdfbox::Cos::Integer.new(1_i64)
      xref_dict[Pdfbox::Cos::Name.new("W")] = w_array
      xref_dict[Pdfbox::Cos::Name.new("Index")] = index_array
      xref_dict.set_long(Pdfbox::Cos::Name.new("Prev"), previous_xref)
      xref_dict.set_int(Pdfbox::Cos::Name.new("Length"), data.size)
      write_incremental_trailer_references(catalog, trailer, object_keys, nil, xref_dict)

      @destination << xref_number << " 0 obj\n"
      @destination << "<<\n"
      xref_dict.entries.each do |name, value|
        @destination << '/' << name.value << ' '
        value.write_pdf(@destination)
        @destination << "\n"
      end
      @destination << ">>\n"
      @destination << "stream\n"
      @destination.write(data.to_slice)
      @destination << "\nendstream\nendobj\n"
      @destination << "startxref\n"
      @destination << position << "\n"
      @destination << "%%EOF\n"
      position
    end

    # Writes the /Root, /Info and /ID entries of a new trailer.
    private def write_incremental_trailer_references(catalog : Pdfbox::Pdmodel::DocumentCatalog?,
                                                     trailer : Pdfbox::Cos::Dictionary?,
                                                     object_keys : Hash(UInt64, Pdfbox::Cos::ObjectKey),
                                                     cos_writer : COSWriter?,
                                                     into : Pdfbox::Cos::Dictionary? = nil) : Nil
      if catalog
        if cat_key = object_keys[catalog.cos_object.object_id.to_u64]?
          write_trailer_entry("Root", Pdfbox::Cos::Object.new(cat_key.number, cat_key.generation, nil), cos_writer, into)
        end
      end

      if trailer
        if info_val = trailer[Pdfbox::Cos::Name.new("Info")]?
          info_base = info_val.is_a?(Pdfbox::Cos::Object) ? info_val.object : info_val
          if info_base && (info_key = object_keys[info_base.object_id.to_u64]?)
            write_trailer_entry("Info", Pdfbox::Cos::Object.new(info_key.number, info_key.generation, nil), cos_writer, into)
          end
        end
      end

      if new_id = incremental_document_id(trailer)
        write_trailer_entry("ID", new_id, cos_writer, into)
      end
    end

    private def write_trailer_entry(name : String,
                                    value : Pdfbox::Cos::Base,
                                    cos_writer : COSWriter?,
                                    into : Pdfbox::Cos::Dictionary?) : Nil
      if into
        into[Pdfbox::Cos::Name.new(name)] = value
        return
      end

      @destination << '/' << name << ' '
      if value.is_a?(Pdfbox::Cos::Object)
        @destination << value.object_number << ' ' << value.generation_number << " R\n"
      elsif cos_writer
        cos_writer.write(value)
        @destination << "\n"
      else
        value.write_pdf(@destination)
        @destination << "\n"
      end
    end

    # Java COSWriter generates a new /ID for an incremental update: the first
    # value is kept and the second one is a fresh SHA-256 of the time plus the
    # /Info values.
    private def incremental_document_id(trailer : Pdfbox::Cos::Dictionary?) : Pdfbox::Cos::Array?
      return unless trailer

      id_val = trailer[Pdfbox::Cos::Name.new("ID")]
      return unless id_val.is_a?(Pdfbox::Cos::Array) && id_val.size == 2

      id_array = Pdfbox::Cos::Array.new
      id_array << id_val.items.first
      id_array << Pdfbox::Cos::String.new(document_id_digest(trailer))
      id_array
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
    @current_object_key : Pdfbox::Cos::ObjectKey?
    # Object ids currently being written inline; used to break cyclic direct
    # dictionaries/arrays (e.g. /K <-> /P) that would otherwise recurse forever.
    @inline_stack = Set(UInt64).new

    def initialize(@destination : ::IO, @will_encrypt : Bool = false, @security_handler : Pdfbox::Pdmodel::Encryption::SecurityHandler? = nil)
    end

    # Set the object key of the indirect object currently being written.
    # Used to derive the per-object key for encrypting strings.
    def current_object_key=(key : Pdfbox::Cos::ObjectKey?) : Nil
      @current_object_key = key
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
      id = dict.object_id.to_u64
      if @inline_stack.includes?(id)
        write_cycle_break(dict)
        return
      end
      @inline_stack.add(id)
      begin
        @destination << "<<"
        dict.entries.each do |key, value|
          write_name(key)
          PDFIO.write_whitespace(@destination)
          write(value)
          PDFIO.write_whitespace(@destination)
        end
        @destination << ">>"
      ensure
        @inline_stack.delete(id)
      end
    end

    # Write a COS array
    def write_array(array : Pdfbox::Cos::Array) : Nil
      id = array.object_id.to_u64
      if @inline_stack.includes?(id)
        write_cycle_break(array)
        return
      end
      @inline_stack.add(id)
      begin
        @destination << '['
        array.items.each_with_index do |item, index|
          write(item)
          if index < array.size - 1
            PDFIO.write_whitespace(@destination)
          end
        end
        @destination << ']'
      ensure
        @inline_stack.delete(id)
      end
    end

    # Break a cyclic inline reference: emit an indirect reference when the
    # object has an assigned key, otherwise a null placeholder.
    private def write_cycle_break(object : Pdfbox::Cos::Base) : Nil
      if key = object.key
        @destination << key.number << ' ' << key.generation << " R"
      else
        @destination << "null"
      end
    end

    # Write a COS string, encrypting it when writing an encrypted document.
    # Matching Java's COSWriter.visitFromString, strings are encrypted with the
    # key derived for the enclosing indirect object.
    def write_string(string : Pdfbox::Cos::String) : Nil
      if @will_encrypt && (handler = @security_handler) && (key = @current_object_key)
        string = handler.encrypt_string(string, key.number, key.generation)
      end
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
