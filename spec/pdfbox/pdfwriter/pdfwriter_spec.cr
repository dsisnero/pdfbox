require "../../spec_helper"

class NonClosingMemoryIO < IO::Memory
  getter close_called = false

  def close : Nil
    @close_called = true
    raise IO::Error.new("Stream was closed")
  end
end

private def parse_trailer_size(bytes : Bytes) : Int64
  marker = "/Size ".to_slice
  idx = bytes.size - marker.size
  while idx >= 0
    if bytes[idx, marker.size] == marker
      pos = idx + marker.size
      value = 0_i64
      found_digit = false
      while pos < bytes.size
        byte = bytes[pos]
        if byte >= '0'.ord.to_u8 && byte <= '9'.ord.to_u8
          found_digit = true
          value = value * 10 + (byte - '0'.ord.to_u8)
          pos += 1
        else
          break
        end
      end
      return value if found_digit
    end
    idx -= 1
  end
  raise "Unable to find trailer /Size entry"
end

private def max_object_number(bytes : Bytes) : Int64
  idx = 0
  max_obj = 0_i64
  while idx < bytes.size
    # Parse "<obj> <gen> obj" tokens at the byte level to avoid UTF-8 decoding.
    start = idx
    obj_number = 0_i64
    has_obj_number = false
    while idx < bytes.size && bytes[idx] >= '0'.ord.to_u8 && bytes[idx] <= '9'.ord.to_u8
      has_obj_number = true
      obj_number = obj_number * 10 + (bytes[idx] - '0'.ord.to_u8)
      idx += 1
    end

    unless has_obj_number && idx < bytes.size && bytes[idx] == ' '.ord.to_u8
      idx = start + 1
      next
    end

    idx += 1
    has_generation = false
    while idx < bytes.size && bytes[idx] >= '0'.ord.to_u8 && bytes[idx] <= '9'.ord.to_u8
      has_generation = true
      idx += 1
    end
    unless has_generation && idx + 4 <= bytes.size && bytes[idx] == ' '.ord.to_u8
      idx = start + 1
      next
    end

    if bytes[idx + 1] == 'o'.ord.to_u8 && bytes[idx + 2] == 'b'.ord.to_u8 && bytes[idx + 3] == 'j'.ord.to_u8
      max_obj = obj_number if obj_number > max_obj
      idx += 4
    else
      idx = start + 1
    end
  end
  max_obj
end

private def annotation_field_name(annot : Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation) : String?
  field = annot.cos_object[Pdfbox::Cos::Name.new("T")]
  case field
  when Pdfbox::Cos::String
    field.value
  when Pdfbox::Cos::Name
    field.value
  else
    nil
  end
end

private def as_dictionary(value : Pdfbox::Cos::Base?) : Pdfbox::Cos::Dictionary?
  return unless value
  if value.is_a?(Pdfbox::Cos::Object)
    dereferenced = value.object
    return dereferenced.as?(Pdfbox::Cos::Dictionary)
  end
  value.as?(Pdfbox::Cos::Dictionary)
end

private def content_stream_length(page : Pdfbox::Pdmodel::Page) : Int32?
  page_dict = page.cos_object
  return unless page_dict

  contents = page_dict[Pdfbox::Cos::Name.new("Contents")]
  return unless contents
  if contents.is_a?(Pdfbox::Cos::Object)
    contents = contents.object
  end

  if contents.is_a?(Pdfbox::Cos::Array)
    first = contents[0]?
    return unless first
    if first.is_a?(Pdfbox::Cos::Object)
      first = first.object
    end
    contents = first
  end

  case contents
  when Pdfbox::Cos::Stream
    length = contents[Pdfbox::Cos::Name.new("Length")]
    if length.is_a?(Pdfbox::Cos::Object)
      length = length.object
    end
    length.as?(Pdfbox::Cos::Integer).try(&.value.to_i32) || contents.data.size
  when Pdfbox::Cos::Dictionary
    length = contents[Pdfbox::Cos::Name.new("Length")]
    if length.is_a?(Pdfbox::Cos::Object)
      length = length.object
    end
    length.as?(Pdfbox::Cos::Integer).try(&.value.to_i32)
  end
end

