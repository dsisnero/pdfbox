# Port of org.apache.pdfbox.pdmodel.graphics.color.PDLabTest
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Color::PDLab do
  it "checks default values and getters/setters" do
    pd_lab = Pdfbox::Pdmodel::Graphics::Color::PDLab.new
    cos_array = pd_lab.cos_object.as(Pdfbox::Cos::Array)
    dict = cos_array[1]
    dict = dict.object if dict.is_a?(Pdfbox::Cos::Object)
    dict = dict.as(Pdfbox::Cos::Dictionary)

    # test with default values
    pd_lab.name.should eq("Lab")
    pd_lab.number_of_components.should eq(3)
    pd_lab.initial_color.should_not be_nil
    pd_lab.initial_color.components.should eq([0.0_f32, 0.0_f32, 0.0_f32])
    pd_lab.blackpoint.x.should eq(0.0)
    pd_lab.blackpoint.y.should eq(0.0)
    pd_lab.blackpoint.z.should eq(0.0)
    pd_lab.whitepoint.x.should eq(1.0)
    pd_lab.whitepoint.y.should eq(1.0)
    pd_lab.whitepoint.z.should eq(1.0)
    pd_lab.a_range.min.should eq(-100.0)
    pd_lab.a_range.max.should eq(100.0)
    pd_lab.b_range.min.should eq(-100.0)
    pd_lab.b_range.max.should eq(100.0)
    dict.entries.size.should eq(0), "read operations should not change the size of /Lab objects"
    dict.to_s

    # test setting specific values
    pd_range = Pdfbox::Pdmodel::Common::PDRange.new
    pd_range.min = -1.0
    pd_range.max = 2.0
    pd_lab.a_range = pd_range
    pd_range = Pdfbox::Pdmodel::Common::PDRange.new
    pd_range.min = 3.0
    pd_range.max = 4.0
    pd_lab.b_range = pd_range
    pd_lab.a_range.min.should eq(-1.0)
    pd_lab.a_range.max.should eq(2.0)
    pd_lab.b_range.min.should eq(3.0)
    pd_lab.b_range.max.should eq(4.0)

    tristimulus = Pdfbox::Pdmodel::Graphics::Color::PDTristimulus.new
    tristimulus.x = 5.0
    tristimulus.y = 6.0
    tristimulus.z = 7.0
    pd_lab.whitepoint = tristimulus
    tristimulus = Pdfbox::Pdmodel::Graphics::Color::PDTristimulus.new
    tristimulus.x = 8.0
    tristimulus.y = 9.0
    tristimulus.z = 10.0
    pd_lab.blackpoint = tristimulus

    pd_lab.whitepoint.x.should eq(5.0)
    pd_lab.whitepoint.y.should eq(6.0)
    pd_lab.whitepoint.z.should eq(7.0)
    pd_lab.blackpoint.x.should eq(8.0)
    pd_lab.blackpoint.y.should eq(9.0)
    pd_lab.blackpoint.z.should eq(10.0)
    pd_lab.initial_color.components.should eq([0.0_f32, 0.0_f32, 3.0_f32])
  end
end
