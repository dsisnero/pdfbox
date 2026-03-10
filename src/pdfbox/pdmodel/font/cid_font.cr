# CIDFont abstract base class
# Corresponds to PDCIDFont in Apache PDFBox
require "../../cos.cr"
require "./font_descriptor"
require "./vector_font"
require "./cid_system_info"

module Pdfbox::Pdmodel::Font
  abstract class PDCIDFont
    include PDVectorFont

    Log = ::Log.for(self)
    Cos = Pdfbox::Cos

    @dict : Pdfbox::Cos::Dictionary
    @font_descriptor : PDFontDescriptor?
    @widths : Hash(Int32, Float32)
    @default_width : Float32 = 0.0_f32
    @average_width : Float32 = 0.0_f32
    @vertical_displacement_y : Hash(Int32, Float32)  # w1y
    @position_vectors : Hash(Int32, PDFont::Vector)  # v
    @dw2 : Array(Float32) = [880.0_f32, -1000.0_f32] # default values

    # Constructor.
    def initialize(font_dictionary : Pdfbox::Cos::Dictionary, parent)
      @dict = font_dictionary
      @widths = {} of Int32 => Float32
      @vertical_displacement_y = {} of Int32 => Float32
      @position_vectors = {} of Int32 => PDFont::Vector
      read_widths
      read_vertical_displacements
    end

    # Returns the PostScript name of the font.
    def base_font : String
      @dict.get_name_as_string(Pdfbox::Cos::Name::BASE_FONT) || ""
    end

    # Returns the name of this font (same as base font).
    def name : String
      base_font
    end

    # Returns the font descriptor, may be nil.
    def font_descriptor : PDFontDescriptor?
      if fd = @font_descriptor
        return fd
      end
      fd_dict = @dict.get_dictionary(Pdfbox::Cos::Name::FONT_DESC)
      if fd_dict
        @font_descriptor = PDFontDescriptor.new(fd_dict)
      else
        nil
      end
    end

    # Reads the widths from the font dictionary (W array).
    private def read_widths : Nil
      w_array = @dict.get_array(Pdfbox::Cos::Name.new("W"))
      return unless w_array

      size = w_array.size
      counter = 0
      while counter < size - 1
        first_code_base = w_array[counter]?
        counter += 1
        break unless first_code_base
        unless first_code_base.is_a?(Pdfbox::Cos::Number)
          Log.warn { "Expected a number array member, got #{first_code_base}" }
          next
        end
        first_code = first_code_base.as(Pdfbox::Cos::Number).to_i
        next_base = w_array[counter]?
        counter += 1
        break unless next_base

        if next_base.is_a?(Pdfbox::Cos::Array)
          array = next_base.as(Pdfbox::Cos::Array)
          array_size = array.size
          (0...array_size).each do |i|
            width_base = array[i]?
            next unless width_base
            if width_base.is_a?(Pdfbox::Cos::Number)
              width = width_base.as(Pdfbox::Cos::Number).to_f32
              @widths[first_code + i] = width
            else
              Log.warn { "Expected a number array member, got #{width_base}" }
            end
          end
        else
          if counter >= size
            Log.warn { "premature end of widths array" }
            break
          end
          second_code_base = next_base
          range_width_base = w_array[counter]?
          counter += 1
          break unless range_width_base
          unless second_code_base.is_a?(Pdfbox::Cos::Number) && range_width_base.is_a?(Pdfbox::Cos::Number)
            Log.warn { "Expected two numbers, got #{second_code_base} and #{range_width_base}" }
            next
          end
          second_code = second_code_base.as(Pdfbox::Cos::Number).to_i
          range_width = range_width_base.as(Pdfbox::Cos::Number).to_f32
          start_range = first_code
          end_range = second_code
          (start_range..end_range).each do |cid|
            @widths[cid] = range_width
          end
        end
      end
    end

    # Reads vertical displacements from the font dictionary (DW2 and W2 arrays).
    private def read_vertical_displacements : Nil
      # default position vector and vertical displacement vector
      dw2_array = @dict.get_array(Pdfbox::Cos::Name.new("DW2"))
      if dw2_array && dw2_array.size >= 2
        base0 = dw2_array[0]?
        base1 = dw2_array[1]?
        if base0.is_a?(Pdfbox::Cos::Number) && base1.is_a?(Pdfbox::Cos::Number)
          @dw2[0] = base0.as(Pdfbox::Cos::Number).to_f32
          @dw2[1] = base1.as(Pdfbox::Cos::Number).to_f32
        end
      end

      # vertical metrics for individual CIDs.
      w2_array = @dict.get_array(Pdfbox::Cos::Name.new("W2"))
      return unless w2_array

      i = 0
      while i < w2_array.size
        c_base = w2_array[i]?
        break unless c_base
        i += 1
        unless c_base.is_a?(Pdfbox::Cos::Number)
          Log.warn { "Expected a number in W2 array, got #{c_base}" }
          next
        end
        c = c_base.as(Pdfbox::Cos::Number).to_i
        next_base = w2_array[i]?
        break unless next_base
        if next_base.is_a?(Pdfbox::Cos::Array)
          array = next_base.as(Pdfbox::Cos::Array)
          i += 1
          array_size = array.size
          j = 0
          while j < array_size
            cid = c + j // 3
            w1y_base = array[j]?
            v1x_base = array[j + 1]?
            v1y_base = array[j + 2]?
            break unless w1y_base && v1x_base && v1y_base
            unless w1y_base.is_a?(Pdfbox::Cos::Number) && v1x_base.is_a?(Pdfbox::Cos::Number) && v1y_base.is_a?(Pdfbox::Cos::Number)
              Log.warn { "Expected three numbers in W2 subarray" }
              j += 3
              next
            end
            w1y = w1y_base.as(Pdfbox::Cos::Number).to_f32
            v1x = v1x_base.as(Pdfbox::Cos::Number).to_f32
            v1y = v1y_base.as(Pdfbox::Cos::Number).to_f32
            @vertical_displacement_y[cid] = w1y
            @position_vectors[cid] = PDFont::Vector.new(v1x, v1y)
            j += 3
          end
        else
          # range format: c, c1, w1y, v1x, v1y
          unless next_base.is_a?(Pdfbox::Cos::Number)
            Log.warn { "Expected a number for second code in W2 range, got #{next_base}" }
            i += 1
            next
          end
          second_code = next_base.as(Pdfbox::Cos::Number).to_i
          i += 1 # move to w1y
          w1y_base = w2_array[i]?
          i += 1
          v1x_base = w2_array[i]?
          i += 1
          v1y_base = w2_array[i]?
          i += 1
          break unless w1y_base && v1x_base && v1y_base
          unless w1y_base.is_a?(Pdfbox::Cos::Number) && v1x_base.is_a?(Pdfbox::Cos::Number) && v1y_base.is_a?(Pdfbox::Cos::Number)
            Log.warn { "Expected three numbers in W2 range" }
            next
          end
          w1y = w1y_base.as(Pdfbox::Cos::Number).to_f32
          v1x = v1x_base.as(Pdfbox::Cos::Number).to_f32
          v1y = v1y_base.as(Pdfbox::Cos::Number).to_f32
          (c..second_code).each do |cid_val|
            @vertical_displacement_y[cid_val] = w1y
            @position_vectors[cid_val] = PDFont::Vector.new(v1x, v1y)
          end
        end
      end
    end

    # Returns the default width (DW entry, default 1000).
    private def default_width : Float32
      if @default_width == 0.0_f32
        base = @dict[Pdfbox::Cos::Name.new("DW")]?
        if base.is_a?(Pdfbox::Cos::Number)
          @default_width = base.as(Pdfbox::Cos::Number).to_f32
        else
          @default_width = 1000.0_f32
        end
      end
      @default_width
    end

    # Returns the default position vector for a CID.
    private def default_position_vector(cid : Int32) : PDFont::Vector
      PDFont::Vector.new(get_width_for_cid(cid) / 2.0_f32, @dw2[0])
    end

    # Returns the width for a CID, using explicit width or default width.
    private def get_width_for_cid(cid : Int32) : Float32
      @widths[cid]? || default_width
    end

    # Returns true if the Font dictionary specifies an explicit width for the given glyph.
    def has_explicit_width?(code : Int32) : Bool
      @widths.has_key?(code_to_cid(code))
    end

    # Returns the position vector (v), in text space, for the given character.
    def position_vector(code : Int32) : PDFont::Vector
      cid = code_to_cid(code)
      @position_vectors[cid]? || default_position_vector(cid)
    end

    # Returns the y-component of the vertical displacement vector (w1).
    def vertical_displacement_vector_y(code : Int32) : Float32
      cid = code_to_cid(code)
      @vertical_displacement_y[cid]? || @dw2[1]
    end

    # Returns the advance width of the given character, in glyph space.
    def width(code : Int32) : Float32
      get_width_for_cid(code_to_cid(code))
    end

    # Returns the average font width for all characters.
    def average_font_width : Float32
      if @average_width == 0.0_f32
        total_widths = 0.0_f32
        character_count = 0
        @widths.each_value do |width|
          if width > 0.0_f32
            total_widths += width
            character_count += 1
          end
        end
        if character_count != 0
          @average_width = total_widths / character_count
        end
        if @average_width <= 0.0_f32 || @average_width.nan?
          @average_width = default_width
        end
      end
      @average_width
    end

    # Returns the CIDSystemInfo, or nil if missing.
    def cid_system_info : PDCIDSystemInfo?
      cid_system_info_dict = @dict.get_dictionary(Pdfbox::Cos::Name.new("CIDSystemInfo"))
      if cid_system_info_dict
        PDCIDSystemInfo.new(cid_system_info_dict)
      else
        nil
      end
    end

    # Returns the CID for the given character code. If not found then CID 0 is returned.
    abstract def code_to_cid(code : Int32) : Int32

    # Returns the GID for the given character code.
    abstract def code_to_gid(code : Int32) : Int32

    # Encodes a glyph ID to PDF content stream bytes.
    abstract def encode_glyph_id(glyph_id : Int32) : Bytes

    # Encodes the given Unicode code point for use in a PDF content stream.
    protected abstract def encode(unicode : Int32) : Bytes

    # Reads the CIDToGID mapping stream.
    protected def read_cid_to_gid_map : Array(Int32)?
      stream = @dict.get_stream(Pdfbox::Cos::Name.new("CIDToGIDMap"))
      return unless stream

      bytes = stream.data
      number_of_ints = bytes.size // 2
      cid2gid = Array(Int32).new(number_of_ints, 0)
      offset = 0
      number_of_ints.times do |index|
        gid = ((bytes[offset] & 0xff).to_i32 << 8) | (bytes[offset + 1] & 0xff)
        cid2gid[index] = gid
        offset += 2
      end
      cid2gid
    end

    # PDVectorFont interface implementation (abstract methods already defined)
    # get_path, get_normalized_path, has_glyph are abstract in PDVectorFont
    # Subclasses must implement them.

    # Additional methods from PDFontLike interface

    # Returns the font matrix (default identity matrix scaled by 0.001).
    abstract def font_matrix : PDFont::Matrix

    # Returns the font's bounding box.
    abstract def bounding_box : PDFont::BoundingBox

    # Returns the height of the given character (deprecated).
    def height(code : Int32) : Float32
      # deprecated, return bounding box height
      bounding_box.height
    end

    # Returns the width from the embedded font file.
    abstract def width_from_font(code : Int32) : Float32

    # Returns true if the font file is embedded.
    abstract def embedded? : Bool

    # Returns true if the embedded font file is damaged.
    abstract def damaged? : Bool
  end
end
