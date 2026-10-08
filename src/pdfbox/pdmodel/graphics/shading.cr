module Pdfbox::Pdmodel::Graphics::Shading
  # Base class for a PDF shading dictionary (PDF 32000-1 8.7.4.3).
  # Port of Apache PDFBox PDShading (model surface).
  class PDShading
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(@dict : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    # The /ShadingType entry.
    def shading_type : Int32
      @dict.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64).to_i32
    end

    # The shading color space (/ColorSpace), or nil.
    def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?
      value = @dict[Pdfbox::Cos::Name.new("ColorSpace")]?
      return unless value
      value = value.object if value.is_a?(Pdfbox::Cos::Object)
      Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(value)
    end

    # Java PDShading#create: dispatch on the ShadingType entry.
    def self.create(dictionary : Pdfbox::Cos::Dictionary) : PDShading
      case dictionary.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64).to_i32
      when 1 then PDShadingType1.new(dictionary)
      when 2 then PDShadingType2.new(dictionary)
      when 3 then PDShadingType3.new(dictionary)
      when 4 then PDShadingType4.new(dictionary)
      when 5 then PDShadingType5.new(dictionary)
      when 6 then PDShadingType6.new(dictionary)
      when 7 then PDShadingType7.new(dictionary)
      else
        raise ArgumentError.new("Unknown shading type #{dictionary.get_int(Pdfbox::Cos::Name.new("ShadingType"), 0_i64)}")
      end
    end
  end
end

require "./shading/pd_shading_type1"
require "./shading/pd_shading_types"
