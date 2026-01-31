module Pdfbox::Pdfparser
  # Filter stream that removes trailing CR, LF, or CR LF from stream data
  # Similar to Apache PDFBox EndstreamFilterStream
  class EndstreamFilterStream
    @has_cr = false
    @has_lf = false
    @pos = 0
    @must_filter = true
    @length = 0_i64

    # Write CR and/or LF that were kept, then writes len bytes from the
    # specified byte array starting at offset off to this output stream,
    # except trailing CR, CR LF, or LF. No filtering will be done for the
    # entire stream if the beginning is assumed to be ASCII.
    def filter(b : Bytes, off : Int32, len : Int32) : Nil
      if @pos == 0 && len > 10
        # PDFBOX-2120 Don't filter if ASCII, i.e. keep a final CR LF or LF
        @must_filter = false
        (0...10).each do |i|
          # Heuristic approach, taken from PDFStreamParser, PDFBOX-1164
          byte = b[off + i]
          if (byte < 0x09) || ((byte > 0x0a) && (byte < 0x20) && (byte != 0x0d))
            # control character or > 0x7f -> we have binary data
            @must_filter = true
            break
          end
        end
      end
      if @must_filter
        # first write what we kept last time
        if @has_cr
          # previous buffer ended with CR
          @has_cr = false
          if !@has_lf && len == 1 && b[off] == '\n'.ord.to_u8
            # actual buffer contains only LF so it will be the last one
            # => we're done
            # reset has_cr done too to avoid CR getting written in the flush
            return
          end
          @length += 1
        end
        if @has_lf
          @length += 1
          @has_lf = false
        end
        # don't write CR, LF, or CR LF if at the end of the buffer
        if len > 0
          if b[off + len - 1] == '\r'.ord.to_u8
            @has_cr = true
            len -= 1
          elsif b[off + len - 1] == '\n'.ord.to_u8
            @has_lf = true
            len -= 1
            if len > 0 && b[off + len - 1] == '\r'.ord.to_u8
              @has_cr = true
              len -= 1
            end
          end
        end
      end
      @length += len
      @pos += len
    end

    # write out a single CR if one was kept. Don't write kept CR LF or LF,
    # and then call the base method to flush.
    def calculate_length : Int64
      # if there is only a CR and no LF, write it
      if @has_cr && !@has_lf
        @length += 1
        @pos += 1
      end
      @has_cr = false
      @has_lf = false
      @length
    end
  end
end
