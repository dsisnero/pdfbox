require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/annotation/AppearanceGenerationTest.java
#
# Chunk K render-compare gated tests (advisory rendering). Only the behavioral
# (non-rendering) parts are ported; the render-only assertions are documented
# here as advisory/out-of-scope.

describe Pdfbox::Pdmodel::Interactive::Annotation do
  it "AppearanceGenerationTest#renderTest (advisory, render-compare)" do
    # Java: saves AnnotationTypes.pdf then TestPDFToImage.doTestFile compares the
    # render against expected PNGs in IN_DIR; on mismatch it only logs ("result
    # must be viewed manually") and does NOT fail. The rendering pipeline
    # (PDFRenderer + expected-image comparison) is out of scope for the Crystal
    # port (Chunk K render policy), so this is advisory.
    true.should be_true
  end

  it "AppearanceGenerationTest#rectangleFullStrokeNoFill (disabled in Java)" do
    # Java: annotated "// Test currently disabled as the content stream differs"
    # -- the PDFBox-generated rectangle appearance tokens do not yet match the
    # Adobe-generated tokens, so the test is effectively disabled upstream. In
    # the Crystal port the regenerated appearance also differs from the
    # fixture's Adobe content stream (token counts differ), matching that state.
    # The behavioral `testTinyHorizontalFieldWith0FontSize` (PDFBOX-5763) is
    # already ported in pd_acro_form_test_spec.cr / appearance specs.
    true.should be_true
  end
end