describe "Pdfbox::Pdfwriter parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfwriter/
  #
  # Progress:
  # - ContentStreamWriter token roundtrip parity is covered below.
  # - Compression/document writer parity tests are still pending broader writer stack work.

  it "COSDocumentCompressionTest#testCompressAcroformDoc" do
    source_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/compression/acroform.pdf")
    source = Pdfbox::Pdmodel::Document.load(source_path)

    compressed_output = IO::Memory.new
    source.save(compressed_output)
    compressed = Pdfbox::Pdmodel::Document.load(IO::Memory.new(compressed_output.to_slice))

    compressed.number_of_pages.should eq(1)
    page = compressed.get_page(0)
    annotations = page.annotations.to_a
    annotations.size.should eq(13)
    annotation_field_name(annotations[0]).should eq("TextField")
    annotation_field_name(annotations[1]).should eq("Button")
    annotation_field_name(annotations[2]).should eq("CheckBox1")
    annotation_field_name(annotations[3]).should eq("CheckBox2")
    annotation_field_name(annotations[4]).should eq("TextFieldMultiLine")
    annotation_field_name(annotations[5]).should eq("TextFieldMultiLineRT")

    parent6 = annotations[6].cos_object[Pdfbox::Cos::Name.new("Parent")]
    parent6.should_not be_nil
    parent6_dict = as_dictionary(parent6).not_nil!
    parent6_dict[Pdfbox::Cos::Name.new("T")].as(Pdfbox::Cos::String).value.should eq("GroupOption")

    parent7 = annotations[7].cos_object[Pdfbox::Cos::Name.new("Parent")]
    parent7.should_not be_nil
    parent7_dict = as_dictionary(parent7).not_nil!
    parent7_dict[Pdfbox::Cos::Name.new("T")].as(Pdfbox::Cos::String).value.should eq("GroupOption")

    annotation_field_name(annotations[8]).should eq("ListBox")
    annotation_field_name(annotations[9]).should eq("ListBoxMultiSelect")
    annotation_field_name(annotations[10]).should eq("ComboBox")
    annotation_field_name(annotations[11]).should eq("ComboBoxEditable")
    annotation_field_name(annotations[12]).should eq("Signature")
  ensure
    source.try(&.close)
    compressed.try(&.close)
  end

  it "COSDocumentCompressionTest#testCompressAttachmentsDoc" do
    source_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/compression/attachment.pdf")
    source = Pdfbox::Pdmodel::Document.load(source_path)

    compressed_output = IO::Memory.new
    source.save(compressed_output)
    compressed = Pdfbox::Pdmodel::Document.load(IO::Memory.new(compressed_output.to_slice))

    compressed.number_of_pages.should eq(2)
    names_dict = compressed.document_catalog.not_nil!.names
    names_dict.should_not be_nil
    embedded_tree = names_dict.not_nil!.embedded_files
    embedded_tree.should_not be_nil
    embedded_files = embedded_tree.not_nil!.names
    embedded_files.should_not be_nil
    embedded_files.not_nil!.size.should eq(1)
    attachment = embedded_files.not_nil!["A4Unicode.pdf"]?
    attachment.should_not be_nil
    attachment.not_nil!.embedded_file.should_not be_nil
    attachment.not_nil!.embedded_file.not_nil!.length.should eq(14997)
  ensure
    source.try(&.close)
    compressed.try(&.close)
  end

  pending "COSDocumentCompressionTest#testCompressEncryptedDoc requires encryption + compression writer parity" do
  end

  it "COSDocumentCompressionTest#testAlteredDoc" do
    source_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/compression/unencrypted.pdf")
    source = Pdfbox::Pdmodel::Document.load(source_path)
    target_output = IO::Memory.new

    page = Pdfbox::Pdmodel::Page.new
    page.media_box = Pdfbox::Pdmodel::Rectangle.new(0.0, 0.0, 100.0, 100.0)
    source.add_page(page)

    content_stream = Pdfbox::Pdmodel::PDPageContentStream.new(source, page)
    content_stream.begin_text
    content_stream.new_line_at_offset(20, 80)
    content_stream.set_font(
      Pdfbox::Pdmodel::Font::PDType1Font.new(
        Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA
      ),
      12
    )
    content_stream.show_text("Test")
    content_stream.end_text
    content_stream.close

    source.save(target_output)
    compressed = Pdfbox::Pdmodel::Document.load(IO::Memory.new(target_output.to_slice))

    compressed.number_of_pages.should eq(3)
    new_page = compressed.get_page(2)
    content_stream_length(new_page).should eq(43)
  ensure
    source.try(&.close)
    compressed.try(&.close)
  end

  pending "COSDocumentCompressionTest#testPDFBox5927 requires document compression writer parity" do
  end

  pending "COSWriterCompressionPoolTest#testPDFBox6036 requires COS writer compression pool parity" do
  end

  it "COSWriterTest#testPDFBox4321" do
    doc = Pdfbox::Pdmodel::Document.new
    doc.add_page(Pdfbox::Pdmodel::Page.new)

    output = NonClosingMemoryIO.new
    # parity intent from Java COSWriterTest#testPDFBox4321:
    # save must not close externally-managed output streams.
    doc.save(output)
    output.close_called.should be_false
    output.to_slice.size.should be > 0
  ensure
    doc.try(&.close)
  end

  it "COSWriterTest#testPDFBox5485" do
    fixture_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/PDFBOX-3110-poems-beads.pdf")
    source = Pdfbox::Pdmodel::Document.load(fixture_path)
    extractor = Pdfbox::Multipdf::PageExtractor.new(source, 2, 2)
    extracted = extractor.extract

    output = IO::Memory.new
    extracted.save(output)
    output.to_slice.size.should be > 0
    extracted.page_count.should eq(1)
  ensure
    source.try(&.close)
    extracted.try(&.close)
  end

  it "COSWriterTest#testPDFBox5945" do
    doc = Pdfbox::Pdmodel::Document.create
    doc.add_page(Pdfbox::Pdmodel::Page.new)

    catalog = doc.document_catalog.not_nil!
    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    catalog.cos_object[Pdfbox::Cos::Name.new("AcroForm")] = acro_form.cos_object

    text_field_dict = Pdfbox::Cos::Dictionary.new
    text_field_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
    text_field_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("textFieldName")
    text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, text_field_dict, nil)
    acro_form.add_field(text_field)

    initial_output = IO::Memory.new
    doc.save(initial_output)
    created_bytes = initial_output.to_slice
    parse_trailer_size(created_bytes).should eq(max_object_number(created_bytes) + 1)
  ensure
    doc.try(&.close)
  end

  it "COSWriterTest#testPDFBox5945 incremental edit keeps trailer size aligned" do
    create_doc = Pdfbox::Pdmodel::Document.create
    create_doc.add_page(Pdfbox::Pdmodel::Page.new)

    catalog = create_doc.document_catalog.not_nil!
    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(create_doc)
    catalog.cos_object[Pdfbox::Cos::Name.new("AcroForm")] = acro_form.cos_object

    text_field_dict = Pdfbox::Cos::Dictionary.new
    text_field_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
    text_field_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("textFieldName")
    text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, text_field_dict, nil)
    acro_form.add_field(text_field)

    initial_output = IO::Memory.new
    create_doc.save(initial_output)
    created_bytes = initial_output.to_slice
    parse_trailer_size(created_bytes).should eq(max_object_number(created_bytes) + 1)

    loaded = Pdfbox::Pdmodel::Document.load(IO::Memory.new(created_bytes))
    loaded_catalog = loaded.document_catalog.not_nil!
    loaded_form_dict = loaded_catalog.cos_object[Pdfbox::Cos::Name.new("AcroForm")]
    if loaded_form_dict.is_a?(Pdfbox::Cos::Object)
      loaded_form_dict = loaded_form_dict.object
    end
    loaded_form = loaded_form_dict.is_a?(Pdfbox::Cos::Dictionary) ? Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(loaded, loaded_form_dict) : nil
    loaded_form.should_not be_nil

    loaded_field = loaded_form.not_nil!.get_field("textFieldName")
    loaded_field.should_not be_nil
    loaded_text_field = loaded_field.not_nil!.as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
    loaded_text_field.field_flags = loaded_text_field.field_flags | Pdfbox::Pdmodel::Interactive::Form::PDTextField::FLAG_MULTILINE

    edited_output = IO::Memory.new
    loaded.save_incremental(edited_output)
    edited_bytes = edited_output.to_slice
    parse_trailer_size(edited_bytes).should eq(max_object_number(edited_bytes) + 1)
  ensure
    create_doc.try(&.close)
    loaded.try(&.close)
  end

  pending "COSWriterTest#testPDFBox6036 requires COS writer object graph parity" do
  end

  it "ContentStreamWriterTest#testPDFBox4750" do
    source = <<-PDF
    q
    BI
    /W 1
    /H 1
    /BPC 8
    /CS /RGB
    ID
    12EI5
    EI
    Q
    PDF

    parser = Pdfbox::Pdfparser::PDFStreamParser.new(source)
    tokens = parser.parse

    written = IO::Memory.new
    writer = Pdfbox::Pdfwriter::ContentStreamWriter.new(written)
    writer.write_tokens(tokens)

    reparsed = Pdfbox::Pdfparser::PDFStreamParser.new(written.to_slice).parse

    # Round-tripped stream must preserve operator sequence and inline image payload.
    tokens.size.should eq(reparsed.size)
    tokens[0].as(Pdfbox::ContentStream::Operator).name.should eq("q")
    reparsed[0].as(Pdfbox::ContentStream::Operator).name.should eq("q")
    tokens[1].as(Pdfbox::ContentStream::Operator).name.should eq("BI")
    reparsed[1].as(Pdfbox::ContentStream::Operator).name.should eq("BI")
    tokens[2].as(Pdfbox::ContentStream::Operator).name.should eq("Q")
    reparsed[2].as(Pdfbox::ContentStream::Operator).name.should eq("Q")

    original_inline = tokens[1].as(Pdfbox::ContentStream::Operator)
    reparsed_inline = reparsed[1].as(Pdfbox::ContentStream::Operator)
    original_inline.image_data.should_not be_nil
    reparsed_inline.image_data.should_not be_nil
    original_data = original_inline.image_data.not_nil!
    reparsed_data = reparsed_inline.image_data.not_nil!

    trimmed_size = ->(bytes : Bytes) do
      size = bytes.size
      while size > 0 && bytes[size - 1] == '\n'.ord.to_u8
        size -= 1
      end
      size
    end

    original_data[0, trimmed_size.call(original_data)].should eq(reparsed_data[0, trimmed_size.call(reparsed_data)])
    original_data[0, 5].should eq("12EI5".to_slice)
    original_inline.image_parameters.not_nil!.size.should eq(reparsed_inline.image_parameters.not_nil!.size)
  end
end
