require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Common::Filespecification::PDEmbeddedFile do
  klass = Pdfbox::Pdmodel::Common::Filespecification::PDEmbeddedFile
  describe "initialize" do
    it "sets TYPE to EmbeddedFile" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.cos_object[Pdfbox::Cos::Name::TYPE].as?(Pdfbox::Cos::Name).try(&.value).should eq "EmbeddedFile"
    end
  end

  describe "#subtype" do
    it "returns nil when not set" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.subtype.should be_nil
    end

    it "returns set subtype" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.subtype = "application/pdf"
      embedded.subtype.should eq "application/pdf"
    end
  end

  describe "#size" do
    it "returns 0 when not set" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.size.should eq 0
    end

    it "returns set size" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.size = 12345
      embedded.size.should eq 12345
    end
  end

  describe "#creation_date" do
    it "returns nil when not set" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.creation_date.should be_nil
    end

    it "returns set creation date" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      time = Time.utc(2025, 1, 15, 10, 30, 0)
      embedded.creation_date = time
      embedded.creation_date.not_nil!.to_s("%Y%m%d%H%M%S").should eq time.to_s("%Y%m%d%H%M%S")
    end
  end

  describe "#mod_date" do
    it "returns nil when not set" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mod_date.should be_nil
    end

    it "returns set mod date" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      time = Time.utc(2025, 2, 20, 14, 45, 0)
      embedded.mod_date = time
      embedded.mod_date.not_nil!.should eq time
    end
  end

  describe "#check_sum" do
    it "returns nil when not set" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.check_sum.should be_nil
    end

    it "returns set check sum" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.check_sum = "abcd1234"
      embedded.check_sum.should eq "abcd1234"
    end
  end

  describe "#mac_subtype" do
    it "returns nil when params not present" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_subtype.should be_nil
    end

    it "returns set mac subtype" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_subtype = "mac subtype value"
      embedded.mac_subtype.should eq "mac subtype value"
    end
  end

  describe "#mac_creator" do
    it "returns nil when params not present" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_creator.should be_nil
    end

    it "returns set mac creator" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_creator = "CREA"
      embedded.mac_creator.should eq "CREA"
    end
  end

  describe "#mac_res_fork" do
    it "returns nil when params not present" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_res_fork.should be_nil
    end

    it "returns set mac res fork" do
      stream = Pdfbox::Cos::Stream.new
      embedded = klass.new(stream)
      embedded.mac_res_fork = "fork data"
      embedded.mac_res_fork.should eq "fork data"
    end
  end
end
