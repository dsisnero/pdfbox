require "../../spec_helper"

describe Fontbox::AFM::FontMetrics do
  describe "names" do
    it "sets and gets font name, family name, full name, version, notice" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.font_name = "fontName"
      fm.family_name = "familyName"
      fm.full_name = "fullName"
      fm.font_version = "fontVersion"
      fm.notice = "notice"
      fm.font_name.should eq("fontName")
      fm.family_name.should eq("familyName")
      fm.full_name.should eq("fullName")
      fm.font_version.should eq("fontVersion")
      fm.notice.should eq("notice")
    end

    it "adds comments" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.comments.size.should eq(0)
      fm.add_comment("comment")
      comments = fm.comments
      comments.size.should eq(1)
      # Java returns unmodifiable lists; adding to the returned list raises.
      expect_raises(Exception) do
        comments << "another"
      end
    end
  end

  describe "simple values" do
    it "sets and gets various numeric properties" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.afm_version = 4.3_f32
      fm.weight = "weight"
      fm.encoding_scheme = "encodingScheme"
      fm.mapping_scheme = 0
      fm.esc_char = 0
      fm.character_set = "characterSet"
      fm.characters = 10
      fm.is_base_font = true
      fm.is_fixed_v = true
      fm.cap_height = 10.0_f32
      fm.x_height = 20.0_f32
      fm.ascender = 30.0_f32
      fm.descender = 40.0_f32
      fm.standard_horizontal_width = 50.0_f32
      fm.standard_vertical_width = 60.0_f32
      fm.underline_position = 70.0_f32
      fm.underline_thickness = 80.0_f32
      fm.italic_angle = 90.0_f32
      fm.fixed_pitch = true

      fm.afm_version.should eq(4.3_f32)
      fm.weight.should eq("weight")
      fm.encoding_scheme.should eq("encodingScheme")
      fm.mapping_scheme.should eq(0)
      fm.esc_char.should eq(0)
      fm.character_set.should eq("characterSet")
      fm.characters.should eq(10)
      fm.is_base_font.should be_true
      fm.is_fixed_v.should be_true
      fm.cap_height.should eq(10.0_f32)
      fm.x_height.should eq(20.0_f32)
      fm.ascender.should eq(30.0_f32)
      fm.descender.should eq(40.0_f32)
      fm.standard_horizontal_width.should eq(50.0_f32)
      fm.standard_vertical_width.should eq(60.0_f32)
      fm.underline_position.should eq(70.0_f32)
      fm.underline_thickness.should eq(80.0_f32)
      fm.italic_angle.should eq(90.0_f32)
      fm.fixed_pitch.should be_true
    end
  end

  describe "complex values" do
    it "sets and gets font bounding box, v_vector, char_width" do
      fm = Fontbox::AFM::FontMetrics.new
      bbox = Fontbox::Util::BoundingBox.new(10, 20, 30, 40)
      fm.font_b_box = bbox
      fm.v_vector = [10.0_f32, 20.0_f32]
      fm.char_width = [30.0_f32, 40.0_f32]
      fm.font_b_box.lower_left_x.should eq(10)
      fm.font_b_box.lower_left_y.should eq(20)
      fm.font_b_box.upper_right_x.should eq(30)
      fm.font_b_box.upper_right_y.should eq(40)
      fm.v_vector.should eq([10.0_f32, 20.0_f32])
      fm.char_width.should eq([30.0_f32, 40.0_f32])
    end
  end

  describe "metric sets" do
    it "sets and gets metric sets" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.metric_sets = 1
      fm.metric_sets.should eq(1)
    end

    it "rejects metric sets values outside 0..2" do
      fm = Fontbox::AFM::FontMetrics.new
      expect_raises(ArgumentError) do
        fm.metric_sets = -1
      end
      expect_raises(ArgumentError) do
        fm.metric_sets = 3
      end
    end
  end

  describe "char metrics" do
    it "adds char metric" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.char_metrics.size.should eq(0)
      char_metric = Fontbox::AFM::CharMetric.new
      fm.add_char_metric(char_metric)
      char_metrics = fm.char_metrics
      char_metrics.size.should eq(1)
      # Java returns unmodifiable lists.
      expect_raises(Exception) do
        char_metrics << char_metric
      end
    end
  end

  describe "composites" do
    it "adds composite" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.composites.size.should eq(0)
      composite = Fontbox::AFM::Composite.new("name")
      fm.add_composite(composite)
      composites = fm.composites
      composites.size.should eq(1)
      expect_raises(Exception) do
        composites << composite
      end
    end
  end

  describe "kern data" do
    it "adds kern pairs, track kern" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.kern_pairs.size.should eq(0)
      kern_pair = Fontbox::AFM::KernPair.new("first", "second", 10.0_f32, 20.0_f32)
      fm.add_kern_pair(kern_pair)
      fm.kern_pairs.size.should eq(1)
      fm.add_kern_pair0(kern_pair)
      fm.kern_pairs0.size.should eq(1)
      fm.add_kern_pair1(kern_pair)
      fm.kern_pairs1.size.should eq(1)
      fm.track_kern.size.should eq(0)
      track_kern = Fontbox::AFM::TrackKern.new(0, 1.0_f32, 1.0_f32, 10.0_f32, 10.0_f32)
      fm.add_track_kern(track_kern)
      fm.track_kern.size.should eq(1)
      # Java returns unmodifiable lists.
      expect_raises(Exception) do
        fm.kern_pairs << kern_pair
      end
    end
  end

  describe "character dimensions" do
    it "computes character width, height, average width from added char metrics" do
      fm = Fontbox::AFM::FontMetrics.new
      fm.average_character_width.should eq(0.0_f32)

      cm10 = Fontbox::AFM::CharMetric.new
      cm10.name = "ten"
      cm10.wx = 10.0_f32
      cm10.wy = 20.0_f32
      fm.add_char_metric(cm10)
      cm20 = Fontbox::AFM::CharMetric.new
      cm20.name = "twenty"
      cm20.wx = 20.0_f32
      cm20.wy = 40.0_f32
      fm.add_char_metric(cm20)
      cm30 = Fontbox::AFM::CharMetric.new
      cm30.name = "thirty"
      cm30.wx = 30.0_f32
      cm30.wy = 60.0_f32
      fm.add_char_metric(cm30)
      cm40 = Fontbox::AFM::CharMetric.new
      cm40.name = "forty"
      cm40.wx = 40.0_f32
      cm40.wy = 80.0_f32
      fm.add_char_metric(cm40)

      fm.character_width("ten").should eq(10.0_f32)
      fm.character_width("thirty").should eq(30.0_f32)
      fm.character_width("unknown").should eq(0.0_f32)

      fm.character_height("twenty").should eq(40.0_f32)
      fm.character_height("forty").should eq(80.0_f32)
      fm.character_height("unknown").should eq(0.0_f32)

      fm.average_character_width.should eq(25.0_f32)
    end
  end
end
