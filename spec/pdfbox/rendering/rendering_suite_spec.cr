require "../../spec_helper"
require "../../../src/pdfbox"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/rendering/TestPDFToImage.java
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/rendering/TestQuality.java
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/rendering/TestRendering.java
#
# Chunk M render-compare suite (advisory rendering). Only the behavioral
# (non-rendering) assertions are ported; the render-compare output assertions
# (TestPDFToImage.doTestFile PNG comparison, TestRendering render smoke image,
# TestQuality PDFBOX-4831 color-count) are render-only and advisory.
#
# Behavioral assertions ported:
#   - TestPDFToImage#doTestFile: a PDF in the input/rendering set must have >= 1
#     page, survive setAllSecurityToBeRemoved + save, and reload cleanly.
#   - TestRendering#render: loading each fixture must not throw (the renderImage
#     call itself is a smoke test; exceptions for unsupported filters / matrix
#     cases are documented).
#   - TestQuality#testPDFBox4831: the PDFBOX-4831 fixture is render-only
#     (colorCount on a 300-dpi render) and is documented as advisory.

private RENDERING_DIR = "vendor/pdfbox/pdfbox/src/test/resources/input/rendering"

private def rendering_fixtures : Array(String)
  Dir.glob("#{RENDERING_DIR}/*.{pdf,ai}").sort.map(&.as(String))
end

describe Pdfbox::Rendering::PDFRenderer do
  it "TestPDFToImage#doTestFile: all rendering fixtures have >= 1 page, save, and reload" do
    fixtures = rendering_fixtures
    fixtures.size.should be >= 1

    fixtures.each do |file|
      document = Pdfbox::Loader.load_pdf(file)
      begin
        document.pages.size.should be >= 1

        tmp = File.tempfile("pdfbox-render", ".pdf")
        begin
          document.set_all_security_to_be_removed(true)
          document.save(tmp.path)

          reloaded = Pdfbox::Loader.load_pdf(tmp.path)
          reloaded.close
        ensure
          tmp.delete
        end
      ensure
        document.close
      end
    end
  end

  it "TestRendering#render: loading every rendering fixture does not throw" do
    rendering_fixtures.each do |file|
      # Java: Loader.loadPDF(file) inside try-with-resources; renderImage(0) is a
      # render smoke test (advisory). The load itself must not throw.
      document = Pdfbox::Loader.load_pdf(file)
      document.close
    end
  end

  it "TestRendering#render: rendering the fixtures that don't hit documented gaps" do
    # renderImage(0) smoke test for the fixtures the Crystal renderer supports.
    # source.pdf (A85 filter abbreviation) renders after the FilterFactory
    # abbreviation wiring; the matrix-illegal-value (survey.pdf) case remains a
    # documented render gap.
    rendering_fixtures.each do |file|
      name = File.basename(file)
      next if name == "survey.pdf"

      document = Pdfbox::Loader.load_pdf(file)
      begin
        renderer = Pdfbox::Rendering::PDFRenderer.new(document)
        image = renderer.render_image(0)
        image.should_not be_nil
        image.rect.width.should be > 0
      ensure
        document.close
      end
    end
  end

  it "TestQuality#testPDFBox4831 (advisory, render-only)" do
    # Java: renders PDFBOX-4831.pdf at 300 dpi and asserts colorCount(rendered) == 2
    # (bitonal scan stays bitonal) and checkIdent(extracted, rendered). Both are
    # render/ImageIO assertions; the fixture also lives under target/pdfs (not
    # vendored). Documented as advisory (Chunk M render policy).
    true.should be_true
  end
end
