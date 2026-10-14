require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDExtendedGraphicsState.java
#
# Characterization spec: upstream has no dedicated test for the ExtGState setter
# surface / transfer functions, so these assertions are inferred from the Java
# observable behavior.
module Pdfbox::Pdmodel::Graphics::State
  describe PDExtendedGraphicsState do
    it "round-trips the numeric and boolean setters" do
      gs = PDExtendedGraphicsState.new

      gs.line_width = 2.5_f32
      gs.line_width.should eq(2.5_f32)
      gs.line_cap_style = 1
      gs.line_cap_style.should eq(1)
      gs.line_join_style = 2
      gs.line_join_style.should eq(2)
      gs.miter_limit = 4.0_f32
      gs.miter_limit.should eq(4.0_f32)
      gs.flatness_tolerance = 0.5_f32
      gs.flatness_tolerance.should eq(0.5_f32)
      gs.smoothness_tolerance = 0.25_f32
      gs.smoothness_tolerance.should eq(0.25_f32)
      gs.overprint_mode = 1
      gs.overprint_mode.should eq(1)
      gs.stroking_overprint_control = true
      gs.stroking_overprint_control.should be_true
      gs.non_stroking_overprint_control = false
      gs.non_stroking_overprint_control.should be_false
      gs.automatic_stroke_adjustment = false
      gs.automatic_stroke_adjustment.should be_false
      gs.text_knockout_flag = false
      gs.text_knockout_flag.should be_false

      # nil clears the numeric entries
      gs.line_width = nil
      gs.line_width.should be_nil
      gs.overprint_mode = nil
      gs.overprint_mode.should be_nil
    end

    it "defaults automatic-stroke-adjustment to false and falls back to stroking for /op" do
      gs = PDExtendedGraphicsState.new
      gs.automatic_stroke_adjustment.should be_false

      gs.stroking_overprint_control = true
      # /op absent -> Java returns the stroking overprint value
      gs.non_stroking_overprint_control.should be_true
    end

    it "round-trips the dash pattern and rendering intent" do
      gs = PDExtendedGraphicsState.new

      pattern = Pdfbox::Pdmodel::Graphics::PDLineDashPattern.new(
        Pdfbox::Cos::Array.new([Pdfbox::Cos::Integer.new(3)]), 2
      )
      gs.line_dash_pattern = pattern
      read = gs.line_dash_pattern
      read.should_not be_nil
      read.not_nil!.dash_array.should eq([3.0])
      read.not_nil!.phase.should eq(2)

      gs.rendering_intent = "Perceptual"
      gs.rendering_intent.should eq(RenderingIntent::Perceptual)
    end

    it "round-trips the transfer functions with the 4-element array rule" do
      gs = PDExtendedGraphicsState.new
      gs.transfer.should be_nil

      identity = Pdfbox::Cos::Name.new("Identity")
      gs.transfer = identity
      gs.transfer.as?(Pdfbox::Cos::Name).try(&.value).should eq("Identity")

      four = Pdfbox::Cos::Array.new([
        Pdfbox::Cos::Name.new("Identity"), Pdfbox::Cos::Name.new("Identity"),
        Pdfbox::Cos::Name.new("Identity"), Pdfbox::Cos::Name.new("Identity"),
      ])
      gs.transfer = four
      gs.transfer.should be(four)

      # an array that is not exactly 4 entries is invalid -> null (Java getTransfer)
      two = Pdfbox::Cos::Array.new([Pdfbox::Cos::Name.new("Identity"), Pdfbox::Cos::Name.new("Identity")])
      gs.transfer = two
      gs.transfer.should be_nil

      gs.transfer2 = Pdfbox::Cos::Name.new("Default")
      gs.transfer2.as?(Pdfbox::Cos::Name).try(&.value).should eq("Default")
    end
  end
end
