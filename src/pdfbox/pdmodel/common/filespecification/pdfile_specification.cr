# Abstract base class for file specifications
# A file specification can either be a COSString or a COSDictionary
module Pdfbox::Pdmodel::Common::Filespecification
  abstract class PDFileSpecification
    # Factory method to create the appropriate file specification
    # from a COSBase object
    def self.create_fs(base : Cos::Base?) : PDFileSpecification?
      return if base.nil?

      case base
      when Cos::String
        PDSimpleFileSpecification.new(base)
      when Cos::Dictionary
        PDComplexFileSpecification.new(base)
      else
        raise "Error: Unknown file specification #{base.class}"
      end
    end

    # Get the file name
    abstract def file : String?

    # Set the file name
    abstract def file=(value : String)
  end
end
