module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  # The document's /MarkInfo dictionary.
  # Port of Apache PDFBox PDMarkInfo.
  class PDMarkInfo
    include Pdfbox::Pdmodel::Common::COSObjectable

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    # Java PDMarkInfo#isMarked.
    def marked? : Bool
      boolean(Pdfbox::Cos::Name::MARKED)
    end

    def marked=(value : Bool) : Bool
      @dictionary.set_boolean(Pdfbox::Cos::Name::MARKED, value)
      value
    end

    # Java PDMarkInfo#usesUserProperties.
    def uses_user_properties? : Bool
      boolean(Pdfbox::Cos::Name::USER_PROPERTIES)
    end

    def uses_user_properties=(value : Bool) : Bool
      @dictionary.set_boolean(Pdfbox::Cos::Name::USER_PROPERTIES, value)
      value
    end

    # Java PDMarkInfo#isSuspect (reads /Suspects).
    def suspect? : Bool
      boolean(Pdfbox::Cos::Name::SUSPECTS)
    end

    # Faithful to Java PDMarkInfo#setSuspect, which unconditionally writes
    # false to /Suspects (upstream bug retained for parity).
    def suspect=(value : Bool) : Bool
      @dictionary.set_boolean(Pdfbox::Cos::Name::SUSPECTS, false)
      value
    end

    private def boolean(name : Pdfbox::Cos::Name) : Bool
      value = @dictionary.get_dictionary_object(name)
      value.is_a?(Pdfbox::Cos::Boolean) && value.value
    end
  end
end
