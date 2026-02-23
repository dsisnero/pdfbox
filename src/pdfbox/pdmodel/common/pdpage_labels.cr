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
end
