require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "MultilineFields.pdf"
private TEST_VALUE     = "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/MultilineFieldsTest.java
# testMultilineBreak (PDFBOX-3835) compares appearance line counts against
# Acrobat-generated lines and is covered by the round-trip here when possible.
private def font_size_from_appearance_stream(field : Pdfbox::Pdmodel::Interactive::Form::PDField) : Float32
  widget = field.widgets[0]
  stream = widget.normal_appearance_stream
  return 0.0_f32 unless stream

  parser = Pdfbox::Pdfparser::PDFStreamParser.new(stream.require_stream_object.create_input_stream.getb_to_end)
  token = parser.parse_next_token
  while token
    if token.is_a?(Pdfbox::Cos::Name) && token.value == "Helv"
      token = parser.parse_next_token
      case token
      when Pdfbox::Cos::Integer
        return token.value.to_f32
      when Pdfbox::Cos::Float
        return token.value.to_f32
      end
    end
    token = parser.parse_next_token
  end
  0.0_f32
end

describe Pdfbox::Pdmodel::Interactive::Form::PDTextField do
  it "MultilineFieldsTest#fillFields" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      %w(
        AlignLeft AlignMiddle AlignRight
        AlignLeft-Border_Small AlignMiddle-Border_Small AlignRight-Border_Small
        AlignLeft-Border_Medium AlignMiddle-Border_Medium AlignRight-Border_Medium
        AlignLeft-Border_Wide AlignMiddle-Border_Wide AlignRight-Border_Wide
      ).each do |name|
        field = acro_form.not_nil!.get_field(name).as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
        field.value = TEST_VALUE
        field.value.should eq(TEST_VALUE)
      end
    ensure
      document.close
    end
  end

  it "MultilineFieldsTest#testMultilineAuto (PDFBOX-3812)" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/PDFBOX3812-acrobat-multiline-auto.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form

      field_multiline = acro_form.not_nil!.get_field("Multiline").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      font_size_multiline = font_size_from_appearance_stream(field_multiline)

      field_singleline = acro_form.not_nil!.get_field("Singleline").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      font_size_singleline = font_size_from_appearance_stream(field_singleline)

      field_multiline_autoscale = acro_form.not_nil!.get_field("MultilineAutoscale").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      font_size_multiline_autoscale = font_size_from_appearance_stream(field_multiline_autoscale)

      field_singleline_autoscale = acro_form.not_nil!.get_field("SinglelineAutoscale").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      font_size_singleline_autoscale = font_size_from_appearance_stream(field_singleline_autoscale)

      field_multiline.value = "Multiline - Fixed"
      field_singleline.value = "Singleline - Fixed"
      field_multiline_autoscale.value = "Multiline - auto"
      field_singleline_autoscale.value = "Singleline - auto"

      font_size_from_appearance_stream(field_multiline).should be_close(font_size_multiline, 0.001)
      font_size_from_appearance_stream(field_singleline).should be_close(font_size_singleline, 0.001)
      font_size_from_appearance_stream(field_multiline_autoscale).should be_close(font_size_multiline_autoscale, 0.001)
      font_size_from_appearance_stream(field_singleline_autoscale).should be_close(font_size_singleline_autoscale, 0.025)
    ensure
      document.close
    end
  end
end
