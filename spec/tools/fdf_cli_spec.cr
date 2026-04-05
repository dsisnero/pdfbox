require "../spec_helper"
require "../../src/tools"
require "file_utils"

private def fdf_temp_dir : String
  dir = (SpecPaths::PROJECT_ROOT / "temp" / "fdf-cli-spec").to_s
  FileUtils.mkdir_p(dir)
  dir
end

private def build_form_pdf(path : String) : Nil
  doc = Pdfbox::Pdmodel::Document.new
  form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
  doc.document_catalog.not_nil!.acro_form = form

  text_dict = Pdfbox::Cos::Dictionary.new
  text_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
  text_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("name")
  field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(form, text_dict, nil)
  field.value = "Alice"
  form.add_field(field)

  doc.save(path)
  doc.close
end

describe "FDF/XFDF CLI parity" do
  it "exports xfdf from a pdf form" do
    pdf = File.join(fdf_temp_dir, "export.pdf")
    xfdf = File.join(fdf_temp_dir, "export.xfdf")
    build_form_pdf(pdf)

    code = Tools::ExportXFDF.new(IO::Memory.new, IO::Memory.new).call(["-i", pdf, "-o", xfdf])

    code.should eq(0)
    File.read(xfdf).should contain(%(<field name="name">))
    File.read(xfdf).should contain("<value>Alice</value>")
  end

  it "imports xfdf into a pdf form and marks need appearances" do
    pdf = File.join(fdf_temp_dir, "import.pdf")
    outfile = File.join(fdf_temp_dir, "import-out.pdf")
    xfdf = File.join(fdf_temp_dir, "import.xfdf")
    build_form_pdf(pdf)
    File.write(xfdf, <<-XML)
      <?xml version="1.0" encoding="UTF-8"?>
      <xfdf xmlns="http://ns.adobe.com/xfdf/" xml:space="preserve">
      <fields>
        <field name="name">
          <value>Bob</value>
        </field>
      </fields>
      </xfdf>
    XML

    code = Tools::ImportXFDF.new(IO::Memory.new, IO::Memory.new).call(["-i", pdf, "-o", outfile, "--data", xfdf])

    code.should eq(0)
    loaded = Pdfbox::Loader.load_pdf(outfile)
    form = loaded.document_catalog.not_nil!.acro_form.not_nil!
    form.get_field("name").not_nil!.value_as_string.should eq("Bob")
    form.need_appearances?.should be_true
    loaded.close
  end
end
