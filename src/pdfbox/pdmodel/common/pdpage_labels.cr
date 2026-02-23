# Represents the page label dictionary of a document.
class Pdfbox::Pdmodel::Common::PDPageLabels
  include COSObjectable

  Log = ::Log.for(self)

  @labels : Hash(Int32, PDPageLabelRange)
  @doc : ::Pdfbox::Pdmodel::Document

  # Creates an empty page label dictionary for the given document.
  #
  # Note that the page label dictionary won't be automatically added to the
  # document; you will still need to do it manually (see
  # Pdfbox::Pdmodel::DocumentCatalog#page_labels=).
  #
  # @param document The document the page label dictionary is created for.
  # @see Pdfbox::Pdmodel::DocumentCatalog#page_labels=
  def initialize(document : ::Pdfbox::Pdmodel::Document)
    @labels = {} of Int32 => PDPageLabelRange
    @doc = document
    default_range = PDPageLabelRange.new
    default_range.style = PDPageLabelRange::STYLE_DECIMAL
    @labels[0] = default_range
  end

  # Creates a page label dictionary for a document using the information in
  # the given COS dictionary.
  #
  # Note that the page label dictionary won't be automatically added to the
  # document; you will still need to do it manually (see
  # Pdfbox::Pdmodel::DocumentCatalog#page_labels=).
  #
  # @param document The document the page label dictionary is created for.
  # @param dict an existing page label dictionary
  # @see Pdfbox::Pdmodel::DocumentCatalog#page_labels=
  def initialize(document : ::Pdfbox::Pdmodel::Document, dict : Cos::Dictionary?)
    @labels = {} of Int32 => PDPageLabelRange
    @doc = document
    default_range = PDPageLabelRange.new
    default_range.style = PDPageLabelRange::STYLE_DECIMAL
    @labels[0] = default_range
    return if dict.nil?
    root = PDNumberTreeNode(PDPageLabelRange).new(dict) do |base|
      case base
      when Cos::Dictionary
        PDPageLabelRange.new(base)
      else
        raise "Unexpected COS type in page label range: #{base.class}"
      end
    end
    find_labels(root)
  end

  private def find_labels(node : PDNumberTreeNode(PDPageLabelRange)) : Nil
    kids = node.kids
    if kids
      kids.each do |kid|
        find_labels(kid)
      end
    else
      numbers = node.numbers
      if numbers
        numbers.each do |key, page_label_range|
          if key >= 0
            @labels[key] = page_label_range
          end
        end
      end
    end
  end

  # Returns the number of page label ranges.
  #
  # This will be always >= 1, as the required default entry for the page
  # range starting at the first page is added automatically by this
  # implementation (see PDF32000-1:2008, p. 375).
  def page_range_count : Int32
    @labels.size
  end

  # Returns the page label range starting at the given page, or `nil`
  # if no such range is defined.
  #
  # @param start_page the 0-based page index representing the start page of the page
  # range the item is defined for.
  # @return the page label range or `nil` if no label range is defined
  # for the given start page.
  def page_label_range(start_page : Int32) : PDPageLabelRange?
    @labels[start_page]?
  end

  # Sets the page label range beginning at the specified start page.
  #
  # @param start_page the 0-based index of the page representing the start of the
  # page label range.
  # @param item the page label item to set.
  # @raise ArgumentError if the startPage parameter is < 0.
  def set_label_item(start_page : Int32, item : PDPageLabelRange) : Nil
    if start_page < 0
      raise ArgumentError.new("startPage parameter of setLabelItem may not be < 0")
    end
    @labels[start_page] = item
  end

  # Convert this standard java object to a COS object.
  #
  # @return The cos object that matches this Java object.
  def cos_object : Cos::Base
    arr = Cos::Array.new
    @labels.each do |key, value|
      arr.add(Cos::Integer.new(key.to_i64))
      arr.add(value.cos_object)
    end
    dict = Cos::Dictionary.new
    dict.set_item(Cos::Name::NUMS, arr)
    dict
  end

  # Returns an ordered set of page indices having a page label range.
  #
  # @return set of page indices.
  def page_indices : Set(Int32)
    Set.new(@labels.keys)
  end

  # Returns a mapping with computed page labels as keys and corresponding
  # 0-based page indices as values. The returned map will contain at most as
  # much entries as the document has pages.
  #
  # NOTE: If the document contains duplicate page labels,
  # the returned map will contain *less* entries than the document has
  # pages. The page index returned in this case is the *highest* index
  # among all pages sharing the same label.
  #
  # @return a mapping from labels to 0-based page indices.
  def page_indices_by_labels : Hash(String, Int32)
    number_of_pages = @doc.page_count
    label_map = {} of String => Int32
    compute_labels(number_of_pages) do |page_index, label|
      label_map[label] = page_index
    end
    label_map
  end

  # Returns a mapping with 0-based page indices as keys and corresponding
  # page labels as values as an array. The array will have exactly as much
  # entries as the document has pages.
  #
  # @return an array mapping from 0-based page indices to labels.
  def labels_by_page_indices : Array(String)
    number_of_pages = @doc.page_count
    map = Array(String).new(number_of_pages, "")
    compute_labels(number_of_pages) do |page_index, label|
      if page_index < number_of_pages
        map[page_index] = label
      end
    end
    map
  end

  private def compute_labels(number_of_pages : Int32, &block : Int32, String -> Nil) : Nil
    sorted_entries = @labels.to_a.sort_by { |key, _| key }
    return if sorted_entries.empty?
    page_index = 0
    last_entry = sorted_entries.first
    sorted_entries[1..].each do |entry|
      num_pages = entry[0] - last_entry[0]
      gen = LabelGenerator.new(last_entry[1], num_pages)
      while gen.has_next?
        block.call(page_index, gen.next)
        page_index += 1
      end
      last_entry = entry
    end
    num_pages = number_of_pages - last_entry[0]
    gen = LabelGenerator.new(last_entry[1], num_pages)
    while gen.has_next?
      block.call(page_index, gen.next)
      page_index += 1
    end
  end

  private class LabelGenerator
    include Iterator(String)

    @label_info : PDPageLabelRange
    @num_pages : Int32
    @current_page : Int32

    def initialize(@label_info : PDPageLabelRange, @num_pages : Int32)
      @current_page = 0
    end

    def has_next? : Bool
      @current_page < @num_pages
    end

    def next : String
      raise StopIteration.new unless has_next?
      buf = String::Builder.new
      prefix = @label_info.prefix
      if prefix
        # there may be some labels with some null bytes at the end
        # which will lead to an incomplete output, see PDFBOX-1047
        index = prefix.index('\0')
        if index
          prefix = prefix[0, index]
        end
        buf << prefix
      end
      style = @label_info.style
      if style
        buf << get_number(@label_info.start + @current_page, style)
      end
      @current_page += 1
      buf.to_s
    end

    private def get_number(page_index : Int32, style : String) : String
      case style
      when PDPageLabelRange::STYLE_DECIMAL
        page_index.to_s
      when PDPageLabelRange::STYLE_LETTERS_LOWER
        make_letter_label(page_index)
      when PDPageLabelRange::STYLE_LETTERS_UPPER
        make_letter_label(page_index).upcase
      when PDPageLabelRange::STYLE_ROMAN_LOWER
        make_roman_label(page_index)
      when PDPageLabelRange::STYLE_ROMAN_UPPER
        make_roman_label(page_index).upcase
      else
        # Fall back to decimals.
        page_index.to_s
      end
    end

    private ROMANS = [
      ["", "i", "ii", "iii", "iv", "v", "vi", "vii", "viii", "ix"],
      ["", "x", "xx", "xxx", "xl", "l", "lx", "lxx", "lxxx", "xc"],
      ["", "c", "cc", "ccc", "cd", "d", "dc", "dcc", "dccc", "cm"],
    ]

    private def make_roman_label(page_index : Int32) : String
      buf = String::Builder.new
      power = 0
      num = page_index
      while power < 3 && num > 0
        buf.insert(0, ROMANS[power][num % 10])
        num //= 10
        power += 1
      end
      # Prepend as many m as there are thousands (which is
      # incorrect by the roman numeral rules for numbers > 3999,
      # but is unbounded and Adobe Acrobat does it this way).
      num.times do
        buf.insert(0, 'm')
      end
      buf.to_s
    end

    # a..z, aa..zz, aaa..zzz ... labeling as described in PDF32000-1:2008,
    # Table 159, Page 375.
    private def make_letter_label(num : Int32) : String
      buf = String::Builder.new
      num_letters = num // 26 + (num % 26).sign
      letter = num % 26 + 26 * (1 - (num % 26).sign) + 'a'.ord - 1
      num_letters.times do
        buf << letter.chr
      end
      buf.to_s
    end
  end
end
