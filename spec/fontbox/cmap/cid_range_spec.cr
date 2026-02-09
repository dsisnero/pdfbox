require "../../spec_helper"

describe Fontbox::CMap::CIDRange do
  describe "#initialize" do
    it "creates a CIDRange with one byte code length" do
      cid_range = Fontbox::CMap::CIDRange.new(0, 20, 65, 1)
      cid_range.code_length.should eq 1
    end

    it "creates a CIDRange with two byte code length" do
      cid_range = Fontbox::CMap::CIDRange.new(256, 280, 65, 2)
      cid_range.code_length.should eq 2
    end
  end

  describe "#map with bytes" do
    it "maps one-byte codes to CID" do
      cid_range = Fontbox::CMap::CIDRange.new(0, 20, 65, 1)
      cid_range.map([0_u8]).should eq 65
      cid_range.map([10_u8]).should eq 75
      cid_range.map([30_u8]).should eq -1
      cid_range.map([0_u8, 10_u8]).should eq -1
    end

    it "maps two-byte codes to CID" do
      cid_range = Fontbox::CMap::CIDRange.new(256, 280, 65, 2)
      cid_range.map([1_u8, 0_u8]).should eq 65
      cid_range.map([1_u8, 10_u8]).should eq 75
      cid_range.map([1_u8, 30_u8]).should eq -1
      cid_range.map([10_u8]).should eq -1
    end
  end

  describe "#map with code and length" do
    it "maps one-byte integer codes to CID" do
      cid_range = Fontbox::CMap::CIDRange.new(0, 20, 65, 1)
      cid_range.map(0, 1).should eq 65
      cid_range.map(10, 1).should eq 75
      cid_range.map(30, 1).should eq -1
      cid_range.map(10, 2).should eq -1
    end

    it "maps two-byte integer codes to CID" do
      cid_range = Fontbox::CMap::CIDRange.new(256, 280, 65, 2)
      cid_range.map(256, 2).should eq 65
      cid_range.map(266, 2).should eq 75
      cid_range.map(290, 2).should eq -1
      cid_range.map(256, 1).should eq -1
    end
  end

  describe "#unmap" do
    it "unmaps CID to one-byte code" do
      cid_range = Fontbox::CMap::CIDRange.new(0, 20, 65, 1)
      cid_range.unmap(65).should eq 0
      cid_range.unmap(75).should eq 10
      cid_range.unmap(100).should eq -1
    end

    it "unmaps CID to two-byte code" do
      cid_range = Fontbox::CMap::CIDRange.new(256, 280, 65, 2)
      cid_range.unmap(65).should eq 256
      cid_range.unmap(75).should eq 266
      cid_range.unmap(100).should eq -1
    end
  end
end