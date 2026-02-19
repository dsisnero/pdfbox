require "../../spec_helper"

describe Pdfbox::Cos::Base do
  describe "#cos_object" do
    it "returns the underlying COS object itself" do
      obj = Pdfbox::Cos::Boolean::TRUE
      obj.cos_object.should be(obj)
    end
  end

  describe "#direct?" do
    it "supports toggling direct state" do
      obj = Pdfbox::Cos::Integer.get(0_i64)

      obj.direct = true
      obj.direct?.should be_true

      obj.direct = false
      obj.direct?.should be_false
    end
  end
end
