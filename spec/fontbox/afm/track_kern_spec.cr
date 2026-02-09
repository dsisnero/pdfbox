require "../../spec_helper"

describe Fontbox::AFM::TrackKern do
  describe "#initialize" do
    it "sets degree, min_point_size, min_kern, max_point_size, max_kern" do
      tk = Fontbox::AFM::TrackKern.new(0, 1.0_f32, 1.0_f32, 10.0_f32, 10.0_f32)
      tk.degree.should eq(0)
      tk.min_point_size.should eq(1.0_f32)
      tk.min_kern.should eq(1.0_f32)
      tk.max_point_size.should eq(10.0_f32)
      tk.max_kern.should eq(10.0_f32)
    end
  end
end
