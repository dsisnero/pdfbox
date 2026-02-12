require "../../spec_helper"

module Fontbox::CFF
  describe "CFFEncoding" do
    it "test CFFExpertEncoding" do
      cff_expert_encoding = ExpertEncoding.instance
      # check some randomly chosen mappings
      cff_expert_encoding.name(0).should eq ".notdef"
      cff_expert_encoding.name(32).should eq "space"
      cff_expert_encoding.name(112).should eq "Psmall"
      cff_expert_encoding.name(251).should eq "Ucircumflexsmall"
      cff_expert_encoding.code("space").should eq 32
      cff_expert_encoding.code("Psmall").should eq 112
      cff_expert_encoding.code("Ucircumflexsmall").should eq 251
    end

    it "test CFFStandardEncoding" do
      cff_standard_encoding = StandardEncoding.instance
      # check some randomly chosen mappings
      cff_standard_encoding.name(0).should eq ".notdef"
      cff_standard_encoding.name(32).should eq "space"
      cff_standard_encoding.name(112).should eq "p"
      cff_standard_encoding.name(251).should eq "germandbls"
      cff_standard_encoding.code("space").should eq 32
      cff_standard_encoding.code("p").should eq 112
      cff_standard_encoding.code("germandbls").should eq 251
    end
  end
end
