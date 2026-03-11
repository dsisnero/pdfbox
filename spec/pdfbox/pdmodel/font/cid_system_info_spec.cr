require "../../../spec_helper"
require "../../../../src/pdfbox/pdmodel/font/cid_system_info"

describe Pdfbox::Pdmodel::Font::PDCIDSystemInfo do
  it "builds dictionary fields from registry, ordering, and supplement" do
    info = Pdfbox::Pdmodel::Font::PDCIDSystemInfo.new("Adobe", "Identity", 0)
    dict = info.cos_object

    dict[Pdfbox::Cos::Name::REGISTRY].should be_a(Pdfbox::Cos::String)
    dict[Pdfbox::Cos::Name::ORDERING].should be_a(Pdfbox::Cos::String)
    dict[Pdfbox::Cos::Name::SUPPLEMENT].should be_a(Pdfbox::Cos::Integer)

    info.registry.should eq("Adobe")
    info.ordering.should eq("Identity")
    info.supplement.should eq(0)
  end

  it "reads values from an existing dictionary" do
    dict = Pdfbox::Cos::Dictionary.new
    dict.set_string(Pdfbox::Cos::Name::REGISTRY, "Adobe")
    dict.set_string(Pdfbox::Cos::Name::ORDERING, "GB1")
    dict.set_int(Pdfbox::Cos::Name::SUPPLEMENT, 5)

    info = Pdfbox::Pdmodel::Font::PDCIDSystemInfo.new(dict)
    info.registry.should eq("Adobe")
    info.ordering.should eq("GB1")
    info.supplement.should eq(5)
    info.to_s.should eq("Adobe-GB1-5")
  end
end
