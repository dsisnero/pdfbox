require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "AlignmentTests.pdf"
private RESOURCE_DIR   = "spec/resources/pdfbox/pdmodel/interactive/form"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java
#   testFlatten / testFlattenWidgetNoRef / testFlattenSpecificFieldsOnly.
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormFlattenTest.java
#   flattenSingleField / flattenTestPDFBOX5254 / flattenTestPDFBOX5225 / testFlatten (PDFBOX-4788, PDFBOX-4955).
#
# Behavioral (non-rendering) assertions only. The Java rendering comparison
# (TestPDFToImage.doTestFile) is advisory (Chunk K render policy), as is the
# generation of expected PNG samples.
#
# Fixtures for the JIRA-based tests (PDFBOX-5254, PDFBOX-5225, and the
# parameterized testFlatten cases) are downloaded from the Java JIRA attachment
# URLs; SHA512 recorded in spec/resources/pdfbox/pdmodel/interactive/form/SHA512SUMS.

private def count_widgets(document : Pdfbox::Pdmodel::Document) : Int32
  count = 0
  document.pages.each do |page|
    page.annotations.each do |annot|
      count += 1 if annot.is_a?(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotationWidget)
    end
  end
  count
end

describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "PDAcroFormTest#testFlatten" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.flatten
      acro_form.not_nil!.get_field_tree.size.should eq(0)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testFlattenWidgetNoRef" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.not_nil!.get_field_tree.each do |field|
        field.widgets.each do |widget|
          widget.cos_object.delete(Pdfbox::Cos::Name.new("P"))
        end
      end
      acro_form.not_nil!.flatten

      # 36 non widget annotations shall not be flattened
      document.pages[0].annotations.size.should eq(36)

      acro_form.not_nil!.get_field_tree.size.should eq(0)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testFlattenSpecificFieldsOnly" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      num_fields_before = acro_form.not_nil!.get_field_tree.size
      num_widgets_before = count_widgets(document)

      fields_to_flatten = [
        acro_form.not_nil!.get_field("AlignLeft-Border_Small-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Medium-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Wide-Filled"),
        acro_form.not_nil!.get_field("AlignLeft-Border_Wide_Clipped-Filled"),
      ].compact

      acro_form.not_nil!.flatten(fields_to_flatten, true)
      num_fields_after = acro_form.not_nil!.get_field_tree.size
      num_widgets_after = count_widgets(document)

      num_fields_before.should eq(num_fields_after + fields_to_flatten.size)
      num_widgets_before.should eq(num_widgets_after + fields_to_flatten.size)
    ensure
      document.close
    end
  end

  it "PDAcroFormFlattenTest#flattenSingleField" do
    file = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form/MultilineFields.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil
      acro_form = acro_form.not_nil!

      num_fields_before = acro_form.fields.size

      field = acro_form.get_field("AlignLeft-Filled")
      field.should_not be_nil
      field.should be_a(Pdfbox::Pdmodel::Interactive::Form::PDTextField)

      to_be_flattened = [field.not_nil!]
      acro_form.flatten(to_be_flattened, false)

      num_fields_before.should eq(acro_form.fields.size + 1)
      acro_form.get_field("AlignLeft-Filled").should be_nil
    ensure
      document.close
    end
  end

  it "PDAcroFormFlattenTest#flattenTestPDFBOX5254" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/f1040sb test.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil
      acro_form.not_nil!.flatten
      acro_form.not_nil!.fields.should be_empty
      document.pages[0].annotations.size.should eq(72)
    ensure
      document.close
    end
  end

  it "PDAcroFormFlattenTest#flattenTestPDFBOX5225" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/SourceFailure.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil
      acro_form = acro_form.not_nil!

      list = [acro_form.get_field("VN_NAME").not_nil!]
      acro_form.flatten(list, false)

      acro_form.get_field_tree.size.should eq(76)
      document.pages[0].annotations.size.should eq(59)
    ensure
      document.close
    end
  end

  # Parameterized testFlatten cases that exercise the flatten-to-empty behavior
  # (fields removed) without rendering.
  it "PDAcroFormFlattenTest#testFlatten PDFBOX-4788 (non-widget annotations kept)" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-4788.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil
      acro_form.not_nil!.flatten
      acro_form.not_nil!.fields.should be_empty
      # 1 non-widget annotation per page is retained
      document.pages[0].annotations.size.should eq(1)
      document.pages[1].annotations.size.should eq(1)
    ensure
      document.close
    end
  end

  it "PDAcroFormFlattenTest#testFlatten PDFBOX-4955 (unused appearance forms)" do
    file = SpecPaths.resolve("#{RESOURCE_DIR}/PDFBOX-4955.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      acro_form.should_not be_nil
      acro_form.not_nil!.flatten
      acro_form.not_nil!.fields.should be_empty
    ensure
      document.close
    end
  end
end
