require "../../document_interchange/marked_content/pd_property_list"

module Pdfbox::Pdmodel::Graphics::OptionalContent
  # An optional content membership dictionary (OCMD).
  # Corresponds to PDOptionalContentMembershipDictionary in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/PDOptionalContentMembershipDictionary.java
  class PDOptionalContentMembershipDictionary < Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
    TYPE = "OCMD"

    def initialize
      super
      @dict.set_name("Type", TYPE)
    end

    def initialize(dict : Pdfbox::Cos::Dictionary)
      type = dict[Pdfbox::Cos::Name.new("Type")]
      type_name = type.as?(Pdfbox::Cos::Name).try(&.value)
      if type_name != TYPE
        raise ArgumentError.new("Provided dictionary is not of type '/#{TYPE}'")
      end
      super(dict)
    end

    # Java getOCGs: the /OCGs entry may be a single dictionary or an array of
    # dictionaries; each is wrapped by PDPropertyList.create.
    def ocgs : Array(Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList)
      base = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("OCGs"))
      case base
      when Pdfbox::Cos::Dictionary
        [Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.create(base)]
      when Pdfbox::Cos::Array
        list = [] of Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
        base.size.times do |i|
          elem = base[i]
          elem = elem.object if elem.is_a?(Pdfbox::Cos::Object)
          if elem.is_a?(Pdfbox::Cos::Dictionary)
            list << Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList.create(elem)
          end
        end
        list
      else
        [] of Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList
      end
    end

    # Java setOCGs: stores the list as the /OCGs array.
    def ocgs=(ocgs : Array(Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDPropertyList)) : Nil
      array = Pdfbox::Cos::Array.new
      ocgs.each { |property| array.add(property.cos_object) }
      @dict[Pdfbox::Cos::Name.new("OCGs")] = array
    end

    # Java getVisibilityPolicy: the /P name, defaulting to AnyOn.
    def visibility_policy : Pdfbox::Cos::Name
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("P"))
      value.is_a?(Pdfbox::Cos::Name) ? value : Pdfbox::Cos::Name.new("AnyOn")
    end

    # Java setVisibilityPolicy.
    def visibility_policy=(visibility_policy : Pdfbox::Cos::Name) : Nil
      @dict[Pdfbox::Cos::Name.new("P")] = visibility_policy
    end
  end
end
