require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroForm.java
#
# Characterization spec: upstream has no dedicated test for the refresh/iterator/
# flag surface, so these assertions are inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDAcroForm do
    it "regenerates terminal field appearances (Java refreshAppearances)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        page = Page.new
        document.add_page(page)

        font = Font::PDType1Font.new(Font::Standard14Fonts::FontName::HELVETICA)
        resources = PDResources.new
        resources.put(Cos::Name.new("Helv"), font)

        acro = PDAcroForm.new(document)
        document.document_catalog.not_nil!.acro_form = acro
        acro.default_resources = resources
        acro.default_appearance = "/Helv 12 Tf 0 g"

        field = PDTextField.new(acro)
        field.partial_name = "SampleField"
        field.default_appearance = "/Helv 12 Tf 0 g"
        acro.add_field(field)

        widget = field.widgets[0]
        widget.rectangle = Common::PDRectangle.new(50.0_f32, 750.0_f32, 200.0_f32, 20.0_f32)
        widget.page = page
        page.annotations.add(widget)

        field.value = "Hello"
        widget.normal_appearance_stream.should_not be_nil

        # drop the generated appearance and regenerate via refresh_appearances
        widget.appearance = nil
        widget.normal_appearance_stream.should be_nil

        acro.refresh_appearances
        widget.normal_appearance_stream.should_not be_nil
      ensure
        document.close
      end
    end

    it "iterates the field tree (Java getFieldIterator)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        field = PDTextField.new(acro)
        field.partial_name = "OnlyField"
        acro.add_field(field)

        acro.field_iterator.to_a.map(&.partial_name).should eq(["OnlyField"])
      ensure
        document.close
      end
    end

    it "round-trips the signature flags (Java isSignaturesExist/IsAppendOnly + setters)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        acro.signatures_exist?.should be_false
        acro.append_only?.should be_false

        acro.signatures_exist = true
        acro.append_only = true
        acro.signatures_exist?.should be_true
        acro.append_only?.should be_true

        acro.signatures_exist = false
        acro.append_only = false
        acro.signatures_exist?.should be_false
        acro.append_only?.should be_false
      ensure
        document.close
      end
    end

    it "tracks the field-caching flag (Java setCacheFields/isCachingFields)" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro = PDAcroForm.new(document)
        acro.caching_fields?.should be_false
        acro.cache_fields = true
        acro.caching_fields?.should be_true
        acro.cache_fields = false
        acro.caching_fields?.should be_false
      ensure
        document.close
      end
    end
  end
end
