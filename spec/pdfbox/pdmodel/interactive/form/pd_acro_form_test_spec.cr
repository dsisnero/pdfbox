require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/PDAcroFormTest.java
describe Pdfbox::Pdmodel::Interactive::Form::PDAcroForm do
  it "PDAcroFormTest#testFieldsEntry" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form

      acro_form.fields.should_not be_nil
      acro_form.fields.size.should eq(0)

      acro_form.get_field("foo").should be_nil

      acro_form.cos_object.delete(Pdfbox::Cos::Name.new("Fields"))

      acro_form.fields.should_not be_nil
      acro_form.fields.size.should eq(0)

      acro_form.get_field("foo").should be_nil
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testAcroFormProperties" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form

      acro_form.default_appearance.should be_empty
      acro_form.default_appearance = "/Helv 0 Tf 0 g"
      acro_form.default_appearance.should eq("/Helv 0 Tf 0 g")
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testBadDA" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)

      acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form
      acro_form.default_resources = Pdfbox::Pdmodel::PDResources.new

      text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form)
      text_box.partial_name = "SampleField"

      # "tf" is a typo, should have been "Tf" and this results that no font is chosen
      text_box.default_appearance = "/Helv 0 tf 0 g"
      acro_form.add_field(text_box)

      widget = text_box.widgets[0]
      widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 200.0_f32, 20.0_f32)
      widget.page = page

      page.annotations.add(widget)

      expect_raises(ArgumentError) { text_box.value = "huhu" }
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testAcroFormDefaultFonts" do
    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)
      acro_form2 = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      document.document_catalog.not_nil!.acro_form = acro_form2

      default_resources = acro_form2.default_resources
      default_resources.should be_nil
      default_resources = Pdfbox::Pdmodel::PDResources.new
      acro_form2.default_resources = default_resources
      default_resources.get_font(Pdfbox::Cos::Name.new("Helv")).should be_nil
      default_resources.get_font(Pdfbox::Cos::Name.new("ZaDb")).should be_nil

      # getting AcroForm sets the two fonts
      acro_form2 = document.document_catalog.not_nil!.acro_form.not_nil!
      default_resources = acro_form2.default_resources.not_nil!
      default_resources.get_font(Pdfbox::Cos::Name.new("Helv")).should_not be_nil
      default_resources.get_font(Pdfbox::Cos::Name.new("ZaDb")).should_not be_nil

      # repeat with a new AcroForm (to delete AcroForm cache) and thus missing /DR
      document.document_catalog.not_nil!.acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)
      acro_form2 = document.document_catalog.not_nil!.acro_form.not_nil!
      default_resources = acro_form2.default_resources.not_nil!

      helv = default_resources.get_font(Pdfbox::Cos::Name.new("Helv"))
      zadb = default_resources.get_font(Pdfbox::Cos::Name.new("ZaDb"))
      helv.should_not be_nil
      zadb.should_not be_nil

      helv.should be_a(Pdfbox::Pdmodel::Font::PDType1Font)
      zadb.should be_a(Pdfbox::Pdmodel::Font::PDType1Font)
      helv.not_nil!.name.should eq(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA.to_s)
      zadb.not_nil!.name.should eq(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::ZAPF_DINGBATS.to_s)
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testDontAddMissingInformationOnDocumentLoad and #testAddMissingInformationOnAcroFormAccess" do
    tmp = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      tmp.add_page(page)

      new_acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(tmp)
      tmp.document_catalog.not_nil!.acro_form = new_acro_form

      text_box = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(new_acro_form)
      text_box.partial_name = "SampleField"
      new_acro_form.add_field(text_box)

      widget = text_box.widgets[0]
      widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 200.0_f32, 20.0_f32)
      widget.page = page

      page.annotations.add(widget)

      output = ::IO::Memory.new
      tmp.save(output)
      pdf_bytes = output.to_slice
    ensure
      tmp.close
    end

    pdf_document = Pdfbox::Loader.load_pdf(pdf_bytes)
    begin
      catalog_dictionary = pdf_document.document_catalog.not_nil!.cos_object
      acro_form_value = catalog_dictionary[Pdfbox::Cos::Name.new("AcroForm")]
      acro_form_value = acro_form_value.object if acro_form_value.is_a?(Pdfbox::Cos::Object)
      acro_form_dictionary = acro_form_value.as(Pdfbox::Cos::Dictionary)

      # low-level access must not generate missing entries
      acro_form_dictionary[Pdfbox::Cos::Name.new("DA")]?.should be_nil
      acro_form_dictionary[Pdfbox::Cos::Name.new("Resources")]?.should be_nil

      # PD-level access shall trigger the generation of missing information
      the_acro_form = pdf_document.document_catalog.not_nil!.acro_form.not_nil!
      the_acro_form.default_appearance.should eq("/Helv 0 Tf 0 g ")
      the_acro_form.default_resources.should_not be_nil
      the_acro_form.default_resources.not_nil!.get_font(Pdfbox::Cos::Name.new("Helv")).not_nil!.name.should eq("Helvetica")
      the_acro_form.default_resources.not_nil!.get_font(Pdfbox::Cos::Name.new("ZaDb")).not_nil!.name.should eq("ZapfDingbats")
    ensure
      pdf_document.close
    end
  end

  it "PDAcroFormTest#testPDFBox3347" do
    # Fixture downloaded from the Java JIRA attachment URL (SHA512 recorded).
    file = SpecPaths.resolve("spec/resources/pdfbox/pdmodel/interactive/form/PDFBOX-3347.pdf")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("Krematorier")
      field.should_not be_nil
      field = field.not_nil!

      set = Set(String).new
      field.widgets.each do |annot|
        appearance = annot.appearance
        normal = appearance.try(&.normal_appearance)
        normal.try(&.sub_dictionary.keys.each do |name|
          set.add(name.value) unless name == Pdfbox::Cos::Name.new("Off")
        end)
      end

      set.to_a.sort.should eq(["Nynäshamn", "Råcksta", "Silverdal", "Skogskrem", "St Botvid", "Storkällan"])
    ensure
      document.close
    end
  end

  it "PDAcroFormTest#testPDFBox5797" do
    # Sejda generated files have widget /DA entries; setting a value with the
    # 'Ş' character used to crash.
    pdf_path = SpecPaths.resolve(
      "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/annotation/PDFBOX-5797-SO79271803.pdf")
    ttf_path = SpecPaths.resolve(
      "vendor/pdfbox/pdfbox/src/main/resources/org/apache/pdfbox/resources/ttf/LiberationSans-Regular.ttf")

    document = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
      font = ::File.open(ttf_path) do |io|
        Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, io, false)
      end

      acro_form = document.document_catalog.not_nil!.acro_form.not_nil!
      resources = acro_form.default_resources.not_nil!
      font_name = resources.add(font).value
      default_appearance_string = "/#{font_name} 12 Tf 0 g"

      field = acro_form.get_field("Name").not_nil!
        .as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      field.default_appearance = default_appearance_string
      field.widgets[0].appearance = nil
      field.value = "ŞŞ"

      field.value.should eq("ŞŞ")
    ensure
      document.close
    end
  end
end
