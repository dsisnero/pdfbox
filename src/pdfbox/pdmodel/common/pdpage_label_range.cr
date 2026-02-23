# This class contains information for a page label range.
#
# @see PDPageLabels
class Pdfbox::Pdmodel::Common::PDPageLabelRange
  include COSObjectable

  Log = ::Log.for(self)

  private KEY_START  = Cos::Name::ST
  private KEY_PREFIX = Cos::Name::P
  private KEY_STYLE  = Cos::Name::S

  # Decimal page numbering style (1, 2, 3, ...).
  STYLE_DECIMAL = "D"

  # Roman numbers (upper case) numbering style (I, II, III, IV, ...).
  STYLE_ROMAN_UPPER = "R"

  # Roman numbers (lower case) numbering style (i, ii, iii, iv, ...).
  STYLE_ROMAN_LOWER = "r"

  # Letter (upper case) numbering style (A, B, ..., Z, AA, BB, ..., ZZ, AAA, ...).
  STYLE_LETTERS_UPPER = "A"

  # Letter (lower case) numbering style (a, b, ..., z, aa, bb, ..., zz, aaa, ...).
  STYLE_LETTERS_LOWER = "a"

  @root : Cos::Dictionary

  # Creates a new empty page label range object.
  def initialize
    @root = Cos::Dictionary.new
  end

  # Creates a new page label range object from the given dictionary.
  def initialize(dict : Cos::Dictionary)
    @root = dict
  end

  # Returns the underlying dictionary.
  def cos_object : Cos::Dictionary
    @root
  end

  # Returns the numbering style for this page range.
  #
  # @return one of the STYLE_* constants
  def style : String?
    @root[KEY_STYLE].as?(Cos::Name).try(&.value)
  end

  # Sets the numbering style for this page range.
  #
  # @param style one of the STYLE_* constants or `nil` if no page numbering is desired.
  def style=(style : String?) : Nil
    if style
      @root.set_name(KEY_STYLE, style)
    else
      @root.delete(KEY_STYLE)
    end
  end

  # Returns the start value for page numbering in this page range.
  #
  # @return a positive integer the start value for numbering.
  def start : Int32
    @root[KEY_START].as?(Cos::Integer).try(&.value.to_i32) || 1
  end

  # Sets the start value for page numbering in this page range.
  #
  # @param start a positive integer representing the start value.
  # @raise ArgumentError if `start` is not a positive integer
  def start=(start : Int32) : Nil
    if start <= 0
      raise ArgumentError.new("The page numbering start value must be a positive integer")
    end
    @root.set_int(KEY_START, start.to_i64)
  end

  # Returns the page label prefix for this page range.
  #
  # @return the page label prefix for this page range, or `nil` if no prefix has been defined.
  def prefix : String?
    @root[KEY_PREFIX].as?(Cos::String).try(&.value)
  end

  # Sets the page label prefix for this page range.
  #
  # @param prefix the page label prefix for this page range, or `nil` to unset the prefix.
  def prefix=(prefix : String?) : Nil
    if prefix
      @root.set_string(KEY_PREFIX, prefix)
    else
      @root.delete(KEY_PREFIX)
    end
  end
end
