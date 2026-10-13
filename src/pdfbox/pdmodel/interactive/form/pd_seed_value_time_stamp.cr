module Pdfbox::Pdmodel::Interactive::Form
  # A seed value time stamp dictionary (/TimeStamp). Corresponds to
  # PDSeedValueTimeStamp in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueTimeStamp.java
  class PDSeedValueTimeStamp
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
      @dictionary.direct = true
    end

    def initialize(@dictionary : Cos::Dictionary)
      @dictionary.direct = true
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # The URL (/URL).
    def url : String?
      @dictionary.get_string(Cos::Name.new("URL"))
    end

    def url=(url : String) : Nil
      @dictionary.set_string(Cos::Name.new("URL"), url)
    end

    # Whether a timestamp is required (/Ff != 0).
    def timestamp_required? : Bool
      @dictionary.get_int(Cos::Name.new("Ff"), 0_i64) != 0
    end

    def timestamp_required=(flag : Bool) : Nil
      @dictionary.set_int(Cos::Name.new("Ff"), flag ? 1 : 0)
    end
  end
end
