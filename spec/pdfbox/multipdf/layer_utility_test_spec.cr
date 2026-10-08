require "../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/multipdf/TestLayerUtility.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/multipdf/LayerUtility.java
#
# Imports a page as a Form XObject, wraps it in a save/restore pair, and appends
# it as an optional-content layer. The overlay lives in /Resources /Properties
# as oc1 and in the catalog OCProperties as group "overlay"; the document
# version becomes 1.5.
describe Pdfbox::Multipdf::LayerUtility do
  it "TestLayerUtility#testLayerImport" do
    dir = Dir.tempdir
    main_path = File.join(dir, "layer_main.pdf")
    overlay_path = File.join(dir, "layer_overlay.pdf")
    target_path = File.join(dir, "layer_target.pdf")

    # createMainPDF
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)
    cs = Pdfbox::Pdmodel::PDPageContentStream.new(
      doc, page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE, false
    )
    font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD)
    cs.begin_text
    cs.new_line_at_offset(50, 720)
    cs.set_font(font, 14)
    cs.show_text("Simple test document with text.")
    cs.end_text
    cs.close
    doc.save(main_path, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    doc.close

    # createOverlay1
    overlay_doc0 = Pdfbox::Pdmodel::Document.new
    overlay_page = Pdfbox::Pdmodel::Page.new
    overlay_doc0.add_page(overlay_page)
    cs2 = Pdfbox::Pdmodel::PDPageContentStream.new(
      overlay_doc0, overlay_page, Pdfbox::Pdmodel::PDPageContentStream::AppendMode::OVERWRITE, false
    )
    overlay_font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA_BOLD)
    cs2.non_stroking_color(192.0 / 255.0, 192.0 / 255.0, 192.0 / 255.0)
    cs2.begin_text
    cs2.set_font(overlay_font, 96)
    cs2.set_text_matrix(Pdfbox::Util::Matrix.identity)
    cs2.show_text("OVERLAY")
    cs2.end_text
    cs2.close
    overlay_doc0.save(overlay_path, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    overlay_doc0.close

    target_doc = Pdfbox::Loader.load_pdf(main_path)
    overlay_doc = Pdfbox::Loader.load_pdf(overlay_path)
    begin
      target_doc.version.should be_close(1.4, 0.001)

      layer_util = Pdfbox::Multipdf::LayerUtility.new(target_doc)
      form = layer_util.import_page_as_form(overlay_doc, 0)
      target_page = target_doc.pages[0]
      layer_util.wrap_in_save_restore(target_page)
      layer_util.append_form_as_layer(target_page, form, Pdfbox::Util::Matrix.identity, "overlay")

      target_doc.version.should be_close(1.5, 0.001)
      target_doc.save(target_path, Pdfbox::Pdfwriter::Compress::CompressParameters::NO_COMPRESSION)
    ensure
      target_doc.close
      overlay_doc.close
    end

    reloaded = Pdfbox::Loader.load_pdf(target_path)
    begin
      reloaded.version.should be_close(1.5, 0.001)

      page = reloaded.pages[0]
      ocg = page.resources.not_nil!.properties(Pdfbox::Cos::Name.new("oc1"))
      ocg.should_not be_nil
      ocg.should be_a(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup)
      ocg.not_nil!.as(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup).name.should eq("overlay")

      catalog = reloaded.document_catalog.not_nil!
      overlay = catalog.oc_properties.not_nil!.group("overlay")
      overlay.should_not be_nil
      overlay.not_nil!.name.should eq("overlay")

      # PDFBOX-5232: importing the document into itself must not throw.
      Pdfbox::Multipdf::LayerUtility.new(reloaded).import_page_as_form(reloaded, 0)
    ensure
      reloaded.close
    end
  end
end
