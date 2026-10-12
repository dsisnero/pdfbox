require "./pd_prop_build_data_dict"

module Pdfbox::Pdmodel::Interactive::Form
  # A property build dictionary (/Prop_Build). Corresponds to PDPropBuild in
  # Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDPropBuild.java
  class PDPropBuild
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @dictionary
    end

    # The signature handler build data (/Filter).
    def filter : PDPropBuildDataDict?
      dictionary = @dictionary.get_dictionary(Cos::Name.new("Filter"))
      dictionary ? PDPropBuildDataDict.new(dictionary) : nil
    end

    def filter=(value : PDPropBuildDataDict?) : Nil
      set_child(Cos::Name.new("Filter"), value)
    end

    # The PubSec software module build data (/PubSec).
    def pub_sec : PDPropBuildDataDict?
      dictionary = @dictionary.get_dictionary(Cos::Name.new("PubSec"))
      dictionary ? PDPropBuildDataDict.new(dictionary) : nil
    end

    def pub_sec=(value : PDPropBuildDataDict?) : Nil
      set_child(Cos::Name.new("PubSec"), value)
    end

    # The viewing application build data (/App).
    def app : PDPropBuildDataDict?
      dictionary = @dictionary.get_dictionary(Cos::Name.new("App"))
      dictionary ? PDPropBuildDataDict.new(dictionary) : nil
    end

    def app=(value : PDPropBuildDataDict?) : Nil
      set_child(Cos::Name.new("App"), value)
    end

    private def set_child(key : Cos::Name, value : PDPropBuildDataDict?) : Nil
      if value
        @dictionary[key] = value.cos_object
      else
        @dictionary.delete(key)
      end
    end
  end
end
