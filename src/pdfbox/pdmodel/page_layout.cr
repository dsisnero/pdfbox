module Pdfbox::Pdmodel
  # A name object specifying the page layout to use when the document is opened.
  enum PageLayout
    SINGLE_PAGE
    ONE_COLUMN
    TWO_COLUMN_LEFT
    TWO_COLUMN_RIGHT
    TWO_PAGE_LEFT
    TWO_PAGE_RIGHT

    def self.from_string(value : String) : self
      case value
      when "SinglePage"     then SINGLE_PAGE
      when "OneColumn"      then ONE_COLUMN
      when "TwoColumnLeft"  then TWO_COLUMN_LEFT
      when "TwoColumnRight" then TWO_COLUMN_RIGHT
      when "TwoPageLeft"    then TWO_PAGE_LEFT
      when "TwoPageRight"   then TWO_PAGE_RIGHT
      else
        raise ArgumentError.new(value)
      end
    end

    def string_value : String
      case self
      when .single_page?      then "SinglePage"
      when .one_column?       then "OneColumn"
      when .two_column_left?  then "TwoColumnLeft"
      when .two_column_right? then "TwoColumnRight"
      when .two_page_left?    then "TwoPageLeft"
      when .two_page_right?   then "TwoPageRight"
      else
        raise ArgumentError.new(to_s)
      end
    end
  end
end
