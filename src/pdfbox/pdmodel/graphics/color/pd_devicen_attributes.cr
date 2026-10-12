require "./pd_devicen_process"
require "./pd_separation"

module Pdfbox::Pdmodel::Graphics::Color
  # Additional information about the components of a DeviceN colour space.
  # Corresponds to PDDeviceNAttributes in Apache PDFBox.
  #
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDDeviceNAttributes.java
  class PDDeviceNAttributes
    @dictionary : Cos::Dictionary

    def initialize
      @dictionary = Cos::Dictionary.new
    end

    def initialize(@dictionary : Cos::Dictionary)
    end

    def cos_dictionary : Cos::Dictionary
      @dictionary
    end

    # Java getColorants: the /Colorants dictionary as a name => PDSeparation map.
    # The Crystal port returns a plain Hash (upstream wraps it in COSDictionaryMap).
    def colorants : Hash(String, PDSeparation)
      actuals = {} of String => PDSeparation
      colorants_dictionary = @dictionary.get_dictionary(Cos::Name.new("Colorants"))
      unless colorants_dictionary
        @dictionary[Cos::Name.new("Colorants")] = Cos::Dictionary.new
        return actuals
      end

      colorants_dictionary.entries.each do |name, value|
        value = value.object if value.is_a?(Cos::Object)
        next unless value
        color_space = PDColorSpace.create(value)
        actuals[name.value] = color_space if color_space.is_a?(PDSeparation)
      end
      actuals
    end

    # Java getProcess: the /Process dictionary, or nil.
    def process : PDDeviceNProcess?
      process_dictionary = @dictionary.get_dictionary(Cos::Name.new("Process"))
      process_dictionary ? PDDeviceNProcess.new(process_dictionary) : nil
    end

    # Java isNChannel: the /Subtype entry equals "NChannel".
    def n_channel? : Bool
      @dictionary.get_name_as_string(Cos::Name::SUBTYPE) == "NChannel"
    end

    # Java setColorants: stores the map as the /Colorants dictionary.
    def colorants=(colorants : Hash(String, PDColorSpace)?) : Nil
      key = Cos::Name.new("Colorants")
      if colorants
        dictionary = Cos::Dictionary.new
        colorants.each do |name, color_space|
          dictionary[Cos::Name.new(name)] = color_space.cos_object
        end
        @dictionary[key] = dictionary
      else
        @dictionary.delete(key)
      end
    end
  end
end
