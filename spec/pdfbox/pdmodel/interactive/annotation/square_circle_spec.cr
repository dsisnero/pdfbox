require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/annotation"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/annotation/PDCircleAnnotationTest.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/annotation/PDSquareAnnotationTest.java
# Model surface parity: default annotation Type/Subtype, and the appearance stream
# (BBox, Matrix translation to origin, content-stream tokens) of a square annotation.
describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle do
  it "PDCircleAnnotationTest#createDefaultCircleAnnotation" do
    annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationCircle.new
    cos = annot.cos_object
    cos[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
    cos[Pdfbox::Cos::Name::SUBTYPE].as(Pdfbox::Cos::Name).value.should eq("Circle")
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare do
  it "PDSquareAnnotationTest#createDefaultSquareAnnotation" do
    annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new
    cos = annot.cos_object
    cos[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
    cos[Pdfbox::Cos::Name::SUBTYPE].as(Pdfbox::Cos::Name).value.should eq("Square")
  end

  it "PDSquareAnnotationTest#createWithAppearance" do
    rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new
    rectangle.lower_left_x = 91.5958_f32
    rectangle.lower_left_y = 741.91_f32
    rectangle.upper_right_x = 113.849_f32
    rectangle.upper_right_y = 757.078_f32

    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)
      annotations = page.annotations

      annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare.new

      border_thin = Pdfbox::Pdmodel::Interactive::Annotation::PDBorderStyleDictionary.new
      border_thin.width = 1

      red = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      annot.contents = "Square Annotation"
      annot.color = red
      annot.border_style = border_thin

      annot.rectangle = rectangle

      annot.construct_appearances
      annotations.add(annot)
    ensure
      document.close
    end
  end

  it "PDSquareAnnotationTest#validateAppearance" do
    rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new
    rectangle.lower_left_x = 91.5958_f32
    rectangle.lower_left_y = 741.91_f32
    rectangle.upper_right_x = 113.849_f32
    rectangle.upper_right_y = 757.078_f32

    file = SpecPaths.resolve("#{ANNOTATION_DIR}/PDSquareAnnotationTest.pdf")
    document = Pdfbox::Pdmodel::Document.load(file)
    begin
      page = document.pages[0]
      annotations = page.annotations
      annot = annotations.get(0)

      annot.should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationSquare)

      appearance = annot.appearance
      appearance.should_not be_nil
      normal = appearance.not_nil!.normal_appearance
      normal.should_not be_nil

      appearance_stream = normal.not_nil!.appearance_stream
      bbox = appearance_stream.bbox
      bbox.should_not be_nil
      bbox.not_nil!.lower_left_x.should be_close(rectangle.lower_left_x, 1e-4_f32)
      bbox.not_nil!.lower_left_y.should be_close(rectangle.lower_left_y, 1e-4_f32)
      bbox.not_nil!.width.should be_close(rectangle.width, 1e-4_f32)
      bbox.not_nil!.height.should be_close(rectangle.height, 1e-4_f32)

      matrix = appearance_stream.matrix
      matrix.translate_x.should be_close(-rectangle.lower_left_x, 1e-4_f32)
      matrix.translate_y.should be_close(-rectangle.lower_left_y, 1e-4_f32)

      content_stream = appearance_stream.content_stream
      content_stream.should_not be_nil
      parser = Pdfbox::Pdfparser::PDFStreamParser.new(content_stream.to_byte_array)
      tokens = parser.parse

      tokens.size.should eq(10)

      tokens[0].as(Pdfbox::Cos::Integer).value.should eq(1)
      tokens[1].as(Pdfbox::Cos::Integer).value.should eq(0)
      tokens[2].as(Pdfbox::Cos::Integer).value.should eq(0)
      tokens[3].as(Pdfbox::ContentStream::Operator).name.should eq("RG")

      tokens[4].as(Pdfbox::Cos::Float).value.should be_close(rectangle.lower_left_x + 1, 1e-4_f32)
      tokens[5].as(Pdfbox::Cos::Float).value.should be_close(rectangle.lower_left_y + 1, 1e-4_f32)
      tokens[6].as(Pdfbox::Cos::Float).value.should be_close(rectangle.width - 2, 1e-4_f32)
      tokens[7].as(Pdfbox::Cos::Float).value.should be_close(rectangle.height - 2, 1e-4_f32)
      tokens[8].as(Pdfbox::ContentStream::Operator).name.should eq("re")
      tokens[9].as(Pdfbox::ContentStream::Operator).name.should eq("S")
    ensure
      document.try(&.close)
    end
  end
end

describe Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget do
  it "PDAnnotationTest#createDefaultWidgetAnnotation" do
    annot = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    cos = annot.cos_object
    cos[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
    cos[Pdfbox::Cos::Name::SUBTYPE].as(Pdfbox::Cos::Name).value.should eq("Widget")
  end

  it "PDAnnotationTest#createWidgetAnnotationFromField" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, Pdfbox::Cos::Dictionary.new, nil)
      widget_annot = text_field.widgets[0]

      cos = widget_annot.cos_object
      cos[Pdfbox::Cos::Name::TYPE].as(Pdfbox::Cos::Name).value.should eq("Annot")
      cos[Pdfbox::Cos::Name::SUBTYPE].as(Pdfbox::Cos::Name).value.should eq("Widget")
    ensure
      document.close
    end
  end
end
