require "../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/PDFMergerUtility.java
# (appendDocument: mergePageLabels / mergeOutputIntents / metadata merge).
describe "PDFMergerUtility appendDocument catalog merges" do
  it "appends source page labels with the destination page-count offset" do
    src = Pdfbox::Pdmodel::Document.create
    2.times { src.add_page(Pdfbox::Pdmodel::Page.new) }
    src_labels = Pdfbox::Cos::Dictionary.new
    src_nums = Pdfbox::Cos::Array.new
    src_nums.add(Pdfbox::Cos::Integer.new(0_i64))
    label = Pdfbox::Cos::Dictionary.new
    label.set_name("S", "r")
    src_nums.add(label)
    src_labels[Pdfbox::Cos::Name.new("Nums")] = src_nums
    src.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("PageLabels")] = src_labels

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      labels = dst.document_catalog.not_nil!.cos_object.get_dictionary(Pdfbox::Cos::Name.new("PageLabels"))
      labels.should_not be_nil
      nums = labels.not_nil!.get_array(Pdfbox::Cos::Name.new("Nums")).not_nil!
      # destPageCount (1) is added to the source label index (0).
      nums[0].as(Pdfbox::Cos::Integer).value.should eq(1)
      nums[1].as(Pdfbox::Cos::Dictionary).get_name_as_string(Pdfbox::Cos::Name.new("S")).should eq("r")
    ensure
      src.close
      dst.close
    end
  end

  it "adds source output intents unless the identifier already exists" do
    src = Pdfbox::Pdmodel::Document.create
    src.add_page(Pdfbox::Pdmodel::Page.new)
    add_output_intent(src, "GTS_PDFA1", "X")

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)
    add_output_intent(dst, "GTS_PDFA1", "X")
    add_output_intent(dst, "GTS_PDFA1", "Y")

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      intents = dst.document_catalog.not_nil!.output_intents
      # "X" already present -> skipped; "Y" stays; total stays 2.
      intents.size.should eq(2)
      intents.map { |intent| intent.output_condition_identifier || "" }.sort.should eq(["X", "Y"])
    ensure
      src.close
      dst.close
    end
  end

  it "always adds a source output intent whose identifier is Custom" do
    src = Pdfbox::Pdmodel::Document.create
    src.add_page(Pdfbox::Pdmodel::Page.new)
    add_output_intent(src, "GTS_PDFA1", "Custom")

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)
    add_output_intent(dst, "GTS_PDFA1", "Custom")

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      dst.document_catalog.not_nil!.output_intents.size.should eq(2)
    ensure
      src.close
      dst.close
    end
  end

  it "copies the source metadata stream when the destination has none" do
    src = Pdfbox::Pdmodel::Document.create
    src.add_page(Pdfbox::Pdmodel::Page.new)
    metadata = Pdfbox::Cos::Stream.new
    metadata.data = "hello".to_slice
    metadata[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("Metadata")
    metadata[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("XML")
    src.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("Metadata")] = metadata

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      merged_metadata = dst.document_catalog.not_nil!.cos_object.get_stream(Pdfbox::Cos::Name.new("Metadata"))
      merged_metadata.should_not be_nil
      merged_metadata.not_nil!.data.should eq("hello".to_slice)
      merged_metadata.not_nil!.get_name_as_string(Pdfbox::Cos::Name.new("Subtype")).should eq("XML")
      # The decoded metadata is stored without a filter.
      merged_metadata.not_nil![Pdfbox::Cos::Name.new("Filter")]?.should be_nil
    ensure
      src.close
      dst.close
    end
  end

  it "appends source outline items after the destination outline" do
    src = Pdfbox::Pdmodel::Document.create
    src.add_page(Pdfbox::Pdmodel::Page.new)
    src_item = Pdfbox::Cos::Dictionary.new
    src_item.set_string("Title", "src")
    src_outline = Pdfbox::Cos::Dictionary.new
    src_outline.set_name("Type", "Outlines")
    src_outline[Pdfbox::Cos::Name.new("First")] = src_item
    src.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("Outlines")] = src_outline

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)
    dst_item = Pdfbox::Cos::Dictionary.new
    dst_item.set_string("Title", "dst")
    dst_outline = Pdfbox::Cos::Dictionary.new
    dst_outline.set_name("Type", "Outlines")
    dst_outline[Pdfbox::Cos::Name.new("First")] = dst_item
    dst_outline[Pdfbox::Cos::Name.new("Last")] = dst_item
    dst.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("Outlines")] = dst_outline

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      first = dst.document_catalog.not_nil!.document_outline.not_nil!.first_child.not_nil!
      first.title.should eq("dst")
      first.next_sibling.not_nil!.title.should eq("src")
    ensure
      src.close
      dst.close
    end
  end

  it "marks the destination document when merging a tagged source (mergeMarkInfo)" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4408.pdf"))
    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)
    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      info = dst.document_catalog.not_nil!.mark_info
      info.should_not be_nil
      info.not_nil!.marked?.should be_true
    ensure
      src.close
      dst.close
    end
  end

  it "keeps the existing destination metadata" do
    src = Pdfbox::Pdmodel::Document.create
    src.add_page(Pdfbox::Pdmodel::Page.new)
    src_metadata = Pdfbox::Cos::Stream.new
    src_metadata.data = "src".to_slice
    src.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("Metadata")] = src_metadata

    dst = Pdfbox::Pdmodel::Document.create
    dst.add_page(Pdfbox::Pdmodel::Page.new)
    dst_metadata = Pdfbox::Cos::Stream.new
    dst_metadata.data = "dst".to_slice
    dst.document_catalog.not_nil!.cos_object[Pdfbox::Cos::Name.new("Metadata")] = dst_metadata

    begin
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      dst.document_catalog.not_nil!.cos_object
        .get_stream(Pdfbox::Cos::Name.new("Metadata")).not_nil!.data.should eq("dst".to_slice)
    ensure
      src.close
      dst.close
    end
  end
end

private def add_output_intent(doc : Pdfbox::Pdmodel::Document, subtype : String, identifier : String) : Nil
  intent = Pdfbox::Cos::Dictionary.new
  intent.set_name("Type", "OutputIntent")
  intent.set_name("S", subtype)
  intent.set_string("OutputConditionIdentifier", identifier)
  doc.document_catalog.not_nil!.add_output_intent(Pdfbox::Pdmodel::OutputIntent.new(intent))
end
