require "../../../../spec_helper"

describe "PDAnnotationWidget" do
  it "creates widget with dictionary" do
    dict = Pdfbox::Cos::Dictionary.new
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new(dict)
    widget.cos_object.should be(dict)
  end

  it "sets and gets rectangle" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 100.0_f32, 100.0_f32)
    widget.rectangle = rect
    widget.rectangle.should be_a(Pdfbox::Pdmodel::Common::PDRectangle)
  end

  it "sets and gets flags" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    widget.flags = 3
    widget.flags.should eq(3)
    widget.invisible?.should be_true
    widget.hidden?.should be_true
    widget.printed?.should be_false
  end

  it "returns correct subtype" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    widget.subtype.should eq("Widget")
  end

  it "sets and gets field name" do
    widget = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget.new
    widget.field_name = "TestField"
    widget.field_name.should eq("TestField")
  end
end
