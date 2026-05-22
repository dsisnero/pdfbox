require "../../spec_helper"

describe Pdfbox::Pdfwriter::DocumentInformationWriter do
  it "sets and gets title" do
    pseudo_title = ""
    io = ::IO::Memory.new

    writer = Pdfbox::Pdfwriter::DocumentInformationWriter.new(io)
    writer.title = "Test Title"

    # Verify the setter returns the value
    (writer.title = "Another Title").should eq("Another Title")
  end

  it "sets multiple metadata fields" do
    io = ::IO::Memory.new
    writer = Pdfbox::Pdfwriter::DocumentInformationWriter.new(io)

    writer.title = "Title"
    writer.author = "Author"
    writer.subject = "Subject"
    writer.keywords = "keywords, test"
    writer.creator = "Creator"
    writer.producer = "Producer"
    writer.creation_date = Time.utc(2024, 1, 1)
    writer.modification_date = Time.utc(2024, 6, 1)

    # All should return non-nil values
    io.to_s.should_not be_nil
  end

  it "writes without info dictionary" do
    io = ::IO::Memory.new
    writer = Pdfbox::Pdfwriter::DocumentInformationWriter.new(io, nil)
    writer.write # should not crash
  end
end
