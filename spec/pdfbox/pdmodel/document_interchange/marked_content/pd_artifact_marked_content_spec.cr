require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/markedcontent/PDArtifactMarkedContent.java
module PdArtifactMarkedContentSpec
  extend self

  def create_artifact : Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDArtifactMarkedContent
    properties = Pdfbox::Cos::Dictionary.new
    properties.set_name(Pdfbox::Cos::Name::TYPE, "Pagination")
    properties.set_name(Pdfbox::Cos::Name::SUBTYPE, "Header")

    bbox = Pdfbox::Cos::Array.new
    [1.0, 2.0, 11.0, 22.0].each { |value| bbox.add(Pdfbox::Cos::Float.new(value)) }
    properties[Pdfbox::Cos::Name::BBOX] = bbox

    attached = Pdfbox::Cos::Array.new
    attached.add(Pdfbox::Cos::Name.new("Top"))
    properties[Pdfbox::Cos::Name::ATTACHED] = attached

    marked_content = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent.create(
      Pdfbox::Cos::Name::ARTIFACT, properties
    )
    marked_content.as(Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDArtifactMarkedContent)
  end
end

describe Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDArtifactMarkedContent do
  it "is created for the /Artifact tag and exposes type, subtype, bbox and attached edges" do
    artifact = PdArtifactMarkedContentSpec.create_artifact
    artifact.tag.should eq("Artifact")
    artifact.type.should eq("Pagination")
    artifact.subtype.should eq("Header")
    artifact.bbox.not_nil!.width.should eq(10.0_f32)
    artifact.bbox.not_nil!.height.should eq(20.0_f32)
    artifact.top_attached?.should be_true
    artifact.bottom_attached?.should be_false
    artifact.left_attached?.should be_false
    artifact.right_attached?.should be_false
  end

  it "creates a plain PDMarkedContent for non-artifact tags" do
    marked_content = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent.create(
      Pdfbox::Cos::Name.new("P"), nil
    )
    marked_content.class.should eq(Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent)
  end
end
