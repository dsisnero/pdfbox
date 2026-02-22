require "../../../spec_helper"

describe Pdfbox::Pdmodel::Common::PDRectangle do
  it "creates default rectangle with 0,0,0,0" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new
    rect.lower_left_x.should eq(0.0_f32)
    rect.lower_left_y.should eq(0.0_f32)
    rect.upper_right_x.should eq(0.0_f32)
    rect.upper_right_y.should eq(0.0_f32)
  end

  it "creates rectangle with specific coordinates" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 100.0_f32, 200.0_f32)
    rect.lower_left_x.should eq(10.0_f32)
    rect.lower_left_y.should eq(20.0_f32)
    rect.upper_right_x.should eq(100.0_f32)
    rect.upper_right_y.should eq(200.0_f32)
  end

  it "calculates width and height" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 100.0_f32, 200.0_f32)
    rect.width.should eq(90.0_f32)
    rect.height.should eq(180.0_f32)
  end

  it "allows setting coordinates" do
    rect = Pdfbox::Pdmodel::Common::PDRectangle.new
    rect.lower_left_x = 10.0_f32
    rect.lower_left_y = 20.0_f32
    rect.upper_right_x = 100.0_f32
    rect.upper_right_y = 200.0_f32

    rect.lower_left_x.should eq(10.0_f32)
    rect.lower_left_y.should eq(20.0_f32)
    rect.upper_right_x.should eq(100.0_f32)
    rect.upper_right_y.should eq(200.0_f32)
  end

  it "provides standard page sizes" do
    letter = Pdfbox::Pdmodel::Common::PDRectangle.letter
    letter.width.should eq(8.5_f32 * 72.0_f32)
    letter.height.should eq(11.0_f32 * 72.0_f32)

    a4 = Pdfbox::Pdmodel::Common::PDRectangle.a4
    a4.width.should be_close(210.0_f32 * (1.0_f32 / (10.0_f32 * 2.54_f32) * 72.0_f32), 0.1_f32)
    a4.height.should be_close(297.0_f32 * (1.0_f32 / (10.0_f32 * 2.54_f32) * 72.0_f32), 0.1_f32)
  end
end

describe Pdfbox::Pdmodel::Common::PDImmutableRectangle do
  it "creates immutable rectangle" do
    rect = Pdfbox::Pdmodel::Common::PDImmutableRectangle.new(100.0_f32, 200.0_f32)
    rect.width.should eq(100.0_f32)
    rect.height.should eq(200.0_f32)
  end

  it "raises error when trying to modify" do
    rect = Pdfbox::Pdmodel::Common::PDImmutableRectangle.new(100.0_f32, 200.0_f32)

    expect_raises(Exception) do
      rect.lower_left_x = 10.0_f32
    end

    expect_raises(Exception) do
      rect.upper_right_x = 10.0_f32
    end
  end
end
