require "../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/fixup/PDDocumentFixup.java
#   .../fixup/AbstractFixup.java
#   .../fixup/AcroFormDefaultFixup.java
#   .../fixup/processor/{PDDocumentProcessor,AbstractProcessor,
#                        AcroFormDefaultsProcessor,AcroFormGenerateAppearancesProcessor}.java
#
# Java's fixup framework applies on AcroForm access: AcroFormDefaultFixup runs
# AcroFormDefaultsProcessor, then (when NeedAppearances is true) rebuilds orphan
# widget fields if /Fields is empty and generates the missing appearances.
# Upstream has no dedicated fixup test; this is the characterization spec.
private def fixup_document : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Interactive::Form::PDAcroForm}
  doc = Pdfbox::Pdmodel::Document.create
  doc.add_page(Pdfbox::Pdmodel::Page.new)
  form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
  doc.document_catalog.not_nil!.acro_form = form
  {doc, form}
end

private def raw_acro_form(doc : Pdfbox::Pdmodel::Document) : Pdfbox::Pdmodel::Interactive::Form::PDAcroForm
  doc.document_catalog.not_nil!.acro_form(nil).not_nil!
end

describe Pdfbox::Pdmodel::Fixup::AcroFormDefaultFixup do
  it "supplies the Adobe default appearance and default resources (AcroFormDefaultsProcessor)" do
    doc, form = fixup_document
    form.default_appearance.should eq("")
    form.default_resources.should be_nil

    Pdfbox::Pdmodel::Fixup::AcroFormDefaultFixup.new(doc).apply

    form = raw_acro_form(doc)
    form.default_appearance.should eq("/Helv 0 Tf 0 g ")
    resources = form.default_resources.not_nil!
    font_names = resources.font_names.map(&.value)
    font_names.should contain("Helv")
    font_names.should contain("ZaDb")
  ensure
    doc.try(&.close)
  end

  it "rebuilds orphan widgets and clears NeedAppearances (PDFBOX-4985)" do
    doc, form = fixup_document
    form.need_appearances = true

    Pdfbox::Pdmodel::Fixup::AcroFormDefaultFixup.new(doc).apply

    form = raw_acro_form(doc)
    form.need_appearances?.should be_false
  ensure
    doc.try(&.close)
  end

  it "applies the default fixup when the AcroForm is accessed (Java getAcroForm())" do
    doc, _form = fixup_document

    form = doc.document_catalog.not_nil!.acro_form.not_nil!
    form.default_appearance.should eq("/Helv 0 Tf 0 g ")
    form.default_resources.not_nil!.font_names.map(&.value).should contain("Helv")
  ensure
    doc.try(&.close)
  end

  it "PDDocumentProcessor#process is idempotent for the defaults" do
    doc, _form = fixup_document

    processor = Pdfbox::Pdmodel::Fixup::Processor::AcroFormDefaultsProcessor.new(doc)
    processor.process
    processor.process

    raw_acro_form(doc).default_resources.not_nil!.font_names.size.should eq(2)
  ensure
    doc.try(&.close)
  end

  it "PDDocumentFixup is an apply-able interface" do
    doc, _form = fixup_document
    fixup = Pdfbox::Pdmodel::Fixup::AcroFormDefaultFixup.new(doc)
    (fixup.is_a?(Pdfbox::Pdmodel::Fixup::PDDocumentFixup)).should be_true
  ensure
    doc.try(&.close)
  end
end
