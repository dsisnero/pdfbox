require "../../spec_helper"

describe Fontbox::AFM::Parser do
  describe "#parse" do
    it "raises an error when missing StartFontMetrics" do
      expect_raises(IO::Error) do
        parser = Fontbox::AFM::Parser.new(IO::Memory.new("huhu"))
        parser.parse
      end
    end

    it "raises an error when missing EndFontMetrics" do
      expect_raises(IO::Error, "Unknown AFM key") do
        File.open("spec/resources/fontbox/afm/NoEndFontMetrics.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    it "raises an error on malformed float" do
      expect_raises(IO::Error, "4,1ab") do
        File.open("spec/resources/fontbox/afm/MalformedFloat.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    it "raises an error on malformed integer" do
      expect_raises(IO::Error, "3.4") do
        File.open("spec/resources/fontbox/afm/MalformedInteger.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    # Port of AFMParserTest.checkHelveticaFontMetrics
    it "parses Helvetica font metrics" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        fm = parser.parse

        fm.afm_version.should eq(4.1_f32)
        fm.font_name.should eq("Helvetica")
        fm.full_name.should eq("Helvetica")
        fm.family_name.should eq("Helvetica")
        fm.weight.should eq("Medium")
        fm.font_b_box.lower_left_x.should eq(-166.0_f32)
        fm.font_b_box.lower_left_y.should eq(-225.0_f32)
        fm.font_b_box.upper_right_x.should eq(1000.0_f32)
        fm.font_b_box.upper_right_y.should eq(931.0_f32)
        fm.font_version.should eq("002.000")
        fm.notice.should eq(
          "Copyright (c) 1985, 1987, 1989, 1990, 1997 Adobe Systems Incorporated.  All Rights Reserved.Helvetica is a trademark of Linotype-Hell AG and/or its subsidiaries.")
        fm.encoding_scheme.should eq("AdobeStandardEncoding")
        fm.mapping_scheme.should eq(0)
        fm.esc_char.should eq(0)
        fm.character_set.should eq("ExtendedRoman")
        fm.characters.should eq(0)
        fm.is_base_font.should be_true
        fm.v_vector.should be_empty
        fm.is_fixed_v.should be_false
        fm.cap_height.should eq(718.0_f32)
        fm.x_height.should eq(523.0_f32)
        fm.ascender.should eq(718.0_f32)
        fm.descender.should eq(-207.0_f32)
        fm.standard_horizontal_width.should eq(76.0_f32)
        fm.standard_vertical_width.should eq(88.0_f32)
        fm.comments.size.should eq(4)
        fm.comments.to_a[0].should eq(
          "Copyright (c) 1985, 1987, 1989, 1990, 1997 Adobe Systems Incorporated.  All Rights Reserved.")
        fm.comments.to_a[2].should eq("UniqueID 43054")
        fm.underline_position.should eq(-100.0_f32)
        fm.underline_thickness.should eq(50.0_f32)
        fm.italic_angle.should eq(0.0_f32)
        fm.char_width.should be_empty
        fm.fixed_pitch.should be_false
      end
    end

    # Port of AFMParserTest.checkHelveticaCharMetrics
    it "parses Helvetica char metrics" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse

        char_metrics = font_metrics.char_metrics
        char_metrics.size.should eq(315)

        space = char_metrics.to_a.find { |cm| cm.name == "space" }
        space.should_not be_nil
        space.not_nil!.wx.should eq(278.0_f32)
        space.not_nil!.character_code.should eq(32)
        space.not_nil!.bounding_box.lower_left_x.should eq(0.0_f32)
        space.not_nil!.bounding_box.lower_left_y.should eq(0.0_f32)
        space.not_nil!.bounding_box.upper_right_x.should eq(0.0_f32)
        space.not_nil!.bounding_box.upper_right_y.should eq(0.0_f32)
        space.not_nil!.ligatures.size.should eq(0)

        ring = char_metrics.to_a.find { |cm| cm.name == "ring" }
        ring.should_not be_nil
        ring.not_nil!.wx.should eq(333.0_f32)
        ring.not_nil!.character_code.should eq(202)
        ring.not_nil!.bounding_box.lower_left_x.should eq(75.0_f32)
        ring.not_nil!.bounding_box.lower_left_y.should eq(572.0_f32)
        ring.not_nil!.bounding_box.upper_right_x.should eq(259.0_f32)
        ring.not_nil!.bounding_box.upper_right_y.should eq(756.0_f32)
        ring.not_nil!.ligatures.size.should eq(0)
      end
    end

    it "parses Helvetica kern pairs" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse

        kern_pairs = font_metrics.kern_pairs
        kern_pairs.size.should eq(2705)
        # "KPX A Ucircumflex -50"
        pair = kern_pairs.to_a.find do |kp|
          kp.first_kern_character == "A" && kp.second_kern_character == "Ucircumflex"
        end
        pair.should_not be_nil
        pair.not_nil!.x.should eq(-50.0_f32)
        pair.not_nil!.y.should eq(0.0_f32)
        # "KPX W agrave -40"
        pair2 = kern_pairs.to_a.find do |kp|
          kp.first_kern_character == "W" && kp.second_kern_character == "agrave"
        end
        pair2.should_not be_nil
        pair2.not_nil!.x.should eq(-40.0_f32)
        # KernPairs0/1 and composites are empty
        font_metrics.kern_pairs0.size.should eq(0)
        font_metrics.kern_pairs1.size.should eq(0)
        font_metrics.composites.size.should eq(0)
      end
    end

    it "parses Helvetica font metrics with reduced dataset" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        fm = parser.parse(true)

        fm.afm_version.should eq(4.1_f32)
        fm.font_name.should eq("Helvetica")
        fm.weight.should eq("Medium")
        fm.cap_height.should eq(718.0_f32)
        fm.ascender.should eq(718.0_f32)
        fm.descender.should eq(-207.0_f32)
      end
    end

    it "parses Helvetica char metrics with reduced dataset" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse(true)

        char_metrics = font_metrics.char_metrics
        char_metrics.size.should eq(315)
        space = char_metrics.to_a.find { |cm| cm.name == "space" }
        space.should_not be_nil
        space.not_nil!.wx.should eq(278.0_f32)
      end
    end

    it "parses Helvetica kern pairs with reduced dataset (empty)" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse(true)
        font_metrics.kern_pairs.should be_empty
        font_metrics.kern_pairs0.should be_empty
        font_metrics.kern_pairs1.should be_empty
        font_metrics.composites.should be_empty
      end
    end
  end
end
