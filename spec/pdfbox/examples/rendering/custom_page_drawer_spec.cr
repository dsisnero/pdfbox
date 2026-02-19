require "../../../spec_helper"

describe "Examples::Rendering::CustomPageDrawer parity" do
  # Source of truth:
  # vendor/pdfbox/examples/src/test/java/org/apache/pdfbox/examples/rendering/TestCustomPageDrawer.java
  #
  # Blocked by unported example rendering stack (CustomPageDrawer/PDFRenderer image output parity).

  it "TestCustomPageDrawer#testCustomPageDrawer" do
    # Java parity expectations:
    # - CustomPageDrawer.main generates target/custom-render.png
    # - generated PNG is readable and non-nil image data
  end
end
