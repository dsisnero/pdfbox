require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDMarkInfo.java
describe Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDMarkInfo do
  it "reads and writes /Marked and /UserProperties, and clears /Suspects like Java" do
    info = Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDMarkInfo.new
    info.marked?.should be_false
    info.uses_user_properties?.should be_false
    info.suspect?.should be_false

    info.marked = true
    info.uses_user_properties = true
    info.suspect = true

    info.marked?.should be_true
    info.uses_user_properties?.should be_true
    # Java PDMarkInfo#setSuspect unconditionally writes false to /Suspects.
    info.suspect?.should be_false
    stored = info.cos_object.get_dictionary_object(Pdfbox::Cos::Name::SUSPECTS)
    stored.as?(Pdfbox::Cos::Boolean).try(&.value).should be_false
  end

  it "round-trips through the document catalog" do
    document = Pdfbox::Pdmodel::Document.create
    begin
      info = Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDMarkInfo.new
      info.marked = true
      document.document_catalog.not_nil!.mark_info = info

      document.document_catalog.not_nil!.mark_info.not_nil!.marked?.should be_true
    ensure
      document.close
    end
  end
end
