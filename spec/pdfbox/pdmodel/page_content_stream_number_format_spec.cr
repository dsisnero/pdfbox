require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/PDAbstractContentStream.java
#     `formatDecimal` is a US-locale NumberFormat with grouping off and
#     `setMaximumFractionDigits(4)`; `writeOperand(float)` formats through
#     NumberFormatUtil.formatFloatFast with those digits (falling back to
#     `formatDecimal.format` when the fast formatter refuses the value).
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/util/NumberFormatUtil.java
#     rounds to the nearest value, ties away from zero, and omits a zero
#     fraction (`1.0` -> `1`).
#
# The port wrote 5 fraction digits (and had no way to configure them), so every
# fractional operand in a generated content stream differed from Java.
private def content_stream_text(document : Pdfbox::Pdmodel::Document,
                                page : Pdfbox::Pdmodel::Page) : String
  page.content_streams.map(&.create_input_stream.gets_to_end).join
end

private def with_content_stream(&)
  document = Pdfbox::Pdmodel::Document.create
  page = Pdfbox::Pdmodel::Page.new
  document.add_page(page)
  stream = Pdfbox::Pdmodel::PDPageContentStream.new(
    document, page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE, true
  )
  begin
    yield document, page, stream
  ensure
    document.close
  end
end

describe "PDPageContentStream number formatting" do
  it "writes at most four fraction digits by default" do
    with_content_stream do |document, page, stream|
      stream.line_width(1.0 / 3.0)
      stream.close
      content_stream_text(document, page).should contain("0.3333 w")
    end
  end

  it "honours the configured maximum fraction digits" do
    with_content_stream do |document, page, stream|
      stream.maximum_fraction_digits = 2
      stream.maximum_fraction_digits.should eq(2)
      stream.line_width(1.0 / 3.0)
      stream.close
      content_stream_text(document, page).should contain("0.33 w")
    end
  end

  it "rounds halves away from zero" do
    with_content_stream do |document, page, stream|
      # With no fraction digits, +-0.5 is exactly a half: NumberFormatUtil rounds
      # away from zero, so both become +-1 (Java does the same).
      stream.maximum_fraction_digits = 0
      stream.line_width(0.5)
      stream.line_width(-0.5)
      stream.close
      content = content_stream_text(document, page)
      content.should contain("1 w")
      content.should contain("-1 w")
    end
  end

  it "omits a zero fraction" do
    with_content_stream do |document, page, stream|
      stream.line_width(2)
      stream.line_width(2.0)
      stream.close
      content = content_stream_text(document, page)
      content.should contain("2 w")
      content.should_not contain("2.0 w")
    end
  end
end
