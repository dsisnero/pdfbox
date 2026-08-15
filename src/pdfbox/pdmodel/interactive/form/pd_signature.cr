# A digital signature that can be attached to a document.
#
# Ported from Apache PDFBox PDSignature (focus: byte range and contents).
module Pdfbox::Pdmodel::Interactive::Form
  class PDSignature
    @dictionary : Cos::Dictionary

    # Default constructor.
    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary[Cos::Name::TYPE] = Cos::Name.new("Sig")
    end

    # Constructor.
    def initialize(dictionary : Cos::Dictionary)
      @dictionary = dictionary
    end

    # Convert this object to a COS dictionary.
    def cos_object : Cos::Dictionary
      @dictionary
    end

    # Sets the byte range. Java PDSignature#setByteRange; a non-4-length range
    # is ignored.
    def byte_range=(range : Array(Int32)) : Nil
      return if range.size != 4

      array = Cos::Array.new
      range.each do |value|
        array.add(Cos::Integer.new(value.to_i64))
      end
      @dictionary[Cos::Name.new("ByteRange")] = array
    end

    # Read out the byterange. Java PDSignature#getByteRange; empty array if none.
    def byte_range : Array(Int32)
      byte_range = @dictionary.get_array(Cos::Name.new("ByteRange"))
      return [] of Int32 if byte_range.nil?

      result = Array(Int32).new(byte_range.size)
      byte_range.size.times do |i|
        item = byte_range.get(i)
        result << case item
        when Cos::Integer then item.value.to_i32
        when Cos::Float   then item.value.to_i32
        else                   0
        end
      end
      result
    end

    # Returns the /Contents string as a byte array. Java PDSignature#getContents.
    def contents : Bytes
      base = @dictionary[Cos::Name.new("Contents")]?
      base = base.object if base.is_a?(Cos::Object)
      if base.is_a?(Cos::String)
        return base.bytes
      end
      Bytes.empty
    end

    # Return the embedded signature between the byterange gap, from a byte array.
    # Java PDSignature#getContents(byte[]).
    def get_contents(pdf_file : Bytes) : Bytes
      byte_range = self.byte_range
      begin_idx = byte_range[0] + byte_range[1] + 1
      len = byte_range[2] - begin_idx - 1

      get_converted_contents(pdf_file[begin_idx, len])
    end

    # Return the embedded signature between the byterange gap, from an IO.
    # Java PDSignature#getContents(InputStream).
    def get_contents(pdf_file : ::IO) : Bytes
      byte_range = self.byte_range
      begin_idx = byte_range[0] + byte_range[1] + 1
      len = byte_range[2] - begin_idx

      pdf_file.seek(begin_idx)
      data = Bytes.new(len)
      pdf_file.read_fully(data)
      get_converted_contents(data)
    end

    private def get_converted_contents(data : Bytes) : Bytes
      start = 0
      write_len = data.size
      # Filter < and (
      if data.size > 0 && (data[0] == 0x3C || data[0] == 0x28)
        start += 1
        write_len -= 1
      end
      # Filter > and ) at the end
      if data.size > 0 && (data[data.size - 1] == 0x3E || data[data.size - 1] == 0x29)
        write_len -= 1
      end

      hex_text = String.new(data[start, write_len])
      Cos::String.parse_hex(hex_text).bytes
    end
  end
end
