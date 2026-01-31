require "log"
require "./cos_parser"
require "../content_stream/operator"
require "../content_stream/operator_name"

module Pdfbox::Pdfparser
  # PDF content stream parser that extracts operands and operators
  # Similar to Apache PDFBox PDFStreamParser
  class PDFStreamParser < COSParser
    Log = ::Log.for(self)
    include Pdfbox::ContentStream::OperatorName

    # Maximum length for testing binary characters after EI in inline images
    MAX_BIN_CHAR_TEST_LENGTH = 10

    @bin_char_test_arr = Bytes.new(MAX_BIN_CHAR_TEST_LENGTH)
    @inline_image_depth = 0
    @inline_offset = 0_i64

    # Constructor for byte array
    def initialize(bytes : Bytes)
      source = Pdfbox::IO::MemoryRandomAccessRead.new(bytes)
      super(source)
    end

    # Constructor that takes a string (converts to bytes)
    def initialize(content : String)
      initialize(content.to_slice)
    end

    # Parse all tokens in the stream
    # Returns array of tokens (COS objects or Operators)
    def parse : Array(Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)
      stream_objects = [] of Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator
      while token = parse_next_token
        stream_objects << token
      end
      stream_objects
    end

    # Pattern to match numbers (integers and floats)
    private NUMBER_PATTERN = /^\d*\.?\d*$/

    # Parse the next token in the stream
    # Returns token or nil if no more tokens
    def parse_next_token : (Pdfbox::Cos::Base | Pdfbox::ContentStream::Operator)?
      return if source.closed?

      skip_spaces
      return if eof?

      c = peek_char
      return unless c

      case c
      when '<'
        # Could be dictionary (<<) or hex string (<)
        saved_pos = position
        read_char # consume '<'
        next_char = peek_char
        seek(saved_pos) # restore

        if next_char == '<'
          parse_dictionary(true)
        else
          parse_string
        end
      when '['
        # array
        parse_array
      when '('
        # string
        parse_cos_literal_string
      when '/'
        # name
        parse_name
      when 'n'
        # null or operator
        null_string = read_string
        if null_string == "null"
          Pdfbox::Cos::Null.instance
        else
          Pdfbox::ContentStream::Operator.get_operator(null_string)
        end
      when 't', 'f'
        next_str = read_string
        if next_str == "true"
          Pdfbox::Cos::Boolean::TRUE
        elsif next_str == "false"
          Pdfbox::Cos::Boolean::FALSE
        else
          Pdfbox::ContentStream::Operator.get_operator(next_str)
        end
      when '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '-', '+', '.'
        # Number parsing similar to Apache PDFBox
        parse_cos_number
      when 'B'
        parse_begin_inline_image
      when 'I'
        parse_inline_image_data
      when ']'
        # some ']' around without its previous '['
        # this means a PDF is somewhat corrupt but we will continue to parse.
        read_char
        # must be a better solution than null...
        Pdfbox::Cos::Null.instance
      else
        # we must be an operator
        operator = read_operator.strip
        unless operator.empty?
          Pdfbox::ContentStream::Operator.get_operator(operator)
        end
      end
    end

    # Parse a COS number (similar to Apache PDFBox parseCOSNumber)
    private def parse_cos_number : Pdfbox::Cos::Base
      # We will be filling buf with the rest of the number.
      # Only allow 1 "." and "-" and "+" at start of number.
      buffer = String::Builder.new
      c = peek_char
      raise "Expected number" unless c
      buffer << c
      read_char # consume

      # Ignore double negative (this is consistent with Adobe Reader)
      if c == '-' && peek_char == '-'
        read_char # consume second '-'
      end

      dot_not_read = c != '.'
      while (c = peek_char) && (c.ascii_number? || (dot_not_read && c == '.') || c == '-')
        if c != '-'
          # PDFBOX-4064: ignore "-" in the middle of a number
          buffer << c
        end
        read_char
        dot_not_read = false if dot_not_read && c == '.'
      end

      s = buffer.to_s
      if s == "+"
        # PDFBOX-5906
        Log.warn { "isolated '+' is ignored" }
        return Pdfbox::Cos::Null.instance
      end

      # Use COSNumber.get(s) equivalent - we'll create integer or float
      if s.includes?('.') || s.downcase.includes?('e')
        Pdfbox::Cos::Float.new(s.to_f64)
      else
        Pdfbox::Cos::Integer.new(s.to_i64)
      end
    end

    # Parse 'B' case (BEGIN_INLINE_IMAGE)
    private def parse_begin_inline_image : Pdfbox::ContentStream::Operator
      next_operator = read_string
      begin_image_op = Pdfbox::ContentStream::Operator.get_operator(next_operator)
      if next_operator == BEGIN_INLINE_IMAGE
        @inline_image_depth += 1
        if @inline_image_depth > 1
          # PDFBOX-6038
          raise ::IO::Error.new("Nested '#{BEGIN_INLINE_IMAGE}' operator not allowed at offset #{position}, first: #{@inline_offset}")
        else
          @inline_offset = position
        end
        image_params = Pdfbox::Cos::Dictionary.new
        begin_image_op.image_parameters = image_params
        next_token = nil
        while (next_token = parse_next_token).is_a?(Pdfbox::Cos::Name)
          value = parse_next_token
          unless value.is_a?(Pdfbox::Cos::Base)
            Log.warn { "Unexpected token in inline image dictionary at offset #{source.closed? ? "EOF" : position}" }
            break
          end
          image_params[next_token.as(Pdfbox::Cos::Name)] = value.as(Pdfbox::Cos::Base)
        end
        # final token will be the image data, maybe??
        if next_token.is_a?(Pdfbox::ContentStream::Operator)
          image_data = next_token.as(Pdfbox::ContentStream::Operator)
          if (data = image_data.image_data).nil? || data.empty?
            Log.warn { "empty inline image at stream offset #{source.closed? ? "EOF" : position}" }
          end
          begin_image_op.image_data = image_data.image_data || Bytes.empty
          @inline_image_depth -= 1
        else
          Log.warn { "nextToken #{next_token} at position #{source.closed? ? "EOF" : position}, expected #{BEGIN_INLINE_IMAGE_DATA}?!" }
        end
      end
      begin_image_op
    end

    # Parse 'I' case (BEGIN_INLINE_IMAGE_DATA)
    private def parse_inline_image_data : Pdfbox::ContentStream::Operator
      # Special case for ID operator
      c1 = read_char
      c2 = read_char
      unless c1 && c2
        close
        raise ::IO::Error.new("Unexpected EOF reading ID operator at offset #{position}")
      end
      id = String.build { |str| str << c1 << c2 }
      unless id == BEGIN_INLINE_IMAGE_DATA
        current_position = position
        close
        raise ::IO::Error.new("Error: Expected operator 'ID' actual='#{id}' at stream offset #{current_position}")
      end

      # skip one line break (CR, LF or CRLF) or any one-byte whitespace
      unless skip_linebreak
        if whitespace?
          read_char # pull off the whitespace character
        end
      end

      last_byte = source.read
      current_byte = source.read
      # PDF spec is kinda unclear about this. Should a whitespace
      # always appear before EI? Not sure, so that we just read
      # until EI<whitespace>.
      # Be aware not all kind of whitespaces are allowed here. see PDFBOX-1561
      buffer = ::IO::Memory.new
      while !(last_byte == 'E'.ord &&
            current_byte == 'I'.ord &&
            has_next_space_or_return? &&
            has_no_following_bin_data?) &&
            !eof?
        buffer.write_byte(last_byte.to_u8) if last_byte
        last_byte = current_byte
        current_byte = source.read
      end
      # the EI operator isn't unread, as it won't be processed anyway
      begin_image_data_op = Pdfbox::ContentStream::Operator.get_operator(BEGIN_INLINE_IMAGE_DATA)
      # save the image data to the operator, so that it can be accessed later
      begin_image_data_op.image_data = buffer.to_slice
      begin_image_data_op
    end

    # Check if there's binary data following an EI operator
    # Used for inline image parsing
    private def has_no_following_bin_data? : Bool
      # as suggested in PDFBOX-1164
      read_bytes = source.read(@bin_char_test_arr, 0, MAX_BIN_CHAR_TEST_LENGTH)
      no_bin_data = true
      start_op_idx = -1
      end_op_idx = -1
      s = ""

      Log.debug { "String after EI: '#{String.new(@bin_char_test_arr[0, read_bytes], "US-ASCII")}'" } if read_bytes > 0

      if read_bytes > 0
        (0...read_bytes).each do |b_idx|
          b = @bin_char_test_arr[b_idx]
          if b != 0 && b < 0x09 || b > 0x0a && b < 0x20 && b != 0x0d
            # control character or > 0x7f -> we have binary data
            no_bin_data = false
            break
          end
          # find the start of a PDF operator
          if start_op_idx == -1 && !(b == 0 || b == 9 || b == 0x20 || b == 0x0a || b == 0x0d)
            start_op_idx = b_idx
          elsif start_op_idx != -1 && end_op_idx == -1 &&
                (b == 0 || b == 9 || b == 0x20 || b == 0x0a || b == 0x0d)
            end_op_idx = b_idx
          end
        end

        # PDFBOX-3742: just assuming that 1-3 non blanks is a PDF operator isn't enough
        if no_bin_data && end_op_idx != -1 && start_op_idx != -1
          # usually, the operator here is Q, sometimes EMC (PDFBOX-2376), S (PDFBOX-3784),
          # or a number (PDFBOX-5957)
          s = String.new(@bin_char_test_arr[start_op_idx, end_op_idx - start_op_idx], "US-ASCII")
          unless s == "Q" || s == "EMC" || s == "S" || NUMBER_PATTERN.matches?(s)
            # operator is not Q, not EMC, not S, nor a number -> assume binary data
            no_bin_data = false
          end
        end

        # only if not close to EOF
        if no_bin_data && start_op_idx != -1 && read_bytes == MAX_BIN_CHAR_TEST_LENGTH
          if end_op_idx == -1
            end_op_idx = MAX_BIN_CHAR_TEST_LENGTH
            s = String.new(@bin_char_test_arr[start_op_idx, end_op_idx - start_op_idx], "US-ASCII")
          end
          Log.debug { "startOpIdx: #{start_op_idx} endOpIdx: #{end_op_idx} s = '#{s}'" }
          # look for token of 3 chars max or a number
          if end_op_idx - start_op_idx > 3 && !NUMBER_PATTERN.matches?(s)
            no_bin_data = false # "operator" too long, assume binary data
          end
        end
        source.rewind(read_bytes)
      end

      unless no_bin_data
        Log.warn do
          "ignoring 'EI' assumed to be in the middle of inline image at stream offset #{position}, s = '#{s}'"
        end
      end
      no_bin_data
    end

    # This will read an operator from the stream.
    # ameba:disable Metrics/CyclomaticComplexity
    private def read_operator : String
      skip_spaces

      # average string size is around 2 and the normal string buffer size is
      # about 16 so lets save some space.
      buffer = String::Builder.new(4)
      next_char = source.peek
      while next_char
        next_char_int = next_char.to_i32
        break if next_char_int == -1
        break if whitespace?(next_char_int)
        break if next_char_int == '['.ord
        break if next_char_int == '<'.ord
        break if next_char_int == '('.ord
        break if next_char_int == '/'.ord
        break if next_char_int == '%'.ord
        break if next_char_int >= '0'.ord && next_char_int <= '9'.ord
        # ameba:disable Lint/NotNil
        current_char = read_char.not_nil!
        next_char = source.peek
        buffer << current_char
        # Type3 Glyph description has operators with a number in the name
        if current_char == 'd' && next_char && (next_char == '0'.ord || next_char == '1'.ord)
          buffer << read_char.not_nil!
          next_char = source.peek
        end
      end
      buffer.to_s
    end

    # Checks if the next char is a space or a return.
    private def has_next_space_or_return? : Bool
      c = source.peek
      c ? space_or_return?(c.to_i32) : false
    end

    private def space_or_return?(c : Int32) : Bool
      c == 10 || c == 13 || c == 32
    end

    # Close the underlying resource.
    def close : Nil
      if !source.closed?
        source.close
      end
    end
  end
end
