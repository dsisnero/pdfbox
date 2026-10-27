require "../../spec_helper"

# Port of org.apache.pdfbox.cos.TestCOSIncrement.
#
# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/cos/TestCOSIncrement.java
# Fixture: simple.png copied from
#   vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/cos/simple.png
# (SHA512 recorded in spec/resources/pdfbox/cos/SHA512SUMS).
private def increment_page(width : Float64) : Pdfbox::Pdmodel::Page
  page = Pdfbox::Pdmodel::Page.new
  page.media_box = Pdfbox::Pdmodel::Rectangle.from_dimensions(width, width)
  page
end

private def increment_xobject_names(resources : Pdfbox::Pdmodel::Resources) : Array(Pdfbox::Cos::Name)
  xobjects = resources.cos_object.get_dictionary(Pdfbox::Cos::Name.new("XObject"))
  xobjects ? xobjects.entries.keys : [] of Pdfbox::Cos::Name
end

# Every saveIncremental in the upstream test appends a revision to the bytes it
# loaded, so each intermediate `documentData` must be a prefix of the next one
# (COSWriter writes the source verbatim and appends the update).
private def increment_assert_appended(previous : Bytes, current : Bytes) : Nil
  current.size.should be > previous.size
  current[0, previous.size].should eq(previous)
end

describe "Pdfbox::Cos Incremental Integration" do
  it "TestCOSIncrement#testIncrementallyCreateDocument" do
    # Add page 1.
    output = IO::Memory.new
    document = Pdfbox::Pdmodel::Document.create
    document.add_page(increment_page(100.0))
    document.save(output)
    document.close
    bytes = output.to_slice

    # Add page 2 and 3.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.number_of_pages.should eq(1)
    document.add_page(increment_page(200.0))
    document.add_page(increment_page(100.0))
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Remove page 2.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.number_of_pages.should eq(3)
    document.remove_page(document.get_page(1)).should be_true
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Add an image to page 1.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.get_page(1).media_box.not_nil!.width.should_not eq(200.0)
    document.number_of_pages.should eq(2)
    document.get_page(0).has_contents?.should be_false
    document.get_page(0).resources.should be_nil
    document.get_page(1).has_contents?.should be_false
    document.get_page(1).resources.should be_nil
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(document, document.get_page(0))
    image = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.create_from_file_by_extension(
      "spec/resources/pdfbox/cos/simple.png", document)
    content_stream.draw_image(image, 15, 20)
    content_stream.close
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Write a text to page 2.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.get_page(0).has_contents?.should be_true
    page0_resources = document.get_page(0).resources
    page0_resources.should_not be_nil
    page0_resources.not_nil!.font_names.should be_empty
    increment_xobject_names(page0_resources.not_nil!).should_not be_empty
    document.get_page(1).has_contents?.should be_false
    document.get_page(1).resources.should be_nil
    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(document, document.get_page(1))
    content_stream.begin_text
    content_stream.set_font(
      Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA), 20)
    content_stream.new_line_at_offset(20, 50)
    content_stream.show_text("Page 2")
    content_stream.end_text
    content_stream.close
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Add an annotation to page 2.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.get_page(0).has_contents?.should be_true
    document.get_page(0).resources.should_not be_nil
    document.get_page(1).resources.should_not be_nil
    document.get_page(1).annotations.size.should eq(0)
    document.get_page(1).has_contents?.should be_true
    document.get_page(1).resources.not_nil!.font_names.should_not be_empty
    increment_xobject_names(document.get_page(1).resources.not_nil!).should be_empty
    text_annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText.new
    text_annot.name = "text annotation"
    text_annot.contents = "text annotation"
    text_annot.open = true
    text_annot.color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new(
      [1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    text_annot.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(4.0_f32, 5.0_f32, 10.0_f32, 10.0_f32)
    text_annot.construct_appearances(document)
    document.get_page(1).annotations.add(text_annot)
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Do nothing.
    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    document.get_page(1).annotations.size.should eq(1)
    previous_bytes = bytes
    document.save_incremental(output)
    document.close
    bytes = output.to_slice
    increment_assert_appended(previous_bytes, bytes)

    # Check the result.
    document = Pdfbox::Loader.load_pdf(bytes)
    document.number_of_pages.should eq(2)
    document.get_page(0).resources.should_not be_nil
    document.get_page(1).resources.should_not be_nil
    document.get_page(0).has_contents?.should be_true
    document.get_page(0).resources.not_nil!.font_names.should be_empty
    increment_xobject_names(document.get_page(0).resources.not_nil!).should_not be_empty
    document.get_page(1).has_contents?.should be_true
    document.get_page(1).annotations.size.should eq(1)
    document.get_page(1).resources.not_nil!.font_names.should_not be_empty
    document.close
  end

  it "TestCOSIncrement#testConcurrentModification" do
    fixture = "spec/resources/pdfbox/pdparser/PDFBOX-5025.pdf"
    bytes = File.open(fixture) do |io|
      data = Bytes.new(io.size.to_i32)
      io.read_fully(data)
      data
    end
    document = Pdfbox::Loader.load_pdf(bytes)
    document.set_all_security_to_be_removed(true)
    output = IO::Memory.new
    document.save(output)
    output.size.should be > 0
    document.close
  end

  it "TestCOSIncrement#testSubsetting" do
    output = IO::Memory.new
    document = Pdfbox::Pdmodel::Document.create
    page = Pdfbox::Pdmodel::Page.new
    page.media_box = Pdfbox::Pdmodel::PageSizes::A4
    document.add_page(page)
    document.save(output)
    document.close
    bytes = output.to_slice

    output = IO::Memory.new
    document = Pdfbox::Loader.load_pdf(bytes)
    page = document.get_page(0)
    font = Pdfbox::Pdmodel::Font::PDType0Font.load(
      document,
      File.open("vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf"))

    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(document, page)
    content_stream.begin_text
    content_stream.set_font(font, 12)
    content_stream.new_line_at_offset(75, 750)
    content_stream.show_text("Apache PDFBox")
    content_stream.end_text
    content_stream.close

    catalog = document.document_catalog.not_nil!.cos_object.as(Pdfbox::Cos::Dictionary)
    catalog.set_need_to_be_updated(true)
    catalog.get_dictionary(Pdfbox::Cos::Name.new("Pages")).not_nil!.set_need_to_be_updated(true)
    page.cos_object.not_nil!.set_need_to_be_updated(true)

    document.save_incremental(output)
    document.close

    document = Pdfbox::Loader.load_pdf(output.to_slice)
    page = document.get_page(0)
    font_name = page.resources.not_nil!.font_names.first
    loaded_font = page.resources.not_nil!.font(font_name).not_nil!
    loaded_font.embedded?.should be_true
    document.close
  end
end
