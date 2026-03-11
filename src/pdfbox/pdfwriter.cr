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
  class Writer
    @destination : ::IO
    @document : Pdfbox::Pdmodel::Document

    def initialize(@destination : ::IO, @document : Pdfbox::Pdmodel::Document)
    end

    # Write PDF header with version (e.g., "1.4")
    def write_header(version : String) : Nil
      @destination << "%PDF-#{version}\n"
      # Write binary comment line (required by PDF spec for binary files)
      @destination << "%\xE2\xE3\xCF\xD3\n"
    end

    # Write the PDF document
    def write : Nil
      write_header(@document.version)
      cos_writer = COSWriter.new(@destination)

      # Create xref writer
      xref_writer = XRefWriter.new(@destination)

      # Object 0: free entry (required by PDF spec)
      xref_writer.add_entry(0_i64, 65535_i64, :free)

      # Write catalog object (object 1)
      catalog_offset = @destination.pos.to_i64
      xref_writer.add_entry(catalog_offset, 0_i64, :in_use)
      @destination << "1 0 obj\n"
      @destination << "<<\n"
      @destination << "/Type /Catalog\n"
      @destination << "/Pages 2 0 R\n"
      if catalog = @document.document_catalog
        catalog.cos_object.entries.each do |key, value|
          key_name = key.value
          next if key_name == "Type" || key_name == "Pages"
          local_stack = Set(UInt64).new
          materialized_value = materialize_for_write(
            value,
            local_stack
          )
          cos_writer.write_name(key)
          @destination << ' '
          cos_writer.write(materialized_value)
          @destination << '\n'
        end
      end
      @destination << ">>\n"
      @destination << "endobj\n"

      # Write pages object (object 2)
      pages_offset = @destination.pos.to_i64
      xref_writer.add_entry(pages_offset, 0_i64, :in_use)
      @destination << "2 0 obj\n"
      @destination << "<<\n"
      @destination << "/Type /Pages\n"
      @destination << "/Kids ["
      # Add page references (object 3..)
      @document.page_count.times do |i|
        @destination << " " << (3 + i) << " 0 R"
      end
      @destination << " ]\n"
      @destination << "/Count " << @document.page_count << "\n"
      @destination << ">>\n"
      @destination << "endobj\n"

      # Write each page object
      deferred_stream_objects = [] of Tuple(Int32, Pdfbox::Cos::Stream)
      next_object_number = 3 + @document.page_count
      @document.page_count.times do |i|
        page_offset = @destination.pos.to_i64
        xref_writer.add_entry(page_offset, 0_i64, :in_use)
        obj_num = 3 + i
        page = @document.get_page(i)
        @destination << obj_num << " 0 obj\n"
        @destination << "<<\n"
        @destination << "/Type /Page\n"
        @destination << "/Parent 2 0 R\n"
        if media_box = page.media_box
          @destination << "/MediaBox ["
          @destination << media_box.lower_left_x << ' '
          @destination << media_box.lower_left_y << ' '
          @destination << media_box.upper_right_x << ' '
          @destination << media_box.upper_right_y
          @destination << "]\n"
        else
          @destination << "/MediaBox [0 0 612 792]\n" # Letter size
        end

        # Write other page dictionary entries (Annots, Resources, Contents, etc.)
        if page_dict = page.cos_object
          page_dict.entries.each do |key, value|
            key_name = key.value
            next if key_name == "Type" || key_name == "Parent" || key_name == "MediaBox"
            local_stack = Set(UInt64).new
            materialized_value = materialize_for_write(
              value,
              local_stack
            )
            cos_writer.write_name(key)
            @destination << ' '
            if key_name == "Contents" && materialized_value.is_a?(Pdfbox::Cos::Stream)
              stream_object_number = next_object_number
              next_object_number += 1
              deferred_stream_objects << {stream_object_number, materialized_value}
              @destination << stream_object_number << " 0 R"
            else
              cos_writer.write(materialized_value)
            end
            @destination << '\n'
          end
        end
        @destination << ">>\n"
        @destination << "endobj\n"
      end

      deferred_stream_objects.each do |stream_object_number, stream|
        stream_offset = @destination.pos.to_i64
        xref_writer.add_entry(stream_offset, 0_i64, :in_use)
        @destination << stream_object_number << " 0 obj\n"
        cos_writer.write_stream(stream)
        @destination << '\n'
        @destination << "endobj\n"
      end

      # Write xref table
      xref_start = @destination.pos
      xref_writer.write

      # Write trailer
      @destination << "trailer\n"
      @destination << "<<\n"
      @destination << "/Size " << (xref_writer.size) << "\n" # includes object 0
      @destination << "/Root 1 0 R\n"
      @destination << ">>\n"

      # Write startxref
      @destination << "startxref\n"
      @destination << xref_start << "\n"

      # Write EOF marker
      @destination << "%%EOF\n"
    end

    private def materialize_for_write(base : Pdfbox::Cos::Base, stack : Set(UInt64)) : Pdfbox::Cos::Base
      case base
      when Pdfbox::Cos::Object
        dereferenced = base.object
        return Pdfbox::Cos::Null.instance unless dereferenced
        materialize_for_write(dereferenced, stack)
      when Pdfbox::Cos::Stream
        object_id = base.object_id.to_u64
        return Pdfbox::Cos::Null.instance if stack.includes?(object_id)

        stack << object_id
        clone = Pdfbox::Cos::Stream.new({} of Pdfbox::Cos::Name => Pdfbox::Cos::Base, base.data.dup)
        base.entries.each do |key, value|
          clone[key] = materialize_for_write(value, stack)
        end
        stack.delete(object_id)
        clone
      when Pdfbox::Cos::Dictionary
        object_id = base.object_id.to_u64
        return Pdfbox::Cos::Null.instance if stack.includes?(object_id)

        stack << object_id
        clone = Pdfbox::Cos::Dictionary.new
        subtype = base[Pdfbox::Cos::Name.new("Subtype")]
        is_widget_annotation = subtype.is_a?(Pdfbox::Cos::Name) && subtype.value == "Widget"
        base.entries.each do |key, value|
          # Avoid page back-reference loops for widget annotations while preserving field parent chains.
          next if is_widget_annotation && key.value == "P"
          clone[key] = materialize_for_write(value, stack)
        end
        stack.delete(object_id)
        clone
      when Pdfbox::Cos::Array
        object_id = base.object_id.to_u64
        return Pdfbox::Cos::Null.instance if stack.includes?(object_id)

        stack << object_id
        clone = Pdfbox::Cos::Array.new
        base.items.each do |item|
          clone.add(materialize_for_write(item, stack))
        end
        stack.delete(object_id)
        clone
      else
        base
      end
    end

    # Write with encryption
    def write(password : String) : Nil
      # TODO: Implement encrypted PDF writing
    end

    # Write incrementally (for digital signatures)
    def write_incremental : Nil
      # TODO: Implement incremental writing
    end

    # Set compression level
    def compression=(level : Int32) : Int32
      # TODO: Implement compression setting
      level
    end

    # Set encryption parameters
    def encryption=(enabled : Bool) : Bool
      # TODO: Implement encryption setting
      enabled
    end
  end

  # COS object writer
  class COSWriter
    @destination : ::IO

    def initialize(@destination : ::IO)
    end

    # Write a COS object
    def write(object : Pdfbox::Cos::Base) : Nil
      case object
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
      when Pdfbox::Cos::Stream
        write_stream(object)
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
    def write_stream(stream : Pdfbox::Cos::Stream) : Nil
      # Write stream dictionary
      write_dictionary(stream)
      @destination << '\n' << "stream" << '\n'
      @destination.write(stream.data)
      @destination << '\n' << "endstream"
    end

    # Write a COS object reference
    def write_object_reference(ref : Pdfbox::Cos::Object) : Nil
      @destination << ref.object_number << ' ' << ref.generation_number << " R"
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
      # TODO: Implement document info writing
    end

    # Set document title
    def title=(title : String) : String
      # TODO: Implement title setting
      title
    end

    # Set document author
    def author=(author : String) : String
      # TODO: Implement author setting
      author
    end

    # Set document subject
    def subject=(subject : String) : String
      # TODO: Implement subject setting
      subject
    end

    # Set document keywords
    def keywords=(keywords : String) : String
      # TODO: Implement keywords setting
      keywords
    end

    # Set document creator
    def creator=(creator : String) : String
      # TODO: Implement creator setting
      creator
    end

    # Set document producer
    def producer=(producer : String) : String
      # TODO: Implement producer setting
      producer
    end

    # Set creation date
    def creation_date=(date : Time) : Time
      # TODO: Implement creation date setting
      date
    end

    # Set modification date
    def modification_date=(date : Time) : Time
      # TODO: Implement modification date setting
      date
    end
  end
end
