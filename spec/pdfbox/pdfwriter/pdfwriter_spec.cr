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

describe "Pdfbox::Pdfwriter parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdfwriter/
  #
  # Progress:
  # - ContentStreamWriter token roundtrip parity is covered below.
  # - Compression/document writer parity tests are still pending broader writer stack work.

  pending "COSDocumentCompressionTest#testCompressAcroformDoc requires document compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testCompressAttachmentsDoc requires document compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testCompressEncryptedDoc requires encryption + compression writer parity" do
  end

  pending "COSDocumentCompressionTest#testAlteredDoc requires document compression writer parity" do
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

  pending "COSWriterTest#testPDFBox5485 requires COS writer object graph parity" do
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
