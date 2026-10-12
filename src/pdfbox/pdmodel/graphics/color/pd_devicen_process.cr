module Pdfbox::Pdmodel::Graphics::Color
  # A DeviceN Process Dictionary. Corresponds to PDDeviceNProcess in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceNProcess.java
  class PDDeviceNProcess
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_dictionary : Cos::Dictionary
      @dictionary
    end

    # Java getColorSpace: the /ColorSpace entry, or nil.
    def color_space : PDColorSpace?
      value = @dictionary.get_dictionary_object(Cos::Name.new("ColorSpace"))
      value ? PDColorSpace.create(value) : nil
    end

    # Java getComponents: the component names (/Components), never nil.
    def components : Array(String)
      array = @dictionary.get_array(Cos::Name.new("Components"))
      return [] of String unless array
      array.items.compact_map do |item|
        item = item.object if item.is_a?(Cos::Object)
        item.as?(Cos::Name).try(&.value)
      end
    end
  end
end
