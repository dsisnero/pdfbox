module Xmpbox
  module Type
    class ColorantType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Colorant#", prefered_prefix: "stClr"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class LayerType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Layer#", prefered_prefix: "stLyr"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class JobType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Job#", prefered_prefix: "stJob"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class OECFType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/OECF#", prefered_prefix: "stOECF"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class CFAPatternType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/CFAPattern#", prefered_prefix: "stCFA"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class DeviceSettingsType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/DeviceSettings#", prefered_prefix: "stDSet"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class FlashType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Flash#", prefered_prefix: "stFlash"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end

    class DimensionsType < AbstractStructuredType
      def self.structured_type_info
        {namespace: "http://ns.adobe.com/xap/1.0/sType/Dimensions#", prefered_prefix: "stDim"}
      end

      def initialize(metadata : XMPMetadata)
        super(metadata)
      end
    end
  end
end
