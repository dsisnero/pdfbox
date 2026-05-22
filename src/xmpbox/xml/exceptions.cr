module Xmpbox
  module Xml
    class XmpParsingException < Exception
      enum ErrorType
        Undefined
        Configuration
        XpacketBadStart
        XpacketBadEnd
        NoRootElement
        NoSchema
        InvalidType
        Format
        NoValue
        NoType
        RequiredProperty
        InvalidPdfaSchema
        InvalidPrefix
      end

      getter error_type : ErrorType

      def initialize(@error_type : ErrorType, message : String, cause : Exception? = nil)
        super(message, cause: cause)
      end
    end

    class XmpSerializationException < Exception
    end
  end
end
