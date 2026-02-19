module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  class PDMarkedContentReference
    TYPE = "MCR"

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name("Type", TYPE)
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dictionary
    end

    def mcid : Int32
      value = @dictionary[Pdfbox::Cos::Name.new("MCID")]
      value.as?(Pdfbox::Cos::Integer).try(&.value.to_i32) || 0
    end

    def mcid=(mcid : Int32 | Int64 | Int) : Int32
      mcid_i32 = mcid.to_i32
      if mcid_i32 < 0
        raise ArgumentError.new("MCID is negative")
      end
      @dictionary.set_int("MCID", mcid_i32)
      mcid_i32
    end
  end
end
