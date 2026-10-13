module Pdfbox::Pdmodel::Graphics::Shading
  # Base class for a PDF shading dictionary (PDF 32000-1 8.7.4.3).
  # Port of Apache PDFBox PDShading (model surface).
  class PDShading
    include Pdfbox::Pdmodel::Common::COSObjectable

    SHADING_TYPE1 = 1
    SHADING_TYPE2 = 2
    SHADING_TYPE3 = 3
    SHADING_TYPE4 = 4
    SHADING_TYPE5 = 5
    SHADING_TYPE6 = 6
    SHADING_TYPE7 = 7

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
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("ColorSpace"))
      return unless value
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

    # The shading function (/Function), or nil (Java getFunction).
    def function : Pdfbox::Pdmodel::Common::Function::PDFunction?
      value = @dict.get_dictionary_object(Pdfbox::Cos::Name.new("Function"))
      value ? Pdfbox::Pdmodel::Common::Function::PDFunction.create(value) : nil
    end

    def function=(new_function : Pdfbox::Pdmodel::Common::Function::PDFunction) : Nil
      @dict[Pdfbox::Cos::Name.new("Function")] = new_function.cos_object
    end

    # Shared setter for optional COSArray entries (Java setItem(name, null) removes).
    protected def set_optional_array(key : ::String, value : Pdfbox::Cos::Array?) : Nil
      name = Pdfbox::Cos::Name.new(key)
      if value
        @dict[name] = value
      else
        @dict.delete(name)
      end
    end
  end
end

require "./shading/pd_shading_type1"
require "./shading/pd_shading_type2"
require "./shading/pd_shading_type3"
require "./shading/pd_triangle_based_shading_type"
require "./shading/pd_shading_type4"
require "./shading/pd_shading_type5"
require "./shading/pd_mesh_based_shading_type"
require "./shading/pd_shading_type6"
require "./shading/pd_shading_type7"
