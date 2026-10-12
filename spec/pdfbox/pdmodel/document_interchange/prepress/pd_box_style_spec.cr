require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/prepress/PDBoxStyle.java
#
# Characterization spec: upstream has no dedicated PDBoxStyle test, so these
# assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::Prepress
  describe PDBoxStyle do
    it "has the documented defaults" do
      box = PDBoxStyle.new

      color = box.guideline_color
      color.components.should eq([0.0_f32, 0.0_f32, 0.0_f32])
      color.color_space.should be(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)

      box.guideline_width.should eq(1.0_f32)
      box.guideline_style.should eq(PDBoxStyle::GUIDELINE_STYLE_SOLID)

      dash = box.line_dash_pattern
      dash.dash_array.should eq([3.0])
      dash.phase.should eq(0)

      # The default getters materialise the entries.
      box.cos_object.get_array(Cos::Name.new("C")).should_not be_nil
      box.cos_object.get_array(Cos::Name.new("D")).should_not be_nil
    end

    it "round-trips the guideline width, style, colour, and dash pattern" do
      box = PDBoxStyle.new

      box.guideline_width = 2.5_f32
      box.guideline_width.should eq(2.5_f32)
      box.cos_object.get_float(Cos::Name.new("W"), 0.0).should eq(2.5)

      box.guideline_style = PDBoxStyle::GUIDELINE_STYLE_DASHED
      box.guideline_style.should eq("D")
      box.cos_object.get_name_as_string(Cos::Name.new("S")).should eq("D")

      rgb = Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE
      box.guide_line_color = Pdfbox::Pdmodel::Graphics::Color::PDColor.new([1.0_f32, 0.5_f32, 0.25_f32], rgb)
      read = box.guideline_color
      read.components.should eq([1.0_f32, 0.5_f32, 0.25_f32])
      read.color_space.should be(rgb)

      box.line_dash_pattern = Cos::Array.new([Cos::Integer.new(4), Cos::Integer.new(2)])
      box.line_dash_pattern.dash_array.should eq([4.0, 2.0])
    end

    it "removes the entries when set to nil" do
      box = PDBoxStyle.new
      box.guideline_color   # materialise /C
      box.line_dash_pattern # materialise /D

      box.guide_line_color = nil
      box.cos_object.get_array(Cos::Name.new("C")).should be_nil

      box.line_dash_pattern = nil
      box.cos_object.get_array(Cos::Name.new("D")).should be_nil
    end
  end
end
