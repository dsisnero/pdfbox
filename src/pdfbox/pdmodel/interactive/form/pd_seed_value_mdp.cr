module Pdfbox::Pdmodel::Interactive::Form
  # A seed value MDP dictionary (/MDP). Corresponds to PDSeedValueMDP in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueMDP.java
  class PDSeedValueMDP
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

    # The P value (/P).
    def p : Int32
      @dictionary.get_int(Cos::Name.new("P"), 0_i64).to_i32
    end

    # Sets the P value (/P); only 0..3 are allowed (Java IllegalArgumentException).
    def p=(p : Int32) : Nil
      if p < 0 || p > 3
        raise ArgumentError.new("Only values between 0 and 3 are allowed.")
      end
      @dictionary.set_int(Cos::Name.new("P"), p)
    end
  end
end
