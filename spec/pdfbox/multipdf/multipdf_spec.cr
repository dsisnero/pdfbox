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
    in_dir = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBoxLegacyMerge-SameMerged.pdf")
    to_be_merged = File.join(in_dir, "AcroFormForMerge.pdf")

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.destination_file_name = out_path
    merger.destination_file_name.should eq(out_path)
    merger.add_source(to_be_merged)
    merger.add_source(to_be_merged)
    merger.merge_documents(nil)
    merger.acro_form_merge_mode = Pdfbox::Multipdf::PDFMergerUtility::AcroFormMergeMode::PDFBOX_LEGACY_MODE
    merger.acro_form_merge_mode.should eq(Pdfbox::Multipdf::PDFMergerUtility::AcroFormMergeMode::PDFBOX_LEGACY_MODE)

    compliant = Pdfbox::Loader.load_pdf(File.join(in_dir, "PDFBoxLegacyMerge-SameMerged.pdf"))
    compared = Pdfbox::Loader.load_pdf(out_path)
    begin
      compliant_form = compliant.document_catalog.not_nil!.acro_form
      compared_form = compared.document_catalog.not_nil!.acro_form
      compliant_form.should_not be_nil
      compared_form.should_not be_nil
      compliant_form.not_nil!.fields.size.should eq(compared_form.not_nil!.fields.size)

      compliant_form.not_nil!.get_field_tree.each do |field|
        compared_form.not_nil!.get_field(field.fully_qualified_name).should_not be_nil
      end
    ensure
      compliant.close
      compared.close
    end
  end

  it "MergeAcroFormsTest#testAnnotsEntry" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-1031.pdf")

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.destination_file_name = out_path
    merger.add_source(File.join(dir, "PDFBOX-1031-1.pdf"))
    merger.add_source(File.join(dir, "PDFBOX-1031-2.pdf"))
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      merged.number_of_pages.should eq(2)
      (0..1).each do |i|
        page = merged.get_page(i)
        page.cos_object.not_nil![Pdfbox::Cos::Name.new("Annots")]?.should_not be_nil
        page.annotations.size.should eq(1)
      end
    ensure
      merged.close
    end
  end

  it "MergeAcroFormsTest#testAPEntry" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-1100.pdf")

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.destination_file_name = out_path
    merger.add_source(File.join(dir, "PDFBOX-1100-1.pdf"))
    merger.add_source(File.join(dir, "PDFBOX-1100-2.pdf"))
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      merged.number_of_pages.should eq(2)
      acro_form = merged.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil

      ["Testfeld", "Testfeld2"].each do |name|
        field = acro_form.not_nil!.get_field(name)
        field.should_not be_nil
        field.not_nil!.cos_object[Pdfbox::Cos::Name.new("AP")]?.should_not be_nil
        field.not_nil!.cos_object[Pdfbox::Cos::Name.new("V")]?.should_not be_nil
      end
    ensure
      merged.close
    end
  end

  it "MergeAnnotationsTest#testLinkAnnotations" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-1065.pdf")

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.destination_file_name = out_path
    merger.add_source(File.join(dir, "PDFBOX-1065-1.pdf"))
    merger.add_source(File.join(dir, "PDFBOX-1065-2.pdf"))
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      merged.number_of_pages.should eq(6)

      destinations = merged.document_catalog.not_nil!.dests
      destinations.should_not be_nil
      destinations.not_nil!.cos_object.entries.size.should eq(12)

      source1 = merged.get_page(0).annotations
      source2 = merged.get_page(3).annotations
      target1 = merged.get_page(2).annotations
      target2 = merged.get_page(5).annotations

      source1.size.should eq(3)
      target1.size.should eq(3)
      source2.size.should eq(3)
      target2.size.should eq(3)

      match = ->(srcs : Enumerable(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation), tgts : Enumerable(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation)) do
        target_names = [] of String
        tgts.each do |a|
          name = (a.cos_object[Pdfbox::Cos::Name.new("Dest")]?.as?(Pdfbox::Cos::Name)).try(&.value)
          target_names << name if name
        end
        srcs.all? do |a|
          src_name = (a.cos_object[Pdfbox::Cos::Name.new("Dest")]?.as?(Pdfbox::Cos::Name)).try(&.value)
          !src_name.nil? && target_names.includes?("annoRef_#{src_name}")
        end
      end

      match.call(source1, target1).should be_true
      match.call(source2, target2).should be_true
    ensure
      merged.close
    end
  end

  it "OverlayTest#testRotatedOverlays" do
  end

  it "OverlayTest#testRotatedOverlaysMap" do
  end

  it "OverlayTest#testOverlayOnRotatedSourcePages" do
  end

  it "PageExtractorTest#testExtract" do
    source_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/cweb.pdf")
    source_pdf = Pdfbox::Loader.load_pdf(source_path)
    begin
      result = Pdfbox::Multipdf::PageExtractor.new(source_pdf).extract
      result.number_of_pages.should eq(source_pdf.number_of_pages)
      result.close

      result = Pdfbox::Multipdf::PageExtractor.new(source_pdf, 1, 1).extract
      result.number_of_pages.should eq(1)
      result.close

      result = Pdfbox::Multipdf::PageExtractor.new(source_pdf, 1, 5).extract
      result.number_of_pages.should eq(5)
      result.close

      result = Pdfbox::Multipdf::PageExtractor.new(source_pdf, 5, 10).extract
      result.number_of_pages.should eq(6)
      result.close

      result = Pdfbox::Multipdf::PageExtractor.new(source_pdf, 2, 1).extract
      result.number_of_pages.should eq(0)
      result.close
    ensure
      source_pdf.close
    end
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
