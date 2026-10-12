require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/documentinterchange/logicalstructure/PDObjectReference.java
#
# Characterization spec: upstream has no dedicated PDObjectReference test, so
# these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::DocumentInterchange::LogicalStructure
  describe PDObjectReference do
    it "defaults to /Type /OBJR" do
      reference = PDObjectReference.new
      reference.cos_object.get_name_as_string(Cos::Name.new("Type")).should eq("OBJR")
    end

    it "returns nil when /Obj is absent" do
      PDObjectReference.new.referenced_object.should be_nil
    end

    it "resolves an annotation /Obj" do
      link = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink.new
      reference = PDObjectReference.new
      reference.referenced_object = link

      resolved = reference.referenced_object
      resolved.should be_a(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationLink)
    end

    it "resolves a form-XObject /Obj" do
      form = Pdfbox::Pdmodel::Graphics::Form::PDFormXObject.new(Pdfbox::Cos::Stream.new)
      reference = PDObjectReference.new
      reference.referenced_object = form

      resolved = reference.referenced_object
      resolved.should be_a(Pdfbox::Pdmodel::Graphics::Form::PDFormXObject)
    end

    it "round-trips the page (/Pg)" do
      reference = PDObjectReference.new
      reference.page.should be_nil

      page = Pdfbox::Pdmodel::Page.new
      reference.page = page
      reference.page.should_not be_nil

      reference.page = nil
      reference.page.should be_nil
    end

    describe "PDStructureElement kid integration" do
      it "creates a PDObjectReference for an OBJR kid" do
        element = PDStructureElement.new("S", nil)
        kid_dict = Cos::Dictionary.new
        kid_dict.set_name(Cos::Name.new("Type"), "OBJR")
        element.cos_object[Cos::Name.new("K")] = kid_dict

        kids = element.kids
        kids.size.should eq(1)
        kids[0].should be_a(PDObjectReference)
      end

      it "appends a PDObjectReference kid" do
        element = PDStructureElement.new("S", nil)
        reference = PDObjectReference.new
        element.append_kid(reference)

        element.cos_object[Cos::Name.new("K")].should be(reference.cos_object)
        element.kids[0].should be_a(PDObjectReference)
      end
    end
  end
end
