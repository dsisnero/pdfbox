# PostScript glyph list, maps glyph names to sequences of Unicode characters.
# Instances of GlyphList are immutable.
# Corresponds to GlyphList in Apache PDFBox.

class Pdfbox::Pdmodel::Font::GlyphList
  Log = ::Log.for(self)

  # Adobe Glyph List (AGL)
  private DEFAULT = load("glyphlist.txt", 4281)

  # Zapf Dingbats has its own glyph list
  private ZAPF_DINGBATS = load("zapfdingbats.txt", 201)

  # Returns the Adobe Glyph List (AGL).
  def self.adobe_glyph_list : GlyphList
    DEFAULT
  end

  # Returns the Zapf Dingbats glyph list.
  def self.zapf_dingbats : GlyphList
    ZAPF_DINGBATS
  end

  # Loads a glyph list from disk.
  private def self.load(filename : String, number_of_entries : Int32) : GlyphList
    path = File.join(__DIR__, "../../../../../vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/glyphlist", filename)
    begin
      file = File.open(path, "r")
      GlyphList.new(file, number_of_entries)
    rescue ex : File::NotFoundError
      Log.error { "GlyphList '#{path}' not found: #{ex.message}" }
      raise "GlyphList '#{filename}' not found"
    end
  end

  # read-only mappings, never modified outside GlyphList's constructor
  @name_to_unicode : Hash(String, String)
  @unicode_to_name : Hash(String, String)

  # additional read/write cache for uniXXXX names
  @uni_name_to_unicode_cache : Hash(String, String)

  # Creates a new GlyphList from a glyph list file.
  #
  # @param number_of_entries number of expected values used to preallocate the correct amount of memory
  # @param input glyph list in Adobe format
  def initialize(input : ::IO, number_of_entries : Int32)
    @name_to_unicode = Hash(String, String).new(initial_capacity: number_of_entries)
    @unicode_to_name = Hash(String, String).new(initial_capacity: number_of_entries)
    @uni_name_to_unicode_cache = Hash(String, String).new
    load_list(input)
  end

  # Creates a new GlyphList from multiple glyph list files.
  #
  # @param glyph_list an existing glyph list to be copied
  # @param input glyph list in Adobe format
  def initialize(glyph_list : GlyphList, input : ::IO)
    @name_to_unicode = glyph_list.@name_to_unicode.dup
    @unicode_to_name = glyph_list.@unicode_to_name.dup
    @uni_name_to_unicode_cache = Hash(String, String).new
    load_list(input)
  end

  private def load_list(input : ::IO) : Nil
    input.each_line do |line|
      next if line.starts_with?('#')
      parts = line.split(';')
      if parts.size < 2
        raise "Invalid glyph list entry: #{line}"
      end

      name = parts[0]
      unicode_list = parts[1].split(' ')

      code_points = unicode_list.map(&.to_i(16))
      string = String.build do |builder|
        code_points.each do |code_point|
          builder << code_point.chr
        end
      end

      # forward mapping
      old_mapping = @name_to_unicode[name]?
      @name_to_unicode[name] = string
      if old_mapping
        Log.warn { "duplicate value for #{name} -> #{parts[1]} #{old_mapping}" }
      end

      # reverse mapping
      # PDFBOX-3884: take the various standard encodings as canonical,
      # e.g. tilde over ilde
      # TODO: Implement force_override logic once all encodings are fully implemented
      # For now, always use put_if_absent to avoid missing encoding tables
      @unicode_to_name.put_if_absent(string, name)
    end
  end

  # Returns the name for the given Unicode code point.
  #
  # @param code_point Unicode code point
  # @return PostScript glyph name, or ".notdef"
  def code_point_to_name(code_point : Int32) : String
    string = String.new(code_point.chr)
    @unicode_to_name[string]? || ".notdef"
  end

  # Returns the name for a given sequence of Unicode characters.
  #
  # @param unicode_sequence sequence of Unicode characters
  # @return PostScript glyph name, or ".notdef"
  def sequence_to_name(unicode_sequence : String) : String
    @unicode_to_name[unicode_sequence]? || ".notdef"
  end

  # Returns the Unicode character sequence for the given glyph name, or nil if there isn't any.
  #
  # @param name PostScript glyph name
  # @return Unicode character(s), or nil.
  def to_unicode(name : String) : String?
    return nil if name.nil?

    unicode = @name_to_unicode[name]?
    return unicode if unicode

    # separate read/write cache for thread safety
    unicode = @uni_name_to_unicode_cache[name]?
    if unicode.nil?
      # test if we have a suffix and if so remove it
      if name.includes?('.')
        unicode = to_unicode(name[0...name.index!('.')])
      elsif (name.size == 7 && name.starts_with?("uni")) ||
            (name.size == 5 && name.starts_with?("u"))
        # test for Unicode name in the format uniXXXX/uXXXX where X is hex
        start = name.size == 7 ? 3 : 1
        begin
          code_point = name[start...start + 4].to_i(16)
          if code_point > 0xD7FF && code_point < 0xE000
            Log.warn { "Unicode character name with disallowed code area: #{name}" }
          else
            unicode = code_point.chr.to_s
          end
        rescue ArgumentError
          Log.warn { "Not a number in Unicode character name: #{name}" }
        end
      end
      if unicode
        # null value not allowed in ConcurrentHashMap (but we use regular Hash)
        @uni_name_to_unicode_cache[name] = unicode
      end
    end
    unicode
  end
end
