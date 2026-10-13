require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDMarkedContentReference.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDMarkedContentReference do
    it "has /Type /MCR and no page by default" do
      reference = PDMarkedContentReference.new
      reference.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq("MCR")
      reference.page.should be_nil
      reference.mcid.should eq(0)
    end

    it "round-trips the page (/Pg)" do
      reference = PDMarkedContentReference.new
      page_dict = Pdfbox::Cos::Dictionary.new
      page_dict[Pdfbox::Cos::Name.new("Type")] = Pdfbox::Cos::Name.new("Page")
      page = Pdfbox::Pdmodel::Page.new(page_dict)

      reference.page = page
      reference.page.not_nil!.cos_object.should be(page_dict)
      reference.cos_object.get_dictionary(Pdfbox::Cos::Name.new("Pg")).should be(page_dict)

      reference.page = nil
      reference.page.should be_nil
      reference.cos_object.get_dictionary(Pdfbox::Cos::Name.new("Pg")).should be_nil
    end

    it "formats as mcid=<n>" do
      reference = PDMarkedContentReference.new
      reference.to_s.should eq("mcid=0")
      reference.mcid = 5
      reference.to_s.should eq("mcid=5")
    end
  end
end
