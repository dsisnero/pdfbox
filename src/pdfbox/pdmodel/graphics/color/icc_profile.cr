# ICC Profile parser for PDFBox Crystal
# Based on ICC.1:2010 specification
module Pdfbox::Pdmodel::Graphics::Color
  class ICCProfileError < Exception; end

  class ICCProfile
    # Color space signatures
    class_getter color_space_signatures = {
      "RGB "  => 3,  # RGB color space
      "CMYK"  => 4,  # CMYK color space
      "GRAY"  => 1,  # Grayscale
      "Lab "  => 3,  # CIELAB
      "XYZ "  => 3,  # CIEXYZ
      "Yxy "  => 3,  # CIEYxy
      "HSV "  => 3,  # HSV
      "HLS "  => 3,  # HLS
      "Luv "  => 3,  # CIELuv
      "L*a*b" => 3,  # DEPRECATED: use "Lab " instead
      "CMY "  => 3,  # CMY
      "2CLR"  => 2,  # 2 color
      "3CLR"  => 3,  # 3 color
      "4CLR"  => 4,  # 4 color
      "5CLR"  => 5,  # 5 color
      "6CLR"  => 6,  # 6 color
      "7CLR"  => 7,  # 7 color
      "8CLR"  => 8,  # 8 color
      "9CLR"  => 9,  # 9 color
      "ACLR"  => 10, # 10 color
      "BCLR"  => 11, # 11 color
      "CCLR"  => 12, # 12 color
      "DCLR"  => 13, # 13 color
      "ECLR"  => 14, # 14 color
      "FCLR"  => 15, # 15 color
    }

    @data : Bytes
    @profile_size : UInt32
    @cmm_type : String
    @version_major : UInt8
    @version_minor : UInt8
    @version_bugfix : UInt8
    @device_class : String
    @color_space : String
    @pcs : String
    @num_tags : UInt32

    # Create an ICCProfile from bytes
    # Raises ICCProfileError if the data is not a valid ICC profile
    def initialize(data : Bytes)
      @data = data

      # Minimum ICC profile size is 128 bytes (header)
      if data.size < 128
        raise ICCProfileError.new("ICC profile too small: #{data.size} bytes (minimum 128)")
      end

      # Parse header
      @profile_size = read_u32(0)

      # Validate profile size
      if @profile_size != data.size
        raise ICCProfileError.new("ICC profile size mismatch: header says #{@profile_size} bytes, actual #{data.size} bytes")
      end

      @cmm_type = String.new(data[4, 4])
      @version_major = data[8]
      @version_minor = data[9] >> 4
      @version_bugfix = data[9] & 0x0F
      @device_class = String.new(data[12, 4])
      @color_space = String.new(data[16, 4])
      @pcs = String.new(data[20, 4])
      @num_tags = read_u32(128)

      # Validate ICC profile signature
      # Bytes 36-39 should be "acsp" (0x61637370)
      if read_u32(36) != 0x61637370
        raise ICCProfileError.new("Invalid ICC profile: missing 'acsp' signature")
      end
    end

    # Get the raw ICC profile data
    def data : Bytes
      @data
    end

    # Get the number of color components
    def num_components : Int32
      # Look up component count based on color space signature
      if count = @@color_space_signatures[@color_space]?
        count
      else
        # Unknown color space, try to determine from device class or make a guess
        case @device_class
        when "link", "abst", "spac"
          # These are abstract or color space conversion profiles
          # Try to determine from PCS
          if pcs_count = @@color_space_signatures[@pcs]?
            pcs_count
          else
            3 # Default guess
          end
        else
          # For device profiles (scnr, mntr, prtr), use color space
          3 # Default guess
        end
      end
    end

    # Get the color space signature
    def color_space : String
      @color_space
    end

    # Get the device class
    def device_class : String
      @device_class
    end

    # Get the PCS (Profile Connection Space)
    def pcs : String
      @pcs
    end

    # Get the profile version
    def version : String
      "#{@version_major}.#{@version_minor}.#{@version_bugfix}"
    end

    private def read_u32(offset : Int) : UInt32
      (@data[offset].to_u32 << 24) |
        (@data[offset + 1].to_u32 << 16) |
        (@data[offset + 2].to_u32 << 8) |
        @data[offset + 3].to_u32
    end

    # Create an ICCProfile from an IO
    def self.from_io(io : IO) : self
      # Read all data from IO
      buffer = IO::Memory.new
      IO.copy(io, buffer)
      new(buffer.to_slice)
    end

    # Create an ICCProfile from bytes
    def self.from_bytes(data : Bytes) : self
      new(data)
    end
  end
end
