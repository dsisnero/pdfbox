require "../spec_helper"
require "../../src/pdfbox"

describe Pdfbox::Printing::Orientation do
  it "parses Java orientation names case-insensitively" do
    Pdfbox::Printing::Orientation.parse("auto").should eq(Pdfbox::Printing::Orientation::AUTO)
    Pdfbox::Printing::Orientation.parse("landscape").should eq(Pdfbox::Printing::Orientation::LANDSCAPE)
    Pdfbox::Printing::Orientation.parse("reverse_landscape").should eq(Pdfbox::Printing::Orientation::REVERSE_LANDSCAPE)
    Pdfbox::Printing::Orientation.parse("portrait").should eq(Pdfbox::Printing::Orientation::PORTRAIT)
  end
end

describe Pdfbox::Printing::PDFPageable do
  it "reports number of pages and carries rendering settings to PDFPrintable" do
    document = Pdfbox::Pdmodel::Document.new
    document.add_page
    document.add_page

    pageable = Pdfbox::Printing::PDFPageable.new(document, Pdfbox::Printing::Orientation::PORTRAIT, true, 144_f32, false)
    pageable.set_subsampling_allowed(true)
    pageable.set_rendering_hints({"quality" => "high"})

    printable = pageable.get_printable(0)

    pageable.get_number_of_pages.should eq(2)
    pageable.is_subsampling_allowed.should be_true
    pageable.get_rendering_hints.should eq({"quality" => "high"})
    printable.show_page_border.should be_true
    printable.dpi.should eq(144_f32)
    printable.center.should be_false
    printable.is_subsampling_allowed.should be_true
    printable.get_rendering_hints.should eq({"quality" => "high"})
  end

  it "derives page format from rotated page boxes" do
    document = Pdfbox::Pdmodel::Document.new
    page = document.add_page
    page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(200.0, 100.0)
    page.crop_box = Pdfbox::Pdmodel::Rectangle.new(10.0, 20.0, 150.0, 80.0)
    page.rotation = 90

    format = Pdfbox::Printing::PDFPageable.new(document).get_page_format(0)

    format.orientation.should eq(Pdfbox::Printing::Orientation::PORTRAIT)
    format.paper.width.should eq(100.0)
    format.paper.height.should eq(200.0)
    format.paper.imageable_x.should eq(20.0)
    format.paper.imageable_y.should eq(10.0)
    format.paper.imageable_width.should eq(60.0)
    format.paper.imageable_height.should eq(140.0)
  end
end

describe Pdfbox::Printing::PDFPrintable do
  it "returns no such page for out-of-range indexes" do
    document = Pdfbox::Pdmodel::Document.new
    printable = Pdfbox::Printing::PDFPrintable.new(document)

    printable.print(0).should eq(Pdfbox::Printing::PDFPrintable::NO_SUCH_PAGE)
  end

  it "raises for rendering because drawing is still unimplemented" do
    document = Pdfbox::Pdmodel::Document.new
    document.add_page
    printable = Pdfbox::Printing::PDFPrintable.new(document)

    expect_raises(Pdfbox::UnsupportedFeatureError, /not yet implemented/) do
      printable.print(0)
    end
  end
end
