# Font descriptor for PDF fonts
# Corresponds to PDFontDescriptor in Apache PDFBox
require "../common/pdrectangle"
require "../common/pdstream"
require "./panose"

module Pdfbox::Pdmodel::Font
  class PDFontDescriptor
    FLAG_FIXED_PITCH  =      1
    FLAG_SERIF        =      2
    FLAG_SYMBOLIC     =      4
    FLAG_SCRIPT       =      8
    FLAG_NON_SYMBOLIC =     32
    FLAG_ITALIC       =     64
    FLAG_ALL_CAP      =  65536
    FLAG_SMALL_CAP    = 131072
    FLAG_FORCE_BOLD   = 262144

    @dic : Pdfbox::Cos::Dictionary
    @x_height : Float32 = -Float32::INFINITY
    @cap_height : Float32 = -Float32::INFINITY
    @flags : Int32 = -1

    # Package-private constructor, for embedding.
    protected def initialize
      @dic = Pdfbox::Cos::Dictionary.new
      @dic[Pdfbox::Cos::Name::TYPE] = Pdfbox::Cos::Name::FONT_DESC
    end

    # Creates a PDFontDescriptor from a COS dictionary.
    def initialize(desc : Pdfbox::Cos::Dictionary)
      @dic = desc
    end

    # Convert this object to a COS object.
    def cos_object : Pdfbox::Cos::Dictionary
      @dic
    end

    # Flag convenience methods
    def fixed_pitch? : Bool
      flag_bit_on?(FLAG_FIXED_PITCH)
    end

    def fixed_pitch=(flag : Bool)
      set_flag_bit(FLAG_FIXED_PITCH, flag)
    end

    def serif? : Bool
      flag_bit_on?(FLAG_SERIF)
    end

    def serif=(flag : Bool)
      set_flag_bit(FLAG_SERIF, flag)
    end

    def symbolic? : Bool
      flag_bit_on?(FLAG_SYMBOLIC)
    end

    def symbolic=(flag : Bool)
      set_flag_bit(FLAG_SYMBOLIC, flag)
    end

    def script? : Bool
      flag_bit_on?(FLAG_SCRIPT)
    end

    def script=(flag : Bool)
      set_flag_bit(FLAG_SCRIPT, flag)
    end

    def non_symbolic? : Bool
      flag_bit_on?(FLAG_NON_SYMBOLIC)
    end

    def non_symbolic=(flag : Bool)
      set_flag_bit(FLAG_NON_SYMBOLIC, flag)
    end

    def italic? : Bool
      flag_bit_on?(FLAG_ITALIC)
    end

    def italic=(flag : Bool)
      set_flag_bit(FLAG_ITALIC, flag)
    end

    def all_cap? : Bool
      flag_bit_on?(FLAG_ALL_CAP)
    end

    def all_cap=(flag : Bool)
      set_flag_bit(FLAG_ALL_CAP, flag)
    end

    def small_cap? : Bool
      flag_bit_on?(FLAG_SMALL_CAP)
    end

    def small_cap=(flag : Bool)
      set_flag_bit(FLAG_SMALL_CAP, flag)
    end

    def force_bold? : Bool
      flag_bit_on?(FLAG_FORCE_BOLD)
    end

    def force_bold=(flag : Bool)
      set_flag_bit(FLAG_FORCE_BOLD, flag)
    end

    private def flag_bit_on?(bit : Int32) : Bool
      (flags & bit) != 0
    end

    private def set_flag_bit(bit : Int32, value : Bool)
      flags = self.flags
      if value
        flags = flags | bit
      else
        flags = flags & (~bit)
      end
      self.flags = flags
    end

    # Get the font name.
    def font_name : String?
      @dic.get_name_as_string(Pdfbox::Cos::Name::FONT_NAME)
    end

    # Set the font name.
    def font_name=(font_name : String?)
      if font_name
        @dic[Pdfbox::Cos::Name::FONT_NAME] = Pdfbox::Cos::Name.new(font_name)
      else
        @dic.delete(Pdfbox::Cos::Name::FONT_NAME)
      end
    end

    # A string representing the preferred font family.
    def font_family : String?
      @dic.get_string(Pdfbox::Cos::Name::FONT_FAMILY)
    end

    # Set the font family.
    def font_family=(font_family : String?)
      if font_family
        @dic[Pdfbox::Cos::Name::FONT_FAMILY] = Pdfbox::Cos::String.new(font_family)
      else
        @dic.delete(Pdfbox::Cos::Name::FONT_FAMILY)
      end
    end

    # The weight of the font.
    def font_weight : Float32
      @dic.get_float(Pdfbox::Cos::Name::FONT_WEIGHT, 0_f32)
    end

    # Set the weight of the font.
    def font_weight=(font_weight : Float32)
      @dic.set_float(Pdfbox::Cos::Name::FONT_WEIGHT, font_weight)
    end

    # A string representing the preferred font stretch.
    def font_stretch : String?
      @dic.get_name_as_string(Pdfbox::Cos::Name::FONT_STRETCH)
    end

    # Set the font stretch.
    def font_stretch=(font_stretch : String?)
      if font_stretch
        @dic[Pdfbox::Cos::Name::FONT_STRETCH] = Pdfbox::Cos::Name.new(font_stretch)
      else
        @dic.delete(Pdfbox::Cos::Name::FONT_STRETCH)
      end
    end

    # Get the font flags.
    def flags : Int32
      if @flags == -1
        @flags = @dic.get_int(Pdfbox::Cos::Name::FLAGS, 0).to_i32
      end
      @flags
    end

    # Set the font flags.
    def flags=(flags : Int32)
      @dic.set_int(Pdfbox::Cos::Name::FLAGS, flags)
      @flags = flags
    end

    # Get the fonts bounding box.
    def font_bounding_box : Common::PDRectangle?
      rect = @dic.get_array(Pdfbox::Cos::Name::FONT_BBOX)
      if rect
        Common::PDRectangle.new(rect)
      else
        nil
      end
    end

    # Set the fonts bounding box.
    def font_bounding_box=(rect : Common::PDRectangle?)
      array = nil
      if rect
        array = rect.cos_array
      end
      @dic[Pdfbox::Cos::Name::FONT_BBOX] = array
    end

    # Get the italic angle for the font.
    def italic_angle : Float32
      @dic.get_float(Pdfbox::Cos::Name::ITALIC_ANGLE, 0_f64).to_f32
    end

    # Set the italic angle for the font.
    def italic_angle=(angle : Float32)
      @dic.set_float(Pdfbox::Cos::Name::ITALIC_ANGLE, angle)
    end

    # Get the ascent for the font.
    def ascent : Float32
      @dic.get_float(Pdfbox::Cos::Name::ASCENT, 0_f64).to_f32
    end

    # Set the ascent for the font.
    def ascent=(ascent : Float32)
      @dic.set_float(Pdfbox::Cos::Name::ASCENT, ascent)
    end

    # Get the descent for the font.
    def descent : Float32
      @dic.get_float(Pdfbox::Cos::Name::DESCENT, 0_f64).to_f32
    end

    # Set the descent for the font.
    def descent=(descent : Float32)
      @dic.set_float(Pdfbox::Cos::Name::DESCENT, descent)
    end

    # Get the leading for the font.
    def leading : Float32
      @dic.get_float(Pdfbox::Cos::Name::LEADING, 0_f64).to_f32
    end

    # Set the leading for the font.
    def leading=(leading : Float32)
      @dic.set_float(Pdfbox::Cos::Name::LEADING, leading)
    end

    # Get the CapHeight for the font.
    def cap_height : Float32
      if @cap_height == -Float32::INFINITY
        # We observed a negative value being returned with
        # the Scheherazade font. PDFBOX-429 was logged for this.
        # We are not sure if returning the absolute value
        # is the correct fix, but it seems to work.
        @cap_height = @dic.get_float(Pdfbox::Cos::Name::CAP_HEIGHT, 0_f64).abs.to_f32
      end
      @cap_height
    end

    # Set the cap height for the font.
    def cap_height=(cap_height : Float32)
      @dic.set_float(Pdfbox::Cos::Name::CAP_HEIGHT, cap_height)
      @cap_height = cap_height
    end

    # Get the x height for the font.
    def x_height : Float32
      if @x_height == -Float32::INFINITY
        # We observed a negative value being returned with
        # the Scheherazade font. PDFBOX-429 was logged for this.
        # We are not sure if returning the absolute value
        # is the correct fix, but it seems to work.
        @x_height = @dic.get_float(Pdfbox::Cos::Name::XHEIGHT, 0_f64).abs.to_f32
      end
      @x_height
    end

    # Set the x height for the font.
    def x_height=(x_height : Float32)
      @dic.set_float(Pdfbox::Cos::Name::XHEIGHT, x_height)
      @x_height = x_height
    end

    # Get the stemV for the font.
    def stem_v : Float32
      @dic.get_float(Pdfbox::Cos::Name::STEM_V, 0_f64).to_f32
    end

    # Set the stem V for the font.
    def stem_v=(stem_v : Float32)
      @dic.set_float(Pdfbox::Cos::Name::STEM_V, stem_v)
    end

    # Get the stemH for the font.
    def stem_h : Float32
      @dic.get_float(Pdfbox::Cos::Name::STEM_H, 0_f64).to_f32
    end

    # Set the stem H for the font.
    def stem_h=(stem_h : Float32)
      @dic.set_float(Pdfbox::Cos::Name::STEM_H, stem_h)
    end

    # Get the average width for the font.
    def average_width : Float32
      @dic.get_float(Pdfbox::Cos::Name::AVG_WIDTH, 0_f64).to_f32
    end

    # Set the average width for the font.
    def average_width=(average_width : Float32)
      @dic.set_float(Pdfbox::Cos::Name::AVG_WIDTH, average_width)
    end

    # Get the max width for the font.
    def max_width : Float32
      @dic.get_float(Pdfbox::Cos::Name::MAX_WIDTH, 0_f64).to_f32
    end

    # Set the max width for the font.
    def max_width=(max_width : Float32)
      @dic.set_float(Pdfbox::Cos::Name::MAX_WIDTH, max_width)
    end

    # Returns true if widths are present in the font descriptor.
    def has_widths? : Bool
      @dic.has_key?(Pdfbox::Cos::Name::WIDTHS) || @dic.has_key?(Pdfbox::Cos::Name::MISSING_WIDTH)
    end

    # Returns true if the missing widths entry is present in the font descriptor.
    def has_missing_width? : Bool
      @dic.has_key?(Pdfbox::Cos::Name::MISSING_WIDTH)
    end

    # Get the missing width for the font from the /MissingWidth dictionary entry.
    def missing_width : Float32
      @dic.get_float(Pdfbox::Cos::Name::MISSING_WIDTH, 0_f64).to_f32
    end

    # Set the missing width for the font.
    def missing_width=(missing_width : Float32)
      @dic.set_float(Pdfbox::Cos::Name::MISSING_WIDTH, missing_width)
    end

    # Get the character set for the font.
    def char_set : String?
      @dic.get_string(Pdfbox::Cos::Name::CHAR_SET)
    end

    # Set the character set for the font.
    def character_set=(char_set : String?)
      name = nil
      if char_set
        name = Pdfbox::Cos::String.new(char_set)
      end
      @dic[Pdfbox::Cos::Name::CHAR_SET] = name
    end

    # A stream containing a Type 1 font program.
    def font_file : Common::PDStream?
      stream = @dic.get_stream(Pdfbox::Cos::Name::FONT_FILE)
      if stream
        Common::PDStream.new(stream)
      else
        nil
      end
    end

    # Set the type 1 font program.
    def font_file=(type1_stream : Common::PDStream?)
      @dic[Pdfbox::Cos::Name::FONT_FILE] = type1_stream
    end

    # A stream containing a true type font program.
    def font_file2 : Common::PDStream?
      stream = @dic.get_stream(Pdfbox::Cos::Name::FONT_FILE2)
      if stream
        Common::PDStream.new(stream)
      else
        nil
      end
    end

    # Set the true type font program.
    def font_file2=(ttf_stream : Common::PDStream?)
      @dic[Pdfbox::Cos::Name::FONT_FILE2] = ttf_stream
    end

    # A stream containing a font program that is not true type or type 1.
    def font_file3 : Common::PDStream?
      stream = @dic.get_stream(Pdfbox::Cos::Name::FONT_FILE3)
      if stream
        Common::PDStream.new(stream)
      else
        nil
      end
    end

    # Set a stream containing a font program that is not true type or type 1.
    def font_file3=(stream : Common::PDStream?)
      @dic[Pdfbox::Cos::Name::FONT_FILE3] = stream
    end

    # Get the CIDSet stream.
    def cid_set : Common::PDStream?
      cid_set = @dic.get_stream(Pdfbox::Cos::Name::CID_SET)
      if cid_set
        Common::PDStream.new(cid_set)
      else
        nil
      end
    end

    # Set a stream containing a CIDSet.
    def cid_set=(stream : Common::PDStream?)
      @dic[Pdfbox::Cos::Name::CID_SET] = stream
    end

    # Returns the Panose entry of the Style dictionary, if any.
    def panose : PDPanose?
      style = @dic.get_dictionary(Pdfbox::Cos::Name::STYLE)
      return unless style
      value = style[Pdfbox::Cos::Name::PANOSE]?
      return unless value
      # Dereference COSObject if needed
      if value.is_a?(Pdfbox::Cos::Object)
        value = value.object
      end
      # Skip COSNull
      return if value.is_a?(Pdfbox::Cos::Null)
      if value.is_a?(Pdfbox::Cos::String)
        bytes = value.bytes
        if bytes.size >= PDPanose::LENGTH
          return PDPanose.new(bytes)
        end
      end
      nil
    end
  end
end
