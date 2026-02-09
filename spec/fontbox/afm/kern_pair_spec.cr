require "../../spec_helper"

describe Fontbox::AFM::KernPair do
  describe "#initialize" do
    it "sets first_kern_character, second_kern_character, x, y" do
      kp = Fontbox::AFM::KernPair.new("firstKernCharacter", "secondKernCharacter", 10.0_f32, 20.0_f32)
      kp.first_kern_character.should eq("firstKernCharacter")
      kp.second_kern_character.should eq("secondKernCharacter")
      kp.x.should eq(10.0_f32)
      kp.y.should eq(20.0_f32)
    end
  end
end