module Pdfbox::Pdmodel::Graphics::State
  class PDExtendedGraphicsState
    include Pdfbox::Pdmodel::Common::COSObjectable

    def initialize(@dict : Pdfbox::Cos::Dictionary = Pdfbox::Cos::Dictionary.new)
    end

    def cos_object : Pdfbox::Cos::Base
      @dict
    end

    def alpha_source_flag=(value : Bool) : Bool
      @dict.set_boolean(Pdfbox::Cos::Name.new("AIS"), value)
      value
    end

    def stroking_alpha_constant=(value : Number) : Float64
      float_value = value.to_f64
      @dict.set_float(Pdfbox::Cos::Name.new("CA"), float_value)
      float_value
    end

    def non_stroking_alpha_constant=(value : Number) : Float64
      float_value = value.to_f64
      @dict.set_float(Pdfbox::Cos::Name.new("ca"), float_value)
      float_value
    end

    def blend_mode=(value : Pdfbox::Pdmodel::Graphics::Blend::BlendMode) : Pdfbox::Pdmodel::Graphics::Blend::BlendMode
      @dict[Pdfbox::Cos::Name.new("BM")] = Pdfbox::Cos::Name.new(value.mode.to_cos_name)
      value
    end
  end
end
