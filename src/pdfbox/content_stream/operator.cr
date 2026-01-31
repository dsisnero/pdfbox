module Pdfbox::ContentStream
  # An Operator in a PDF content stream.
  # Similar to Apache PDFBox Operator
  class Operator
    @name : String
    @image_data : Bytes?
    @image_parameters : Pdfbox::Cos::Dictionary?

    # Private constructor - use get_operator to create/cache operators
    def initialize(@name : String)
      if @name.starts_with?("/")
        raise ArgumentError.new("Operators are not allowed to start with / '#{@name}'")
      end
    end

    # Get the operator name
    def name : String
      @name
    end

    # Get inline image data (if this is an ID operator)
    def image_data : Bytes?
      @image_data
    end

    # Set inline image data
    def image_data=(data : Bytes) : Bytes
      @image_data = data
    end

    # Get inline image parameters (if this is a BI operator)
    def image_parameters : Pdfbox::Cos::Dictionary?
      @image_parameters
    end

    # Set inline image parameters
    def image_parameters=(params : Pdfbox::Cos::Dictionary) : Pdfbox::Cos::Dictionary
      @image_parameters = params
    end

    # Cache for operator instances (singleton pattern)
    @@operators = {} of String => Operator

    # Create/cache operators in the system.
    # For ID and BI operators, always create new instance (can't cache).
    def self.get_operator(name : String) : Operator
      if name == OperatorName::BEGIN_INLINE_IMAGE_DATA || name == OperatorName::BEGIN_INLINE_IMAGE
        # we can't cache the ID/BI operators
        Operator.new(name)
      else
        @@operators[name] ||= begin
          Operator.new(name)
        end
      end
    end
  end
end
