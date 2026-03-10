# Simple font base class
# Corresponds to PDSimpleFont in Apache PDFBox
require "./encoding"

abstract class Pdfbox::Pdmodel::Font::PDSimpleFont < Pdfbox::Pdmodel::Font::PDFont
  Log = ::Log.for(self)

  protected getter encoding : Pdfbox::Pdmodel::Font::Encoding?
  protected getter glyph_list : Pdfbox::Pdmodel::Font::GlyphList?

  @is_symbolic : Bool?
  @no_unicode = Set(Int32).new

  # Constructor for embedding.
  protected def initialize
    super
  end

  # Constructor for Standard 14.
  protected def initialize(base_font : Pdfbox::Pdmodel::Font::Standard14Fonts::FontName)
    super(base_font)
    assign_glyph_list(base_font)
  end

  # Constructor.
  protected def initialize(font_dictionary : Pdfbox::Cos::Dictionary)
    super(font_dictionary)
  end

  # Reads the Encoding from the Font dictionary or the embedded or substituted font file.
  # Must be called at the end of any subclass constructors.
  protected def read_encoding : Nil
    encoding_base = @dict[Pdfbox::Cos::Name::ENCODING]?
    if encoding_base.is_a?(Pdfbox::Cos::Name)
      encoding_name = encoding_base
      if font_name == Standard14Fonts::FontName::ZAPF_DINGBATS && !embedded?
        # PDFBOX- and PDF.js issue 16464: ignore other encodings
        # this segment will work only if read_encoding() is called after the data
        # for get_name() and embedded?() is available
        @encoding = Encoding::ZapfDingbatsEncoding::INSTANCE
      else
        @encoding = Encoding.get_instance(encoding_name)
        if @encoding.nil?
          Log.warn { "Unknown encoding: #{encoding_name}" }
          @encoding = read_encoding_from_font # fallback
        end
      end
    elsif encoding_base.is_a?(Pdfbox::Cos::Dictionary)
      encoding_dict = encoding_base
      built_in = nil
      symbolic = symbolic_flag

      base_encoding = encoding_dict[Pdfbox::Cos::Name::BASE_ENCODING]?
      has_valid_base_encoding = base_encoding.is_a?(Pdfbox::Cos::Name) &&
                                !Encoding.get_instance(base_encoding).nil?

      if !has_valid_base_encoding && symbolic == true
        built_in = read_encoding_from_font
      end

      symbolic = false if symbolic.nil?
      @encoding = DictionaryEncoding.new(encoding_dict, !symbolic, built_in)
    else
      @encoding = read_encoding_from_font
    end
    # normalise the standard 14 name, e.g "Symbol,Italic" -> "Symbol"
    standard14_name = Standard14Fonts.get_mapped_font_name(name)
    assign_glyph_list(standard14_name)
  end

  # Called by read_encoding if the encoding needs to be extracted from the font file.
  protected abstract def read_encoding_from_font : Pdfbox::Pdmodel::Font::Encoding

  # Returns the Encoding.
  def encoding : Pdfbox::Pdmodel::Font::Encoding
    @encoding || raise "PDFBox bug: encoding should not be nil"
  end

  # Returns the glyph list.
  def glyph_list : Pdfbox::Pdmodel::Font::GlyphList
    @glyph_list || raise "PDFBox bug: glyph list should not be nil"
  end

  # Returns true if the font is a symbolic (that is, it does not use the Adobe Standard Roman character set).
  def symbolic? : Bool
    if @is_symbolic.nil?
      result = font_symbolic?
      if !result.nil?
        @is_symbolic = result
      else
        # unless we can prove that the font is non-symbolic, we assume that it is not
        @is_symbolic = true
      end
    end
    @is_symbolic || raise "PDFBox bug: symbolic flag should not be nil"
  end

  # Internal implementation of symbolic?, allowing for the fact that the result may be indeterminate.
  protected def font_symbolic? : Bool?
    result = symbolic_flag
    return result unless result.nil?

    if standard14?
      mapped_name = Standard14Fonts.get_mapped_font_name(name)
      mapped_name == Standard14Fonts::FontName::SYMBOL || mapped_name == Standard14Fonts::FontName::ZAPF_DINGBATS
    else
      if @encoding.nil?
        # check, should never happen
        unless self.is_a?(PDTrueTypeFont)
          raise "PDFBox bug: encoding should not be nil!"
        end

        # TTF without its non-symbolic flag set must be symbolic
        true
      elsif @encoding.is_a?(WinAnsiEncoding) ||
            @encoding.is_a?(MacRomanEncoding) ||
            @encoding.is_a?(StandardEncoding)
        false
      elsif @encoding.is_a?(DictionaryEncoding)
        # each name in Differences array must also be in the latin character set
        @encoding.as(DictionaryEncoding).differences.each_value do |name|
          next if name == ".notdef"
          unless WinAnsiEncoding::INSTANCE.contains(name) &&
                 MacRomanEncoding::INSTANCE.contains(name) &&
                 StandardEncoding::INSTANCE.contains(name)
            return true
          end
        end
        false
      else
        # we don't know
        nil
      end
    end
  end

  # Returns the value of the symbolic flag, allowing for the fact that the result may be indeterminate.
  protected def symbolic_flag : Bool?
    fd = font_descriptor
    return fd.symbolic? unless fd.nil?
    nil
  end

  # Override PDFont methods

  def vertical? : Bool
    false
  end

  protected def get_standard14_width(code : Int32) : Float32
    afm = get_standard14_afm
    if afm
      name_in_afm = encoding.get_name(code)

      # the Adobe AFMs don't include .notdef, but Acrobat uses 250, test with PDFBOX-2334
      if name_in_afm == ".notdef"
        return 250.0_f32
      end

      if name_in_afm == "nbspace"
        # PDFBOX-4944: nbspace is missing in AFM files,
        # but PDF specification tells "it shall be typographically the same as SPACE"
        name_in_afm = "space"
      elsif name_in_afm == "sfthyphen"
        # PDFBOX-5115: sfthyphen is missing in AFM files,
        # but PDF specification tells "it shall be typographically the same as hyphen"
        name_in_afm = "hyphen"
      end

      return afm.character_width(name_in_afm)
    end
    raise "No AFM"
  end

  def standard14? : Bool
    # this logic is based on Acrobat's behaviour, see PDFBOX-2372
    # the Encoding entry cannot have Differences if we want "standard 14" font handling
    if encoding.is_a?(DictionaryEncoding)
      dictionary = encoding.as(DictionaryEncoding)
      unless dictionary.differences.empty?
        # we also require that the differences are actually different, see PDFBOX-1900 with
        # the file from PDFBOX-2192 on Windows
        base_encoding = dictionary.base_encoding
        return false if base_encoding.nil?
        dictionary.differences.each do |key, value|
          if value != base_encoding.get_name(key)
            return false
          end
        end
      end
    end
    super
  end

  # Abstract methods from PDSimpleFont

  # Returns the path for the character with the given name.
  abstract def get_path(name : String) # TODO: Return GeneralPath type

  # Returns true if the font contains the character with the given name.
  abstract def has_glyph?(name : String) : Bool

  # Returns the embedded or system font used for rendering.
  abstract def font_box_font # TODO: Return FontBoxFont type

  # Returns the Unicode string for the given character code.
  def to_unicode(code : Int32) : String?
    to_unicode(code, GlyphList.adobe_glyph_list)
  end

  # Returns the Unicode string for the given character code using a custom glyph list.
  def to_unicode(code : Int32, custom_glyph_list : GlyphList) : String?
    # allow the glyph list to be overridden for the purpose of extracting Unicode
    # we only do this when the font's glyph list is the AGL, to avoid breaking Zapf Dingbats
    unicode_glyph_list = if @glyph_list == GlyphList.adobe_glyph_list
                           custom_glyph_list
                         else
                           @glyph_list
                         end

    # first try to use a ToUnicode CMap
    unicode = super.to_unicode(code)
    return unicode unless unicode.nil?

    # if the font is a "simple font" and uses MacRoman/MacExpert/WinAnsi[Encoding]
    # or has Differences with names from only Adobe Standard and/or Symbol, then:
    #
    #    a) Map the character codes to names
    #    b) Look up the name in the Adobe Glyph List to obtain the Unicode value

    if encoding = @encoding
      name = encoding.get_name(code)
      unicode = unicode_glyph_list.to_unicode(name)
      return unicode unless unicode.nil?
    end

    # if no value has been produced, there is no way to obtain Unicode for the character.
    if Log.warn? && !@no_unicode.includes?(code)
      # we keep track of which warnings have been issued, so we don't log multiple times
      @no_unicode.add(code)
      if name
        Log.warn { "No Unicode mapping for #{name} (#{code}) in font #{name}" }
      else
        Log.warn { "No Unicode mapping for code #{code} in font #{name}" }
      end
    end
    nil
  end

  # Subsetting not supported for simple fonts
  def add_to_subset(code_point : Int32) : Nil
    raise "Unsupported operation"
  end

  def subset : Nil
    raise "Unsupported operation"
  end

  def will_be_subset? : Bool
    false
  end

  def has_explicit_width?(code : Int32) : Bool
    if @dict.has_key?(Pdfbox::Cos::Name::WIDTHS)
      first_char = @dict[Pdfbox::Cos::Name::FIRST_CHAR]?.try(&.as_i) || -1
      if code >= first_char && code - first_char < widths.size
        return true
      end
    end
    false
  end

  # Helper method to assign glyph list based on font name
  private def assign_glyph_list(font_name : Pdfbox::Pdmodel::Font::Standard14Fonts::FontName?) : Nil
    # assign the glyph list based on the font
    if font_name == Standard14Fonts::FontName::ZAPF_DINGBATS
      @glyph_list = GlyphList.zapf_dingbats
    else
      @glyph_list = GlyphList.adobe_glyph_list
    end
  end

  # Helper to get font name
  private def font_name : Pdfbox::Pdmodel::Font::Standard14Fonts::FontName?
    Standard14Fonts.get_mapped_font_name(name)
  end

  # Returns true if the given bounding box is non-zero.
  private def non_zero_bounding_box?(bbox : BoundingBox) : Bool
    # TODO: Implement proper bounding box check
    false
  end
end
