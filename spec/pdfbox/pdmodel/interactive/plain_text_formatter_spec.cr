require "../../../spec_helper"
require "../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::TextAlign do
  it "maps Java alignment integers" do
    Pdfbox::Pdmodel::Interactive::TextAlign.value_of(0).should eq(Pdfbox::Pdmodel::Interactive::TextAlign::LEFT)
    Pdfbox::Pdmodel::Interactive::TextAlign.value_of(1).should eq(Pdfbox::Pdmodel::Interactive::TextAlign::CENTER)
    Pdfbox::Pdmodel::Interactive::TextAlign.value_of(2).should eq(Pdfbox::Pdmodel::Interactive::TextAlign::RIGHT)
    Pdfbox::Pdmodel::Interactive::TextAlign.value_of(4).should eq(Pdfbox::Pdmodel::Interactive::TextAlign::JUSTIFY)
    Pdfbox::Pdmodel::Interactive::TextAlign.value_of(99).should eq(Pdfbox::Pdmodel::Interactive::TextAlign::LEFT)
  end
end

describe Pdfbox::Pdmodel::Interactive::AppearanceStyle do
  it "tracks Acrobat-like default font size and leading" do
    style = Pdfbox::Pdmodel::Interactive::AppearanceStyle.new

    style.font_size.should eq(12.0_f32)
    style.leading.should eq(14.4_f32)

    style.font_size = 10
    style.leading.should eq(12.0_f32)

    style.leading = 9
    style.leading.should eq(9.0_f32)
  end
end

describe Pdfbox::Pdmodel::Interactive::PlainText do
  it "splits paragraphs on Java line separators and replaces tabs" do
    text = Pdfbox::Pdmodel::Interactive::PlainText.new("a\tb\r\n\nc")

    text.paragraphs.map(&.text).should eq(["a b", " ", "c"])
  end

  it "wraps and splits long words into lines" do
    font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
    paragraph = Pdfbox::Pdmodel::Interactive::PlainText.new("abcdef").paragraphs.first

    lines = paragraph.lines(font, 12, 20)

    lines.size.should be > 1
    lines.first.words.first.text.should_not be_empty
  end
end

describe Pdfbox::Pdmodel::Interactive::PlainTextFormatter do
  it "writes wrapped text through the existing content stream" do
    document = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    document.add_page(page)

    contents = Pdfbox::Pdmodel::PDPageContentStream.new(
      document,
      page,
      Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE,
      false
    )
    font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
    style = Pdfbox::Pdmodel::Interactive::AppearanceStyle.new
    style.font = font
    style.font_size = 12

    contents.begin_text
    contents.set_font(font, 12)

    formatter = Pdfbox::Pdmodel::Interactive::PlainTextFormatter::Builder.new(contents)
      .style(style)
      .wrap_lines(true)
      .width(60)
      .text(Pdfbox::Pdmodel::Interactive::PlainText.new("alpha beta gamma"))
      .initial_offset(10, 20)
      .text_align(Pdfbox::Pdmodel::Interactive::TextAlign::CENTER)
      .build

    formatter.format

    contents.end_text
    contents.close

    stream_text = String.new(page.contents.as(Pdfbox::Cos::Dictionary).create_input_stream.getb_to_end)
    stream_text.should contain("Td")
    stream_text.should contain("(alpha")
    stream_text.should contain("(beta")
  end
end
