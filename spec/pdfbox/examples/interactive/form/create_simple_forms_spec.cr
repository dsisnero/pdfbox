require "../../../../spec_helper"

describe "Examples::Interactive::Form::CreateSimpleForms parity" do
  # Source of truth:
  # vendor/pdfbox/examples/src/test/java/org/apache/pdfbox/examples/interactive/form/TestCreateSimpleForms.java
  #
  # These examples rely on AcroForm/field/widget APIs and rendering components that are not yet
  # available in the Crystal port. Keep Java-parity expectations here so implementation can go
  # red->green in follow-up tasks.

  pending "testCreateSimpleForm" do
    # Java parity expectations:
    # - CreateSimpleForm generates target/TestCreateSimpleForm.pdf
    # - field SampleField value == \"Sample field content\"
    # - setting \"Łódź\" fails for Helvetica with glyph-missing message for U+0141
    # - widget resources include /Helv font named Helvetica, standard14=true
  end

  pending "testAddBorderToField" do
    # Java parity expectations:
    # - CreateSimpleForm first yields green border/yellow background
    # - AddBorderToField rewrites border color to red
    # - color space for border/background is DeviceRGB
  end

  pending "testCreateSimpleFormWithEmbeddedFont" do
    # Java parity expectations:
    # - CreateSimpleFormWithEmbeddedFont generates target/SimpleFormWithEmbeddedFont.pdf
    # - field SampleField value == \"Sample field İ\"
    # - setting \"Łódź\" succeeds with embedded font
    # - widget resources include /F1 with font name LiberationSans
  end

  pending "testCreateMultiWidgetsForm" do
    # Java parity expectations:
    # - output has 2 pages and renders both
    # - SampleField has 2 widgets on different pages
    # - widget appearance colors:
    #   w1 bg=[1,1,0], border=[0,1,0]
    #   w2 bg=[0,1,0], border=[1,0,0]
  end

  pending "testCreateCheckBox" do
    # Java parity expectations:
    # - checkbox MyCheckBox on-value == \"Yes\", initial value == \"Off\"
    # - after check() + save/reload value persists as \"Yes\"
  end

  pending "testRadioButtons" do
    # Java parity expectations:
    # - radio MyRadioButton has 3 widgets
    # - initial value/export selection == \"c\"
    # - export values == [\"a\", \"b\", \"c\"]
    # - after setValue(\"b\") + save/reload selection persists as \"b\"
  end

  pending "testCreatePushButton" do
    # Java parity expectations:
    # - CreatePushButton generates target/PushButtonSample.pdf
    # - AcroForm field \"push\" exists as push button
  end
end
