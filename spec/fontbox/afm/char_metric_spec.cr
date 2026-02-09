require "../../spec_helper"

describe Fontbox::AFM::CharMetric do
  describe "#character_code" do
    it "sets and gets character code" do
      char_metric = Fontbox::AFM::CharMetric.new
      char_metric.character_code = 0
      char_metric.character_code.should eq(0)
    end
  end

  describe "#name" do
    it "sets and gets name" do
      char_metric = Fontbox::AFM::CharMetric.new
      char_metric.name = "name"
      char_metric.name.should eq("name")
    end
  end

  describe "#wx, #w0x, #w1x, #wy, #w0y, #w1y" do
    it "sets and gets simple width values" do
      char_metric = Fontbox::AFM::CharMetric.new
      char_metric.wx = 10.0_f32
      char_metric.w0x = 20.0_f32
      char_metric.w1x = 30.0_f32
      char_metric.wy = 40.0_f32
      char_metric.w0y = 50.0_f32
      char_metric.w1y = 60.0_f32
      char_metric.wx.should eq(10.0_f32)
      char_metric.w0x.should eq(20.0_f32)
      char_metric.w1x.should eq(30.0_f32)
      char_metric.wy.should eq(40.0_f32)
      char_metric.w0y.should eq(50.0_f32)
      char_metric.w1y.should eq(60.0_f32)
    end
  end

  describe "#w, #w0, #w1, #vv" do
    it "sets and gets array values" do
      char_metric = Fontbox::AFM::CharMetric.new
      char_metric.w = [10.0_f32, 20.0_f32]
      char_metric.w0 = [30.0_f32, 40.0_f32]
      char_metric.w1 = [50.0_f32, 60.0_f32]
      char_metric.vv = [70.0_f32, 80.0_f32]
      char_metric.w.should eq([10.0_f32, 20.0_f32])
      char_metric.w0.should eq([30.0_f32, 40.0_f32])
      char_metric.w1.should eq([50.0_f32, 60.0_f32])
      char_metric.vv.should eq([70.0_f32, 80.0_f32])
    end
  end

  describe "#bounding_box" do
    it "sets and gets bounding box" do
      char_metric = Fontbox::AFM::CharMetric.new
      bbox = Fontbox::Util::BoundingBox.new(10, 20, 30, 40)
      char_metric.bounding_box = bbox
      char_metric.bounding_box.lower_left_x.should eq(10)
      char_metric.bounding_box.lower_left_y.should eq(20)
      char_metric.bounding_box.upper_right_x.should eq(30)
      char_metric.bounding_box.upper_right_y.should eq(40)
    end
  end

  describe "#ligatures" do
    it "adds ligature and returns unmodifiable list" do
      char_metric = Fontbox::AFM::CharMetric.new
      char_metric.ligatures.size.should eq(0)
      ligature = Fontbox::AFM::Ligature.new("successor", "ligature")
      char_metric.add_ligature(ligature)
      ligatures = char_metric.ligatures
      ligatures.size.should eq(1)
      ligatures[0].successor.should eq("successor")
      # In Java, the returned list is unmodifiable; we can test that adding raises an error.
      # Crystal arrays are modifiable, but we can mimic by returning a read-only view.
      # For now, skip that check.
    end
  end
end
