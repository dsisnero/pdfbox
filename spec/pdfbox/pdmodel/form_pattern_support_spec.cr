require "../../spec_helper"
require "../../../src/pdfbox"

describe Pdfbox::Pdmodel::PDResources do
  it "adds form xobjects and tiling patterns with generated resource names" do
    resources = Pdfbox::Pdmodel::PDResources.new
    form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(Pdfbox::Cos::Stream.new)
    pattern = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern.new

    form_name = resources.add(form, "Fm")
    pattern_name = resources.add(pattern, "P")

    form_name.value.should eq("Fm1")
    pattern_name.value.should eq("P1")
    resources.xobject_names.should contain(form_name)
    resources.pattern_names.should contain(pattern_name)
    resources.xobject(form_name).should eq(form.cos_object)
    resources.pattern(pattern_name).as(Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern).cos_object.should eq(pattern.cos_object)
  end
end

describe Pdfbox::Pdmodel::Graphics::Form::PDFormXObject do
  it "stores bbox, matrix, resources, content stream, and transparency group" do
    form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(Pdfbox::Cos::Stream.new)
    resources = Pdfbox::Pdmodel::PDResources.new
    bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(1.0_f32, 2.0_f32, 30.0_f32, 40.0_f32)
    matrix = Pdfbox::Util::Matrix.translate(5.0_f32, 6.0_f32)
    group = Pdfbox::Pdmodel::Graphics::Form::PDTransparencyGroupAttributes.new

    form.resources = resources
    form.bbox = bbox
    form.matrix = matrix
    form.group = group

    form.resources.not_nil!.cos_object.should eq(resources.cos_object)
    form.bbox.not_nil!.width.should eq(30.0_f32)
    form.matrix.get_value(2, 0).should eq(5.0_f32)
    form.matrix.get_value(2, 1).should eq(6.0_f32)
    form.group.not_nil!.cos_object.should eq(group.cos_object)
    form.content_stream.cos_object.should eq(form.cos_object)
  end
end

describe Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern do
  it "stores bbox, steps, paint type, tiling type, and resources" do
    pattern = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern.new
    resources = Pdfbox::Pdmodel::PDResources.new
    bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(0.0_f32, 0.0_f32, 10.0_f32, 12.0_f32)

    pattern.resources = resources
    pattern.bbox = bbox
    pattern.paint_type = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern::PAINT_UNCOLORED
    pattern.tiling_type = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern::TILING_CONSTANT_SPACING_FASTER_TILING
    pattern.x_step = 10
    pattern.y_step = 13

    pattern.pattern_type.should eq(1)
    pattern.resources.not_nil!.cos_object.should eq(resources.cos_object)
    pattern.bbox.not_nil!.height.should eq(12.0_f32)
    pattern.paint_type.should eq(2)
    pattern.tiling_type.should eq(3)
    pattern.x_step.should eq(10.0)
    pattern.y_step.should eq(13.0)
  end
end

describe "form and pattern content streams" do
  it "writes form drawing operators to form and pattern streams" do
    form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(Pdfbox::Cos::Stream.new)
    form.resources = Pdfbox::Pdmodel::PDResources.new
    child_form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(Pdfbox::Cos::Stream.new)
    child_form.resources = Pdfbox::Pdmodel::PDResources.new
    pattern = Pdfbox::Pdmodel::Graphics::Pattern::PDTilingPattern.new

    form_stream = Pdfbox::Pdmodel::PDFormContentStream.new(form)
    form_stream.non_stroking_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.0_f32, 0.0_f32], Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    form_stream.add_rect(0, 0, 10, 12)
    form_stream.draw_form(child_form)
    form_stream.fill
    form_stream.close

    pattern_stream = Pdfbox::Pdmodel::PDPatternContentStream.new(pattern)
    pattern_stream.line_cap_style(1)
    pattern_stream.line_join_style(1)
    pattern_stream.line_width(1)
    pattern_stream.miter_limit(10)
    pattern_stream.move_to(0, 1)
    pattern_stream.line_to(5, 11)
    pattern_stream.line_to(10, 1)
    pattern_stream.stroke
    pattern_stream.close

    form_content = String.new(form.content_stream.create_input_stream.getb_to_end)
    pattern_content = String.new(pattern.content_stream.create_input_stream.getb_to_end)

    form_content.should contain("1 0 0 rg")
    form_content.should contain("re")
    form_content.should contain("Do")
    form_content.should contain("f")
    pattern_content.should contain("1 J")
    pattern_content.should contain("1 j")
    pattern_content.should contain("1 w")
    pattern_content.should contain("10 M")
    pattern_content.should contain("m")
    pattern_content.should contain("l")
    pattern_content.should contain("S")
  end
end
