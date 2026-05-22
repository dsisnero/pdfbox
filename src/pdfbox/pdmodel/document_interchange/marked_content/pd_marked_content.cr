module Pdfbox::Pdmodel::DocumentInterchange::MarkedContent
  class PDMarkedContent
    @tag : String?
    @properties : Pdfbox::Cos::Dictionary?
    @contents : Array(String)

    def self.create(tag : Pdfbox::Cos::Name?, properties : Pdfbox::Cos::Dictionary?) : self
      new(tag, properties)
    end

    def initialize(tag : Pdfbox::Cos::Name?, @properties : Pdfbox::Cos::Dictionary?)
      @tag = tag.try(&.value)
      @contents = [] of String
    end

    def tag : String?
      @tag
    end

    def properties : Pdfbox::Cos::Dictionary?
      @properties
    end

    def mcid : Int32
      props = @properties
      return -1 unless props
      return -1 unless props.contains_key?("MCID")

      value = props[Pdfbox::Cos::Name.new("MCID")]
      value.as?(Pdfbox::Cos::Integer).try(&.value.to_i32) || -1
    end

    def actual_text : String?
      props = @properties
      return nil unless props
      props[Pdfbox::Cos::Name.new("ActualText")]?.try(&.as?(Pdfbox::Cos::String)).try(&.value)
    end
  end
end
