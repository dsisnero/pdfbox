module Pdfbox::Pdmodel::DocumentInterchange::MarkedContent
  class PDMarkedContent
    @tag : String?
    @properties : Pdfbox::Cos::Dictionary?
    @contents : Array(Pdfbox::Cos::Base | Pdfbox::Text::TextPosition | PDMarkedContent)

    def self.create(tag : Pdfbox::Cos::Name?, properties : Pdfbox::Cos::Dictionary?) : PDMarkedContent
      # Java PDMarkedContent#create dispatches /Artifact to PDArtifactMarkedContent.
      if tag == Pdfbox::Cos::Name::ARTIFACT
        return PDArtifactMarkedContent.new(properties)
      end
      new(tag, properties)
    end

    def initialize(tag : Pdfbox::Cos::Name?, @properties : Pdfbox::Cos::Dictionary?)
      @tag = tag.try(&.value)
      @contents = [] of (Pdfbox::Cos::Base | Pdfbox::Text::TextPosition | PDMarkedContent)
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
      props[Pdfbox::Cos::Name::ACTUAL_TEXT]?.try(&.as?(Pdfbox::Cos::String)).try(&.value)
    end

    # Java PDMarkedContent#getLanguage.
    def language : String?
      @properties.try(&.get_name_as_string(Pdfbox::Cos::Name::LANG))
    end

    # Java PDMarkedContent#getAlternateDescription.
    def alternate_description : String?
      @properties.try(&.get_string(Pdfbox::Cos::Name::ALT))
    end

    # Java PDMarkedContent#getExpandedForm.
    def expanded_form : String?
      @properties.try(&.get_string(Pdfbox::Cos::Name::E))
    end

    # Java PDMarkedContent#getContents.
    def contents : Array(Pdfbox::Cos::Base | Pdfbox::Text::TextPosition | PDMarkedContent)
      @contents
    end

    # Java PDMarkedContent#addText.
    def add_text(text : Pdfbox::Text::TextPosition) : Nil
      @contents << text
    end

    # Java PDMarkedContent#addMarkedContent.
    def add_marked_content(marked_content : PDMarkedContent) : Nil
      @contents << marked_content
    end

    # Java PDMarkedContent#addXObject.
    def add_x_object(xobject : Pdfbox::Cos::Base) : Nil
      @contents << xobject
    end

    # The nested marked-content sequences (Java contents filtered to PDMarkedContent).
    def marked_contents : Array(PDMarkedContent)
      @contents.select(PDMarkedContent).map(&.as(PDMarkedContent))
    end

    def to_s(io : IO) : Nil
      io << "tag=" << @tag << ", properties=" << @properties << ", contents=" << @contents.size
    end
  end

  # Marked-content sequence with the /Artifact tag.
  # Port of Apache PDFBox PDArtifactMarkedContent.
  class PDArtifactMarkedContent < PDMarkedContent
    def initialize(properties : Pdfbox::Cos::Dictionary?)
      super(Pdfbox::Cos::Name::ARTIFACT, properties)
    end

    # Java PDArtifactMarkedContent#getType.
    def type : String?
      @properties.try(&.get_name_as_string(Pdfbox::Cos::Name::TYPE))
    end

    # Java PDArtifactMarkedContent#getSubtype.
    def subtype : String?
      @properties.try(&.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE))
    end

    # Java PDArtifactMarkedContent#getBBox.
    def bbox : Pdfbox::Pdmodel::Common::PDRectangle?
      array = @properties.try(&.get_array(Pdfbox::Cos::Name::BBOX))
      array ? Pdfbox::Pdmodel::Common::PDRectangle.new(array) : nil
    end

    def top_attached? : Bool
      attached?("Top")
    end

    def bottom_attached? : Bool
      attached?("Bottom")
    end

    def left_attached? : Bool
      attached?("Left")
    end

    def right_attached? : Bool
      attached?("Right")
    end

    # Java PDArtifactMarkedContent#isAttached.
    private def attached?(edge : String) : Bool
      array = @properties.try(&.get_array(Pdfbox::Cos::Name::ATTACHED))
      return false unless array
      array.items.any? do |item|
        item = item.object if item.is_a?(Pdfbox::Cos::Object)
        item.is_a?(Pdfbox::Cos::Name) && item.value == edge
      end
    end
  end
end
