# Soft mask for transparency compositing.
# Port of Apache PDFBox PDSoftMask (stub implementation).
module Pdfbox::Pdmodel::Graphics::State
  class PDSoftMask
    property dictionary : Pdfbox::Cos::Dictionary

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    # Creates a PDSoftMask from a COSBase dictionary.
    # Returns nil if the mask is "None" or invalid.
    def self.create(dictionary : Pdfbox::Cos::Base) : PDSoftMask?
      case dictionary
      when Pdfbox::Cos::Name
        return nil if dictionary.name == "None"
        nil
      when Pdfbox::Cos::Dictionary
        PDSoftMask.new(dictionary)
      else
        nil
      end
    end
  end
end
