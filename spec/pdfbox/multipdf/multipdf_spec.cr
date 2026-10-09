require "../../spec_helper"

describe "Pdfbox::Multipdf parity" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/multipdf/
  #
  # Blocked by missing Crystal multipdf module/classes:
  # PDFCloneUtility, LayerUtility, PDFMergerUtility, Overlay, PageExtractor, and related structure tree handling.

  it "PDFCloneUtilityTest#testClonePDFWithCosArrayStream" do
    src_doc = Pdfbox::Pdmodel::Document.new
    dst_doc = Pdfbox::Pdmodel::Document.new
    src_page = Pdfbox::Pdmodel::Page.new
    src_doc.add_page(src_page)
    Pdfbox::Pdmodel::PDPageContentStream.new(
      src_doc, src_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, true
    ).close
    Pdfbox::Pdmodel::PDPageContentStream.new(
      src_doc, src_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, true
    ).close

    cloner = Pdfbox::Multipdf::PDFCloneUtility.new(dst_doc)
    cloner.destination.should be(dst_doc)

    cloned_dict = cloner.clone_for_new_document(src_page.cos_object.not_nil!)
    cloned_dict = cloned_dict.as(Pdfbox::Cos::Dictionary)
    cloned_page = Pdfbox::Pdmodel::Page.new(cloned_dict)
    cloned_page.content_streams.size.should eq(2)
    cloned_page.content_streams.each(&.should_not be_nil)
  end

  it "PDFCloneUtilityTest#testClonePDFWithCosArrayStream2" do
    dir = Dir.tempdir
    src_path = File.join(dir, "clone-src.pdf")
    dst_path = File.join(dir, "clone-dst.pdf")

    src_doc = Pdfbox::Pdmodel::Document.new
    src_page = Pdfbox::Pdmodel::Page.new
    src_doc.add_page(src_page)
    [
      Pdfbox::Pdmodel::Graphics::Color::PDColor.new([0.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE),
      Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE),
      Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 1.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE),
    ].each_with_index do |color, i|
      cs = Pdfbox::Pdmodel::PDPageContentStream.new(
        src_doc, src_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::APPEND, false
      )
      cs.non_stroking_color(color.components[0], color.components[1], color.components[2])
      cs.add_rect(100, 600 - i * 100, 300, 100)
      cs.fill
      cs.close
    end
    src_doc.save(src_path, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    src_doc.close

    src_for_merge = Pdfbox::Loader.load_pdf(src_path)
    dst_doc = Pdfbox::Pdmodel::Document.new
    begin
      merger = Pdfbox::Multipdf::PDFMergerUtility.new
      merger.append_document(dst_doc, src_for_merge)
      dst_doc.save(dst_path)
    ensure
      dst_doc.close
      src_for_merge.close
    end

    [src_path, dst_path].each do |path|
      reloaded = Pdfbox::Loader.load_pdf(path)
      reloaded.number_of_pages.should eq(1)
      reloaded.close
    end
  end

  it "PDFCloneUtilityTest#testDirectIndirect" do
    doc1 = Pdfbox::Pdmodel::Document.new
    doc1.add_page(Pdfbox::Pdmodel::Page.new)
    doc1.document_catalog.not_nil!.oc_properties = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new

    io = ::IO::Memory.new
    doc1.save(io, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)

    doc2 = Pdfbox::Loader.load_pdf(io.to_slice)
    begin
      merger = Pdfbox::Multipdf::PDFMergerUtility.new
      merger.append_document(doc2, doc1)
      doc2.number_of_pages.should eq(2)
    ensure
      doc2.close
      doc1.close
    end
  end

  it "TestLayerUtility#testLayerImport" do
  end

  it "MergeAcroFormsTest#testLegacyModeMerge" do
  end

  it "MergeAcroFormsTest#testAnnotsEntry" do
  end

  it "MergeAcroFormsTest#testAPEntry" do
  end

  it "MergeAnnotationsTest#testLinkAnnotations" do
  end

  it "OverlayTest#testRotatedOverlays" do
  end

  it "OverlayTest#testRotatedOverlaysMap" do
  end

  it "OverlayTest#testOverlayOnRotatedSourcePages" do
  end

  it "PageExtractorTest#testExtract" do
  end

  it "PDFMergerUtilityTest#testPDFMergerUtility" do
  end

  it "PDFMergerUtilityTest#testPDFMergerUtility2" do
  end

  it "PDFMergerUtilityTest#testJpegCcitt" do
  end

  it "PDFMergerUtilityTest#testPDFMergerOpenAction" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge2" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge3" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge4" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge5" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge6" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge7" do
  end

  it "PDFMergerUtilityTest#testMissingParentTreeNextKey" do
  end

  it "PDFMergerUtilityTest#testStructureTreeMergeIDTree" do
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents1" do
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents2" do
  end

  it "PDFMergerUtilityTest#testParentTree" do
  end

  it "PDFMergerUtilityTest#testFileDeletion" do
  end

  it "PDFMergerUtilityTest#testPDFBox5198_2" do
  end

  it "PDFMergerUtilityTest#testPDFBox5198_3" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTree" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinations" do
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinationsAndRemovedAnnotations" do
  end

  it "PDFMergerUtilityTest#testSinglePageSplit" do
  end

  it "PDFMergerUtilityTest#testSplitWithPopupAnnotations" do
  end

  it "PDFMergerUtilityTest#testSplitWithBrokenDestination" do
  end

  it "PDFMergerUtilityTest#testSplitWithNamedDestinations" do
  end

  it "PDFMergerUtilityTest#testSplitWithPgEntryAtTheTop" do
  end

  it "PDFMergerUtilityTest#testSplitWithOrphanPopupAnnotation" do
  end

  it "PDFMergerUtilityTest#testOutlinesSelfParent" do
  end

  it "PDFMergerUtilityTest#testPDFBox515" do
  end
end
