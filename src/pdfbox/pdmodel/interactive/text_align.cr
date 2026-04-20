module Pdfbox::Pdmodel::Interactive
  enum TextAlign
    LEFT    = 0
    CENTER  = 1
    RIGHT   = 2
    JUSTIFY = 4

    def self.value_of(alignment : Int) : self
      from_value?(alignment) || LEFT
    end
  end
end
