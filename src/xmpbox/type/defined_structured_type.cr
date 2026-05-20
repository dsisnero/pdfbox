module Xmpbox
  module Type
    class DefinedStructuredType < AbstractStructuredType
      def initialize(metadata : XMPMetadata, @namespace_uri : String?, prefered_prefix : String?, property_name : String?)
        super(metadata, @namespace_uri, prefered_prefix, property_name)
      end
    end
  end
end
