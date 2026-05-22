module Xmpbox
  module Type
    enum Types
      Structured
      DefinedType

      # Basic simple types
      Text
      Date
      Boolean
      Integer
      Real
      GPSCoordinate
      ProperName
      Locale
      AgentName
      GUID
      XPath
      Part
      URL
      URI
      Choice
      MIMEType
      LangAlt
      RenditionClass
      Rational

      # Structured types
      Colorant
      Font
      Layer
      Thumbnail
      ResourceEvent
      ResourceRef
      Version
      PDFASchema
      PDFAField
      PDFAProperty
      PDFAType
      Job
      OECF
      CFAPattern
      DeviceSettings
      Flash
      Dimensions

      def simple?
        !(structured? || defined?)
      end

      def basic?
        basic.nil?
      end

      def structured?
        self.in?(Colorant, Font, Layer, Thumbnail, ResourceEvent, ResourceRef,
          Version, PDFASchema, PDFAField, PDFAProperty, PDFAType, Job, OECF,
          CFAPattern, DeviceSettings, Flash, Dimensions)
      end

      def defined?
        self == DefinedType
      end

      def basic : Types?
        return Text if self.in?(
                         GPSCoordinate, ProperName, Locale, AgentName, GUID, XPath,
                         Part, URL, URI, Choice, MIMEType, RenditionClass, Rational
                       )
        return Structured if structured?
        nil
      end

      def implementing_class_name : String?
        case self
        when Text           then "TextType"
        when Date           then "DateType"
        when Boolean        then "BooleanType"
        when Integer        then "IntegerType"
        when Real           then "RealType"
        when GPSCoordinate  then "TextType"
        when ProperName     then "ProperNameType"
        when Locale         then "LocaleType"
        when AgentName      then "AgentNameType"
        when GUID           then "GUIDType"
        when XPath          then "XPathType"
        when Part           then "PartType"
        when URL            then "URLType"
        when URI            then "URIType"
        when Choice         then "ChoiceType"
        when MIMEType       then "MIMEType"
        when LangAlt        then "TextType"
        when RenditionClass then "RenditionClassType"
        when Rational       then "RationalType"
        when Colorant       then "ColorantType"
        when Font           then "FontType"
        when Layer          then "LayerType"
        when Thumbnail      then "ThumbnailType"
        when ResourceEvent  then "ResourceEventType"
        when ResourceRef    then "ResourceRefType"
        when Version        then "VersionType"
        when PDFASchema     then "PDFASchemaType"
        when PDFAField      then "PDFAFieldType"
        when PDFAProperty   then "PDFAPropertyType"
        when PDFAType       then "PDFATypeType"
        when Job            then "JobType"
        when OECF           then "OECFType"
        when CFAPattern     then "CFAPatternType"
        when DeviceSettings then "DeviceSettingsType"
        when Flash          then "FlashType"
        when Dimensions     then "DimensionsType"
        end
      end
    end
  end
end
