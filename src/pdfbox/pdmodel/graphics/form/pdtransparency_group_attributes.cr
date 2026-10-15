module Pdfbox::Pdmodel::Graphics::Form
  class PDTransparencyGroupAttributes
    include Pdfbox::Pdmodel::Common::COSObjectable

    @dictionary : Pdfbox::Cos::Dictionary

    def initialize
      @dictionary = Pdfbox::Cos::Dictionary.new
      @dictionary.set_name(Pdfbox::Cos::Name::S, "Transparency")
    end

    def initialize(@dictionary : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Base
      @dictionary
    end

    # The group color space (/CS), or nil when it isn't defined.
    # Java PDTransparencyGroupAttributes#getColorSpace.
    def color_space : Pdfbox::Pdmodel::Graphics::Color::PDColorSpace?
      return unless @dictionary.has_key?(Pdfbox::Cos::Name.new("CS"))
      base = @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("CS"))
      base ? Pdfbox::Pdmodel::Graphics::Color::PDColorSpace.create(base) : nil
    end

    def isolated? : Bool
      @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("I"))
        .as?(Pdfbox::Cos::Boolean).try(&.value) || false
    end

    def knockout? : Bool
      @dictionary.get_dictionary_object(Pdfbox::Cos::Name.new("K"))
        .as?(Pdfbox::Cos::Boolean).try(&.value) || false
    end
  end
end
