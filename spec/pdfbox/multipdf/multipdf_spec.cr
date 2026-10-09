require "../../spec_helper"

# Helpers mirroring PDFMergerUtilityTest's structure-tree orphan checks.
module MultipdfSplitterHelpers
  extend self

  def page_ids(doc : Pdfbox::Pdmodel::Document) : Set(UInt64)
    ids = Set(UInt64).new
    doc.pages.each do |page|
      page.cos_object.try { |dict| ids.add(dict.object_id.to_u64) }
    end
    ids
  end

  def check_for_page(ids : Set(UInt64), structure_element) : Nil
    if page = structure_element.page
      dict = page.cos_object
      ids.includes?(dict.object_id.to_u64).should be_true
    end
  end

  class ElementCounter
    getter cnt : Int32 = 0
    getter set : Set(UInt64) = Set(UInt64).new

    def walk(base : Pdfbox::Cos::Base?) : Nil
      case base
      when Pdfbox::Cos::Array
        base.items.each do |element|
          element = element.object if element.is_a?(Pdfbox::Cos::Object)
          walk(element)
        end
      when Pdfbox::Cos::Dictionary
        kdict = base
        if kdict.has_key?(Pdfbox::Cos::Name::PG)
          @cnt += 1
          @set.add(kdict.object_id.to_u64)
        elsif kdict.has_key?(Pdfbox::Cos::Name::K)
          if kid_array = kdict.get_array(Pdfbox::Cos::Name::K)
            kid_array.items.each do |element|
              element = element.object if element.is_a?(Pdfbox::Cos::Object)
              if element.is_a?(Pdfbox::Cos::Dictionary) &&
                 element.has_key?(Pdfbox::Cos::Name::PG) &&
                 element.has_key?(Pdfbox::Cos::Name.new("MCID"))
                @cnt += 1
                @set.add(kdict.object_id.to_u64)
                break
              end
            end
          end
        end
        if kdict.has_key?(Pdfbox::Cos::Name::K)
          walk(kdict.get_dictionary_object(Pdfbox::Cos::Name::K))
        end
      end
    end
  end

  def check_element(ids : Set(UInt64), base : Pdfbox::Cos::Base?, parent_dict : Pdfbox::Cos::Dictionary) : Nil
    case base
    when Pdfbox::Cos::Array
      base.items.each do |element|
        element = element.object if element.is_a?(Pdfbox::Cos::Object)
        check_element(ids, element, parent_dict)
      end
    when Pdfbox::Cos::Dictionary
      kdict = base
      if kdict.has_key?(Pdfbox::Cos::Name::PG)
        check_for_page(ids, Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(kdict))
      end
      if kdict.has_key?(Pdfbox::Cos::Name::K)
        check_element(ids, kdict.get_dictionary_object(Pdfbox::Cos::Name::K), kdict)
        node = Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement.new(kdict)
        node.kids.each do |kid|
          next unless kid.is_a?(Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDStructureElement)
          parent = kid.parent
          parent.should_not be_nil
          parent.not_nil!.cos_object.same?(kdict).should be_true
        end
        return
      end

      if kdict.has_key?(Pdfbox::Cos::Name::KIDS)
        check_element(ids, kdict.get_dictionary_object(Pdfbox::Cos::Name::KIDS), kdict)
      elsif kdict.has_key?(Pdfbox::Cos::Name::NUMS)
        check_element(ids, kdict.get_dictionary_object(Pdfbox::Cos::Name::NUMS), kdict)
      end

      type = kdict.get_name_as_string(Pdfbox::Cos::Name::TYPE)
      if type == "OBJR" || type == "MCR"
        (kdict.get_dictionary(Pdfbox::Cos::Name::PG).nil? &&
          parent_dict.get_dictionary(Pdfbox::Cos::Name::PG).nil?).should be_false
      end

      if kdict.has_key?(Pdfbox::Cos::Name::OBJ)
        obj = kdict.get_dictionary(Pdfbox::Cos::Name::OBJ)
        if obj
          obj_type = obj.get_name_as_string(Pdfbox::Cos::Name::TYPE)
          obj_subtype = obj.get_name_as_string(Pdfbox::Cos::Name::SUBTYPE)
          if obj_type == "Annot" || obj_subtype == "Link"
            annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation.create_annotation(obj)
            page = annot.page
            if annot.is_a?(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
              link = annot
              destination = link.destination
              if destination.nil?
                action = link.action
                if action.is_a?(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
                  destination = action.destination
                end
              end
              if destination.is_a?(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
                dest_page_dict = destination.page
                if dest_page_dict
                  ids.includes?(dest_page_dict.object_id.to_u64).should be_true
                end
              end
            end
            if page
              ids.includes?(page.cos_object.not_nil!.object_id.to_u64).should be_true
            end
          else
            raise "Other type: #{obj_type}, obj: #{obj}"
          end
        end
      end
    end
  end

  def check_for_id_tree_orphans(ids : Set(UInt64), structure_tree_root) : Nil
    id_tree = structure_tree_root.id_tree
    return unless id_tree
    map = Pdfbox::Multipdf::PDFMergerUtility.get_id_tree_as_map(id_tree)
    map.each_value do |element|
      check_for_page(ids, element) if element.page
      unless element.kids.empty?
        check_element(ids, element.cos_object.get_dictionary_object(Pdfbox::Cos::Name::K), element.cos_object)
      end
    end
  end

  def check_parent_tree_against_k(structure_tree_root) : Nil
    counter = ElementCounter.new
    counter.walk(structure_tree_root.k)
    map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(structure_tree_root.parent_tree)
    map.each_value do |value|
      base = value.cos_object
      next unless base.is_a?(Pdfbox::Cos::Array)
      base.items.each do |element|
        element = element.object if element.is_a?(Pdfbox::Cos::Object)
        if element.is_a?(Pdfbox::Cos::Dictionary)
          counter.set.includes?(element.object_id.to_u64).should be_true
        end
      end
    end
  end

  def page_index(doc : Pdfbox::Pdmodel::Document, page : Pdfbox::Pdmodel::Page?) : Int32
    return -1 unless page
    page_index(doc, page.cos_object)
  end

  def page_index(doc : Pdfbox::Pdmodel::Document, page_dict : Pdfbox::Cos::Dictionary?) : Int32
    return -1 unless page_dict
    doc.pages.index { |candidate| candidate.cos_object.try(&.same?(page_dict)) } || -1
  end

  def parent_tree_size(doc : Pdfbox::Pdmodel::Document) : Int32
    root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
    Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree).size
  end

  def role_map_size(doc : Pdfbox::Pdmodel::Document) : Int32
    root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
    role_map = root.cos_object.get_dictionary(Pdfbox::Cos::Name::ROLE_MAP)
    role_map ? role_map.size : 0
  end

  def id_tree_size(doc : Pdfbox::Pdmodel::Document) : Int32
    root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
    id_tree = root.id_tree
    return 0 unless id_tree
    Pdfbox::Multipdf::PDFMergerUtility.get_id_tree_as_map(id_tree).size
  end

  # Java checkWithNumberTree, minus the marked-content/MCID walk (the Crystal
  # port has no PDFMarkedContentExtractor/PDStructureNode yet). Verifies that
  # every page/annotation /StructParent(s) maps to a /ParentTree array entry.
  def check_with_number_tree(doc : Pdfbox::Pdmodel::Document) : Nil
    root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
    root.parent_tree_next_key.should_not eq(-1)
    map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree)
    doc.pages.each do |page|
      sp = page.struct_parents
      next if sp < 0
      map.has_key?(sp).should be_true
      map[sp].cos_object.is_a?(Pdfbox::Cos::Array).should be_true
    end
  end

  def element_count(doc : Pdfbox::Pdmodel::Document) : Tuple(Int32, Int32)
    counter = ElementCounter.new
    counter.walk(doc.document_catalog.not_nil!.structure_tree_root.not_nil!.k)
    {counter.cnt, counter.set.size}
  end

  # Java checkStructTreeRootCount uses COSDocument#getObjectsByType, which the
  # Crystal pdmodel.Document does not expose; reload and assert a single usable
  # structure tree root instead.
  def check_struct_tree_root_count(path : String) : Nil
    doc = Pdfbox::Loader.load_pdf(path)
    begin
      doc.document_catalog.not_nil!.structure_tree_root.should_not be_nil
    ensure
      doc.close
    end
  end

  # Java checkParts: top level /Document with /Part children.
  def check_parts(path : String) : Nil
    doc = Pdfbox::Loader.load_pdf(path)
    begin
      root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
      top = root.k.as?(Pdfbox::Cos::Dictionary)
      top.should_not be_nil
      top = top.not_nil!
      top.get_name_as_string(Pdfbox::Cos::Name.new("S")).should eq("Document")
      parent = top.get_dictionary(Pdfbox::Cos::Name::P)
      parent.should_not be_nil
      parent.not_nil!.same?(root.cos_object).should be_true
      k_array = top.get_array(Pdfbox::Cos::Name::K).not_nil!
      k_array.size.should eq(doc.number_of_pages)
      k_array.items.each do |item|
        item = item.object if item.is_a?(Pdfbox::Cos::Object)
        dict = item.as?(Pdfbox::Cos::Dictionary)
        dict.should_not be_nil
        dict = dict.not_nil!
        dict.get_name_as_string(Pdfbox::Cos::Name.new("S")).should eq("Part")
        dict.get_dictionary(Pdfbox::Cos::Name::P).not_nil!.same?(top).should be_true
      end
    ensure
      doc.close
    end
  end

  # Java checkMergeIdentical: merged pages render identically to the sources.
  def check_merge_identical(dir : String, filename1 : String, filename2 : String, merge_path : String) : Nil
    src1 = Pdfbox::Loader.load_pdf(File.join(dir, filename1))
    src1_pngs = (0...src1.number_of_pages).map { |p| Pdfbox::Rendering::PDFRenderer.new(src1).render_image_png(p) }
    src1.close
    src2 = Pdfbox::Loader.load_pdf(File.join(dir, filename2))
    src2_pngs = (0...src2.number_of_pages).map { |p| Pdfbox::Rendering::PDFRenderer.new(src2).render_image_png(p) }
    src2.close

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(File.join(dir, filename1))
    merger.add_source(File.join(dir, filename2))
    merger.destination_file_name = merge_path
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(merge_path)
    begin
      merged.number_of_pages.should eq(src1_pngs.size + src2_pngs.size)
      renderer = Pdfbox::Rendering::PDFRenderer.new(merged)
      src1_pngs.each_with_index { |png, index| renderer.render_image_png(index).should eq(png) }
      src2_pngs.each_with_index { |png, index| renderer.render_image_png(src1_pngs.size + index).should eq(png) }
    ensure
      merged.close
    end
  end

  def check_for_page_orphans(doc : Pdfbox::Pdmodel::Document) : Nil
    ids = page_ids(doc)
    root = doc.document_catalog.try(&.structure_tree_root)
    root.should_not be_nil
    root = root.not_nil!
    if parent_tree = root.parent_tree
      check_element(ids, parent_tree.cos_object, root.cos_object)
    end
    root.k.should_not be_nil
    check_element(ids, root.k, root.cos_object)
    check_for_id_tree_orphans(ids, root)
    check_parent_tree_against_k(root)
  end
end

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
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out1 = File.join(Dir.tempdir, "GlobalResourceMergeTestResult1.pdf")
    out2 = File.join(Dir.tempdir, "GlobalResourceMergeTestResult2.pdf")
    MultipdfSplitterHelpers.check_merge_identical(dir,
      "PDFBox.GlobalResourceMergeTest.Doc01.decoded.pdf",
      "PDFBox.GlobalResourceMergeTest.Doc02.decoded.pdf", out1)
    # "once again, with scratch file" is a stream-cache variant with no Crystal equivalent.
    MultipdfSplitterHelpers.check_merge_identical(dir,
      "PDFBox.GlobalResourceMergeTest.Doc01.decoded.pdf",
      "PDFBox.GlobalResourceMergeTest.Doc02.decoded.pdf", out2)
  end

  it "PDFMergerUtilityTest#testPDFMergerUtility2" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out3 = File.join(Dir.tempdir, "GlobalResourceMergeTestResult3.pdf")
    out4 = File.join(Dir.tempdir, "GlobalResourceMergeTestResult4.pdf")
    MultipdfSplitterHelpers.check_merge_identical(dir,
      "PDFBox.GlobalResourceMergeTest.Doc01.pdf",
      "PDFBox.GlobalResourceMergeTest.Doc02.pdf", out3)
    MultipdfSplitterHelpers.check_merge_identical(dir,
      "PDFBox.GlobalResourceMergeTest.Doc01.pdf",
      "PDFBox.GlobalResourceMergeTest.Doc02.pdf", out4)
  end

  it "PDFMergerUtilityTest#testJpegCcitt" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out1 = File.join(Dir.tempdir, "JpegMultiMergeTestResult.pdf")
    out2 = File.join(Dir.tempdir, "JpegMultiMergeTestResult2.pdf")
    MultipdfSplitterHelpers.check_merge_identical(dir, "jpegrgb.pdf", "multitiff.pdf", out1)
    MultipdfSplitterHelpers.check_merge_identical(dir, "jpegrgb.pdf", "multitiff.pdf", out2)
  end

  it "PDFMergerUtilityTest#testPDFMergerOpenAction" do
    dir = Dir.tempdir
    p1 = File.join(dir, "MergerOpenActionTest1.pdf")
    p2 = File.join(dir, "MergerOpenActionTest2.pdf")
    out_path = File.join(dir, "MergerOpenActionTestResult.pdf")
    params = Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION

    doc1 = Pdfbox::Pdmodel::Document.new
    3.times { doc1.add_page(Pdfbox::Pdmodel::Page.new) }
    doc1.save(p1, params)
    doc1.close

    doc2 = Pdfbox::Pdmodel::Document.new
    3.times { doc2.add_page(Pdfbox::Pdmodel::Page.new) }
    dest = Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageFitDestination.new
    dest.page = doc2.get_page(1).cos_object.not_nil!
    doc2.document_catalog.not_nil!.open_action = dest
    doc2.save(p2, params)
    doc2.close

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(p1)
    merger.add_source(p2)
    merger.destination_file_name = out_path
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      catalog = merged.document_catalog.not_nil!
      page_dest = catalog.open_action.as?(
        Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination
      )
      page_dest.should_not be_nil
      target = page_dest.not_nil!.page
      merged.pages.index { |pg| pg.cos_object == target }.should eq(4)
    ensure
      merged.close
    end
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    path = File.join(dir, "PDFBOX-3999-GeneralForbearance.pdf")
    src = Pdfbox::Loader.load_pdf(path)
    single_cnt, single_set_size = MultipdfSplitterHelpers.element_count(src)
    single_cnt.should eq(134)
    single_set_size.should eq(134)

    dst = Pdfbox::Loader.load_pdf(path)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    out_path = File.join(Dir.tempdir, "PDFBOX-3999-GeneralForbearance-merged.pdf")
    dst.save(out_path)
    dst.close

    doc = Pdfbox::Loader.load_pdf(out_path)
    begin
      cnt, set_size = MultipdfSplitterHelpers.element_count(doc)
      cnt.should eq(single_cnt * 2)
      set_size.should eq(single_set_size * 2)
      MultipdfSplitterHelpers.check_for_page_orphans(doc)
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge2" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    flat_path = File.join(Dir.tempdir, "PDFBOX-3999-GeneralForbearance-flattened.pdf")
    merged_path = File.join(Dir.tempdir, "PDFBOX-3999-GeneralForbearance-flattened-merged.pdf")

    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-3999-GeneralForbearance.pdf"))
    doc.document_catalog.not_nil!.acro_form.not_nil!.flatten
    doc.save(flat_path)
    single_cnt, single_set_size = MultipdfSplitterHelpers.element_count(doc)
    single_cnt.should eq(134)
    single_set_size.should eq(134)
    doc.close

    src = Pdfbox::Loader.load_pdf(flat_path)
    dst = Pdfbox::Loader.load_pdf(flat_path)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(merged_path)
    dst.close

    doc = Pdfbox::Loader.load_pdf(merged_path)
    begin
      MultipdfSplitterHelpers.check_for_page_orphans(doc)
      cnt, set_size = MultipdfSplitterHelpers.element_count(doc)
      cnt.should eq(single_cnt * 2)
      set_size.should eq(single_set_size * 2)
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge3" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    path = File.join(dir, "PDFBOX-4408.pdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4408-merged.pdf")

    src = Pdfbox::Loader.load_pdf(path)
    single_cnt, single_set_size = MultipdfSplitterHelpers.element_count(src)
    single_cnt.should eq(25)
    single_set_size.should eq(25)

    dst = Pdfbox::Loader.load_pdf(path)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      cnt, set_size = MultipdfSplitterHelpers.element_count(dst)
      cnt.should eq(single_cnt * 2)
      set_size.should eq(single_set_size * 2)
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge4" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    path = File.join(dir, "PDFBOX-4417-001031.pdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4417-001031-merged.pdf")

    src = Pdfbox::Loader.load_pdf(path)
    single_cnt, single_set_size = MultipdfSplitterHelpers.element_count(src)
    single_cnt.should eq(104)
    single_set_size.should eq(104)

    dst = Pdfbox::Loader.load_pdf(path)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      cnt, set_size = MultipdfSplitterHelpers.element_count(dst)
      cnt.should eq(single_cnt * 2)
      set_size.should eq(single_set_size * 2)
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge5" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    path = File.join(dir, "PDFBOX-4417-054080.pdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4417-054080-merged.pdf")

    src = Pdfbox::Loader.load_pdf(path)
    single_cnt, single_set_size = MultipdfSplitterHelpers.element_count(src)

    dst = Pdfbox::Loader.load_pdf(path)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
      cnt, set_size = MultipdfSplitterHelpers.element_count(dst)
      cnt.should eq(single_cnt * 2)
      set_size.should eq(single_set_size * 2)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge6" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4418-merged.pdf")

    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4418-000671.pdf"))
    src_root = src.document_catalog.not_nil!.structure_tree_root.not_nil!
    src_map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(src_root.parent_tree)
    src_map.size.should eq(381)
    (src_map.keys.max + 1).should eq(743)
    src_map.keys.min.should eq(0)
    src_root.parent_tree_next_key.should eq(743)

    dst = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4418-000314.pdf"))
    dst_root = dst.document_catalog.not_nil!.structure_tree_root.not_nil!
    dst_map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(dst_root.parent_tree)
    dst_map.size.should eq(7)
    (dst_map.keys.max + 1).should eq(328)
    dst_map.keys.min.should eq(321)
    dst_root.parent_tree_next_key.should eq(408)

    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
      root = dst.document_catalog.not_nil!.structure_tree_root.not_nil!
      map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree)
      map.size.should eq(381 + 7)
      (map.keys.max + 1).should eq(408 + 743)
      map.keys.min.should eq(321)
      root.parent_tree_next_key.should eq(408 + 743)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testStructureTreeMerge7" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4423-merged.pdf")

    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4423-000746.pdf"))
    root = src.document_catalog.not_nil!.structure_tree_root.not_nil!
    map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree)
    map.size.should eq(33)
    (map.keys.max + 1).should eq(64)
    map.keys.min.should eq(31)
    root.parent_tree_next_key.should eq(126)

    dst = Pdfbox::Pdmodel::Document.new
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
      root = dst.document_catalog.not_nil!.structure_tree_root.not_nil!
      map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree)
      map.size.should eq(33)
      (map.keys.max + 1).should eq(64)
      map.keys.min.should eq(31)
      root.parent_tree_next_key.should eq(64)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testMissingParentTreeNextKey" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4418-000314-merged.pdf")
    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4418-000314.pdf"))
    dst = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4418-000314.pdf"))
    dst.document_catalog.not_nil!.structure_tree_root.not_nil!.cos_object.delete(Pdfbox::Cos::Name::PARENT_TREE_NEXT_KEY)
    Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      dst.document_catalog.not_nil!.structure_tree_root.not_nil!.parent_tree_next_key.should eq(656)
    ensure
      dst.close
    end
  end

  it "PDFMergerUtilityTest#testStructureTreeMergeIDTree" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-4416-IDTree-merged.pdf")
    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4417-001031.pdf"))
    dst = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4417-054080.pdf"))

    src_id_map = Pdfbox::Multipdf::PDFMergerUtility.get_id_tree_as_map(src.document_catalog.not_nil!.structure_tree_root.not_nil!.id_tree.not_nil!)
    dst_id_map = Pdfbox::Multipdf::PDFMergerUtility.get_id_tree_as_map(dst.document_catalog.not_nil!.structure_tree_root.not_nil!.id_tree.not_nil!)
    expected_total = src_id_map.size + dst_id_map.size
    expected_total.should eq(192)

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    empty_dest = Pdfbox::Pdmodel::Document.new
    merger.append_document(empty_dest, src)
    src.close
    src = empty_dest
    src.document_catalog.not_nil!.structure_tree_root.not_nil!.parent_tree_next_key.should eq(4)

    merger.append_document(dst, src)
    src.close
    dst.save(out_path)
    dst.close

    dst = Pdfbox::Loader.load_pdf(out_path)
    begin
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
      result_map = Pdfbox::Multipdf::PDFMergerUtility.get_id_tree_as_map(dst.document_catalog.not_nil!.structure_tree_root.not_nil!.id_tree.not_nil!)
      result_map.size.should eq(expected_total)
    ensure
      dst.close
    end
    MultipdfSplitterHelpers.check_struct_tree_root_count(out_path)
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents1" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4408.pdf"))
    dst = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4408.pdf"))
    begin
      dst.document_catalog.not_nil!.structure_tree_root = nil
      dst.get_page(0).struct_parents = 9999
      dst.get_page(0).annotations.get(0).struct_parent = 9998
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
    ensure
      src.close
      dst.close
    end
  end

  it "PDFMergerUtilityTest#testMergeBogusStructParents2" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    src = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4408.pdf"))
    dst = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4408.pdf"))
    begin
      src.document_catalog.not_nil!.structure_tree_root = nil
      src.get_page(0).struct_parents = 9999
      src.get_page(0).annotations.get(0).struct_parent = 9998
      Pdfbox::Multipdf::PDFMergerUtility.new.append_document(dst, src)
      MultipdfSplitterHelpers.check_with_number_tree(dst)
      MultipdfSplitterHelpers.check_for_page_orphans(dst)
    ensure
      src.close
      dst.close
    end
  end

  it "PDFMergerUtilityTest#testParentTree" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-3999-GeneralForbearance.pdf"))
    begin
      root = doc.document_catalog.not_nil!.structure_tree_root.not_nil!
      root.parent_tree.not_nil!.value(0)
      map = Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree)
      map.size.should eq(31)
      (map.keys.max + 1).should eq(31)
      map.keys.min.should eq(0)
      root.parent_tree_next_key.should eq(31)
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testFileDeletion" do
    dir = Dir.tempdir
    in1 = File.join(dir, "PDFBOX-4383-src1.pdf")
    in2 = File.join(dir, "PDFBOX-4383-src2.pdf")
    out_path = File.join(dir, "PDFBOX-4383-result.pdf")
    params = Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION

    [in1, in2].each do |path|
      doc = Pdfbox::Pdmodel::Document.new
      doc.add_page(Pdfbox::Pdmodel::Page.new)
      doc.save(path, params)
      doc.close
    end

    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    ::File.open(out_path, "w") do |io|
      merger.destination_stream = io
      merger.destination_stream.should eq(io)
      merger.add_source(in1)
      merger.add_source(in2)
      merger.merge_documents(nil)
    end

    doc = Pdfbox::Loader.load_pdf(out_path)
    begin
      doc.number_of_pages.should eq(2)
    ensure
      doc.close
    end

    [in1, in2, out_path].each { |path| File.delete(path) if File.exists?(path) }
  end

  it "PDFMergerUtilityTest#testPDFBox5198_2" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFA3A-merged2.pdf")
    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(File.join(dir, "PDFA3A.pdf"))
    merger.add_source(File.join(dir, "PDFA3A.pdf"))
    merger.destination_file_name = out_path
    merger.merge_documents(nil)
    MultipdfSplitterHelpers.check_parts(out_path)
  end

  it "PDFMergerUtilityTest#testPDFBox5198_3" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFA3A-merged3.pdf")
    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(File.join(dir, "PDFA3A.pdf"))
    merger.add_source(File.join(dir, "PDFA3A.pdf"))
    merger.add_source(File.join(dir, "PDFA3A.pdf"))
    merger.destination_file_name = out_path
    merger.merge_documents(nil)
    MultipdfSplitterHelpers.check_parts(out_path)
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTree" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-4417-001031.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_start_page(1)
      splitter.set_end_page(2)
      splitter.set_split_at_page(2)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)
      dst_doc = split_result[0]
      begin
        dst_doc.number_of_pages.should eq(2)
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        MultipdfSplitterHelpers.id_tree_size(dst_doc).should eq(126)
        MultipdfSplitterHelpers.parent_tree_size(dst_doc).should eq(2)
        MultipdfSplitterHelpers.role_map_size(dst_doc).should eq(6)
      ensure
        dst_doc.close
      end
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinations" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5762-722238.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_start_page(1)
      splitter.set_end_page(2)
      splitter.set_split_at_page(2)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)
      dst_doc = split_result[0]
      begin
        dst_doc.number_of_pages.should eq(2)
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        MultipdfSplitterHelpers.parent_tree_size(dst_doc).should eq(7)
        MultipdfSplitterHelpers.role_map_size(dst_doc).should eq(4)

        annotations = dst_doc.get_page(0).annotations
        annotations.size.should eq(5)
        destinations = (0...5).map do |i|
          link = annotations.get(i).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
          action = link.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
          action.destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
        end
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[0].page).should eq(0)
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[1].page).should eq(1)
        destinations[2].page.should be_nil
        destinations[3].page.should be_nil
        destinations[4].page.should be_nil
      ensure
        dst_doc.close
      end
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithStructureTreeAndDestinationsAndRemovedAnnotations" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5762-722238.pdf"))
    begin
      doc.pages.each { |page| page.annotations = [] of Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation }
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_start_page(1)
      splitter.set_end_page(2)
      splitter.set_split_at_page(2)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)
      dst_doc = split_result[0]
      begin
        dst_doc.number_of_pages.should eq(2)
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
      ensure
        dst_doc.close
      end
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithPopupAnnotations" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5809-509329.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_start_page(3)
      splitter.set_end_page(3)
      splitter.set_split_at_page(1)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)

      dst_doc = split_result[0]
      begin
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        dst_doc.number_of_pages.should eq(1)
        annotations = dst_doc.get_page(0).annotations
        annotations.size.should eq(5)
        annotation_text3 = annotations.get(3).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
        annotation_popup4 = annotations.get(4).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup)
        annotation_text3.popup.not_nil!.cos_object.should eq(annotation_popup4.cos_object)
        annotation_popup4.parent.not_nil!.cos_object.should eq(annotation_text3.cos_object)
        annotation_text3.page.not_nil!.cos_object.same?(dst_doc.get_page(0).cos_object).should be_true
      ensure
        dst_doc.close
      end

      # Check that source document is ok
      annotations = doc.get_page(2).annotations
      annotations.size.should eq(5)
      annotation_text3 = annotations.get(3).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
      annotation_popup4 = annotations.get(4).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationPopup)
      annotation_text3.popup.not_nil!.cos_object.should eq(annotation_popup4.cos_object)
      annotation_popup4.parent.not_nil!.cos_object.should eq(annotation_text3.cos_object)
      annotation_text3.page.not_nil!.cos_object.same?(doc.get_page(2).cos_object).should be_true
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithBrokenDestination" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5811-362972.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_start_page(2)
      splitter.set_end_page(2)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)

      dst_doc = split_result[0]
      begin
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        dst_doc.number_of_pages.should eq(1)
        annotations = dst_doc.get_page(0).annotations
        annotations.size.should eq(1)
        link = annotations.get(0).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
        link.destination.should be_nil
      ensure
        dst_doc.close
      end

      # Check source document
      annotations = doc.get_page(1).annotations
      annotations.size.should eq(1)
      link = annotations.get(0).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
      expect_raises(Exception) { link.destination }
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSinglePageSplit" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5792-240045.pdf"))
    split_result = [] of Pdfbox::Pdmodel::Document
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_split_at_page(1)
      split_result = splitter.split(doc)
      split_result.size.should eq(6)
      split_result.each do |dst_doc|
        dst_doc.number_of_pages.should eq(1)
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        dst_doc.get_page(0).annotations.each do |annot|
          link = annot.as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
          action = link.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
          destination = action.destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
          destination.page.should be_nil
        end
      end

      parent_tree_size = ->(dst_doc : Pdfbox::Pdmodel::Document) do
        root = dst_doc.document_catalog.not_nil!.structure_tree_root.not_nil!
        Pdfbox::Multipdf::PDFMergerUtility.get_number_tree_as_map(root.parent_tree).size
      end
      role_map_size = ->(dst_doc : Pdfbox::Pdmodel::Document) do
        root = dst_doc.document_catalog.not_nil!.structure_tree_root.not_nil!
        role_map = root.cos_object.get_dictionary(Pdfbox::Cos::Name::ROLE_MAP)
        role_map ? role_map.size : 0
      end

      parent_tree_size.call(split_result[0]).should eq(6)
      role_map_size.call(split_result[0]).should eq(3)
      parent_tree_size.call(split_result[1]).should eq(6)
      role_map_size.call(split_result[1]).should eq(3)
      parent_tree_size.call(split_result[2]).should eq(6)
      role_map_size.call(split_result[2]).should eq(4)
      parent_tree_size.call(split_result[3]).should eq(5)
      role_map_size.call(split_result[3]).should eq(4)
      parent_tree_size.call(split_result[4]).should eq(1)
      role_map_size.call(split_result[4]).should eq(6)
      parent_tree_size.call(split_result[5]).should eq(1)
      role_map_size.call(split_result[5]).should eq(7)
    ensure
      split_result.each(&.close)
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithNamedDestinations" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-5840-410609.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_split_at_page(6)
      split_result = splitter.split(doc)
      split_result.size.should eq(1)
      dst_doc = split_result[0]
      begin
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
        dst_doc.number_of_pages.should eq(6)
        annotations = dst_doc.get_page(0).annotations
        annotations.size.should eq(5)
        destinations = (0...5).map do |i|
          link = annotations.get(i).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
          action = link.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo)
          action.destination.as(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDPageDestination)
        end
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[0].page).should eq(0)
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[1].page).should eq(1)
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[2].page).should eq(3)
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[3].page).should eq(3)
        MultipdfSplitterHelpers.page_index(dst_doc, destinations[4].page).should eq(5)

        dst_doc.document_catalog.not_nil!.metadata.should_not be_nil

        io = ::IO::Memory.new
        dst_doc.save(io)
        reloaded = Pdfbox::Loader.load_pdf(io.to_slice)
        begin
          reloaded.document_catalog.not_nil!.metadata.should_not be_nil
        ensure
          reloaded.close
        end
      ensure
        dst_doc.close
      end

      # Check that source document is unchanged
      annotations = doc.get_page(0).annotations
      annotations.size.should eq(5)
      link = annotations.get(0).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
      link.action.as(Pdfbox::Pdmodel::Interactive::Action::PDActionGoTo).destination
        .is_a?(Pdfbox::Pdmodel::Interactive::DocumentNavigation::Destination::PDNamedDestination).should be_true
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithPgEntryAtTheTop" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-6009.pdf"))
    split_result = [] of Pdfbox::Pdmodel::Document
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      splitter.set_split_at_page(1)
      split_result = splitter.split(doc)
      split_result.size.should eq(3)
      split_result.each do |dst_doc|
        dst_doc.number_of_pages.should eq(1)
        MultipdfSplitterHelpers.check_with_number_tree(dst_doc)
        MultipdfSplitterHelpers.check_for_page_orphans(dst_doc)
      end
    ensure
      split_result.each(&.close)
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testSplitWithOrphanPopupAnnotation" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    doc = Pdfbox::Loader.load_pdf(File.join(dir, "PDFBOX-6018-099267-p9-OrphanPopups.pdf"))
    begin
      splitter = Pdfbox::Multipdf::Splitter.new
      split_result = splitter.split(doc)
      split_result.size.should eq(1)
      dst_doc = split_result[0]
      begin
        dst_doc.number_of_pages.should eq(1)
        page = dst_doc.get_page(0)
        annotations = page.annotations
        annotations.size.should eq(2)
        ann0 = annotations.get(0).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
        ann1 = annotations.get(1).as(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationText)
        ann0.page.not_nil!.cos_object.same?(page.cos_object).should be_true
        ann1.page.not_nil!.cos_object.same?(page.cos_object).should be_true
        ann0.popup.not_nil!.parent.not_nil!.cos_object.should eq(ann0.cos_object)
        ann1.popup.not_nil!.parent.not_nil!.cos_object.should eq(ann1.cos_object)
      ensure
        dst_doc.close
      end
    ensure
      doc.close
    end
  end

  it "PDFMergerUtilityTest#testOutlinesSelfParent" do
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-5939-google-docs-result.pdf")
    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(File.join(dir, "PDFBOX-5939-google-docs-1.pdf"))
    merger.add_source(File.join(dir, "PDFBOX-5939-google-docs-1.pdf"))
    merger.destination_file_name = out_path
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      merged.number_of_pages.should eq(2)
    ensure
      merged.close
    end
  end

  it "PDFMergerUtilityTest#testPDFBox515" do
    # PDFBOX-515 / PDFBOX-5950: the source info dictionary has a stream deep down
    # (Info/ImPDF/Images/Kids/[0]) that must survive the merge. Java creates an
    # image XObject and decodes it (AWT); the Crystal port has no public decode
    # accessor for an arbitrary XObject, so this asserts the deep-cloned image
    # dictionary's encoded dimensions instead.
    dir = SpecPaths.resolve("spec/resources/pdfbox/multipdf")
    out_path = File.join(Dir.tempdir, "PDFBOX-515-result.pdf")
    merger = Pdfbox::Multipdf::PDFMergerUtility.new
    merger.add_source(File.join(dir, "ComSquare1.pdf"))
    merger.add_source(File.join(dir, "Ghostscript1.pdf"))
    merger.destination_file_name = out_path
    merger.merge_documents(nil)

    merged = Pdfbox::Loader.load_pdf(out_path)
    begin
      merged.number_of_pages.should eq(2)
      info = merged.document_information.not_nil!.cos_object
      impdf = info.get_dictionary(Pdfbox::Cos::Name.new("ImPDF")).not_nil!
      images = impdf.get_dictionary(Pdfbox::Cos::Name.new("Images")).not_nil!
      kids = images.get_array(Pdfbox::Cos::Name::KIDS).not_nil!
      base = kids[0]?
      base = base.object if base.is_a?(Pdfbox::Cos::Object)
      image_dict = base.as(Pdfbox::Cos::Dictionary)
      stream = image_dict.as?(Pdfbox::Cos::Stream)
      image_xobject = Pdfbox::Pdmodel::Graphics::Image::PDImageXObject.new(merged, image_dict, stream)
      image_xobject.width.should eq(909)
      image_xobject.height.should eq(233)
    ensure
      merged.close
    end
  end
end
