# Placeholder for PDPageDestination
module Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination
  class PDPageDestination
    @dict : Cos::Dictionary

    def initialize
      @dict = Cos::Dictionary.new
    end

    def initialize(dict : Cos::Dictionary)
      @dict = dict
    end

    def cos_object : Cos::Dictionary
      @dict
    end
  end
end
