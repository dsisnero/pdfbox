require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDLayoutAttributeObject.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/taggedpdf/PDFourColours.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDGamma.java
#
# Characterization spec: upstream has no dedicated PDLayoutAttributeObject test,
# so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::TaggedPdf
  describe PDFourColours do
    it "reads and writes the four edge colours" do
      four = PDFourColours.new
      four.before_colour.should be_nil

      before = Pdfbox::Pdmodel::Graphics::Color::PDGamma.new
      before.r = 0.1_f32
      before.g = 0.2_f32
      before.b = 0.3_f32
      four.before_colour = before

      read = four.before_colour
      read.should_not be_nil
      read.not_nil!.r.should eq(0.1_f32)
      read.not_nil!.g.should eq(0.2_f32)
      read.not_nil!.b.should eq(0.3_f32)

      end_colour = Pdfbox::Pdmodel::Graphics::Color::PDGamma.new
      end_colour.r = 0.9_f32
      four.end_colour = end_colour
      four.end_colour.not_nil!.r.should eq(0.9_f32)
    end
  end

  describe PDLayoutAttributeObject do
    it "defaults to the Layout owner and documented default values" do
      layout = PDLayoutAttributeObject.new
      layout.owner.should eq("Layout")

      layout.placement.should eq(PDLayoutAttributeObject::PLACEMENT_INLINE)
      layout.writing_mode.should eq(PDLayoutAttributeObject::WRITING_MODE_LRTB)
      layout.border_style.should eq(PDLayoutAttributeObject::BORDER_STYLE_NONE)
      layout.padding.should eq(0.0_f32)
      layout.space_before.should eq(0.0_f32)
      layout.space_after.should eq(0.0_f32)
      layout.start_indent.should eq(0.0_f32)
      layout.end_indent.should eq(0.0_f32)
      layout.text_indent.should eq(0.0_f32)
      layout.text_align.should eq(PDLayoutAttributeObject::TEXT_ALIGN_START)
      layout.width.should eq(PDLayoutAttributeObject::WIDTH_AUTO)
      layout.height.should eq(PDLayoutAttributeObject::HEIGHT_AUTO)
      layout.block_align.should eq(PDLayoutAttributeObject::BLOCK_ALIGN_BEFORE)
      layout.inline_align.should eq(PDLayoutAttributeObject::INLINE_ALIGN_START)
      layout.baseline_shift.should eq(0.0_f32)
      layout.line_height.should eq(PDLayoutAttributeObject::LINE_HEIGHT_NORMAL)
      layout.text_decoration_type.should eq(PDLayoutAttributeObject::TEXT_DECORATION_TYPE_NONE)
      layout.ruby_align.should eq(PDLayoutAttributeObject::RUBY_ALIGN_DISTRIBUTE)
      layout.ruby_position.should eq(PDLayoutAttributeObject::RUBY_POSITION_BEFORE)
      layout.glyph_orientation_vertical.should eq(PDLayoutAttributeObject::GLYPH_ORIENTATION_VERTICAL_AUTO)
      layout.column_count.should eq(1)
      layout.border_thickness.should be_nil
      layout.column_gap.should be_nil
      layout.column_widths.should be_nil
    end

    it "round-trips name and number-or-name attributes and writes the COS keys" do
      layout = PDLayoutAttributeObject.new
      cos = layout.cos_object

      layout.placement = PDLayoutAttributeObject::PLACEMENT_BLOCK
      layout.placement.should eq("Block")
      cos.get_name_as_string(Cos::Name.new("Placement")).should eq("Block")

      layout.writing_mode = PDLayoutAttributeObject::WRITING_MODE_TBRL
      layout.writing_mode.should eq("TbRl")

      layout.width = 100.5
      layout.width.should eq(100.5_f32)
      layout.set_width_auto
      layout.width.should eq("Auto")

      layout.height = 20
      layout.height.should eq(20.0_f32)
      layout.set_height_auto
      layout.height.should eq("Auto")

      layout.text_align = PDLayoutAttributeObject::TEXT_ALIGN_JUSTIFY
      layout.text_align.should eq("Justify")

      layout.line_height = 1.5
      layout.line_height.should eq(1.5_f32)
      layout.set_line_height_normal
      layout.line_height.should eq("Normal")
      layout.set_line_height_auto
      layout.line_height.should eq("Auto")

      layout.glyph_orientation_vertical = PDLayoutAttributeObject::GLYPH_ORIENTATION_VERTICAL_270_DEGREES
      layout.glyph_orientation_vertical.should eq("270")

      layout.column_count = 3
      layout.column_count.should eq(3)
    end

    it "round-trips numeric attributes" do
      layout = PDLayoutAttributeObject.new

      layout.space_before = 1.5
      layout.space_after = 2
      layout.start_indent = 3.25
      layout.end_indent = 4.0
      layout.text_indent = 5
      layout.baseline_shift = 6.5
      layout.text_decoration_thickness = 0.75

      layout.space_before.should eq(1.5_f32)
      layout.space_after.should eq(2.0_f32)
      layout.start_indent.should eq(3.25_f32)
      layout.end_indent.should eq(4.0_f32)
      layout.text_indent.should eq(5.0_f32)
      layout.baseline_shift.should eq(6.5_f32)
      layout.text_decoration_thickness.should eq(0.75_f32)
    end

    it "round-trips number-or-array attributes" do
      layout = PDLayoutAttributeObject.new

      layout.all_border_thicknesses = 2.0
      layout.border_thickness.should eq(2.0_f32)

      layout.border_thicknesses = [1.0_f32, 2.0_f32, 3.0_f32, 4.0_f32]
      layout.border_thickness.as(Array(Float32)).should eq([1.0_f32, 2.0_f32, 3.0_f32, 4.0_f32])

      layout.paddings = [5.0_f32, 6.0_f32, 7.0_f32, 8.0_f32]
      layout.padding.as(Array(Float32)).should eq([5.0_f32, 6.0_f32, 7.0_f32, 8.0_f32])

      layout.all_t_paddings = 1.0
      layout.t_padding.should eq(1.0_f32)

      layout.all_column_widths = 3.0
      layout.column_widths.should eq(3.0_f32)
      layout.column_gaps = [10.0_f32, 20.0_f32]
      layout.column_gap.as(Array(Float32)).should eq([10.0_f32, 20.0_f32])
    end

    it "round-trips name-or-array-of-name attributes" do
      layout = PDLayoutAttributeObject.new

      layout.all_border_styles = PDLayoutAttributeObject::BORDER_STYLE_SOLID
      layout.border_style.should eq("Solid")

      layout.border_styles = ["Solid", "Dotted", "Dashed", "None"]
      layout.border_style.as(Array(String)).should eq(["Solid", "Dotted", "Dashed", "None"])

      layout.all_t_border_styles = PDLayoutAttributeObject::BORDER_STYLE_GROOVE
      layout.t_border_style.should eq("Groove")

      layout.t_border_styles = ["Ridge", "Inset", "Outset", "None"]
      layout.t_border_style.as(Array(String)).should eq(["Ridge", "Inset", "Outset", "None"])
    end

    it "round-trips the bounding box" do
      layout = PDLayoutAttributeObject.new
      layout.bbox.should be_nil

      layout.bbox = Pdfbox::Pdmodel::Common::PDRectangle.new(1.0_f32, 2.0_f32, 30.0_f32, 40.0_f32)
      read = layout.bbox
      read.should_not be_nil
      read.not_nil!.lower_left_x.should eq(1.0_f32)
      read.not_nil!.lower_left_y.should eq(2.0_f32)
      read.not_nil!.width.should eq(30.0_f32)
      read.not_nil!.height.should eq(40.0_f32)

      layout.bbox = nil
      layout.bbox.should be_nil
    end

    it "round-trips colours (single and four-edge)" do
      layout = PDLayoutAttributeObject.new

      background = Pdfbox::Pdmodel::Graphics::Color::PDGamma.new
      background.r = 1.0_f32
      background.g = 0.5_f32
      background.b = 0.25_f32
      layout.background_color = background
      layout.background_color.not_nil!.r.should eq(1.0_f32)
      layout.background_color.not_nil!.b.should eq(0.25_f32)

      # Single border colour (3-element array) is read back as a PDGamma.
      single = Pdfbox::Pdmodel::Graphics::Color::PDGamma.new
      single.r = 0.9_f32
      layout.all_border_colors = single
      layout.border_colors.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDGamma)
      layout.border_colors.as(Pdfbox::Pdmodel::Graphics::Color::PDGamma).r.should eq(0.9_f32)

      # Four border colours (4-element array) is read back as PDFourColours.
      four = PDFourColours.new
      before = Pdfbox::Pdmodel::Graphics::Color::PDGamma.new
      before.g = 0.8_f32
      four.before_colour = before
      layout.border_colors = four
      layout.border_colors.should be_a(PDFourColours)
      layout.border_colors.as(PDFourColours).before_colour.not_nil!.g.should eq(0.8_f32)
    end

    it "dispatches through PDAttributeObject.create on the Layout owner" do
      dict = Cos::Dictionary.new
      dict.set_name(Cos::Name.new("O"), "Layout")
      dict.set_name(Cos::Name.new("Placement"), "Block")

      attribute = Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure::PDAttributeObject.create(dict)
      attribute.should be_a(PDLayoutAttributeObject)
      attribute.as(PDLayoutAttributeObject).placement.should eq("Block")
    end
  end
end
