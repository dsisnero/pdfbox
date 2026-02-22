require "../../../spec_helper"

describe "PDAcroForm" do
  it "creates form from document" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    form.should be_a(Pdfbox::Pdmodel::Interactive::Form::PDAcroForm)
  end

  it "returns empty fields array" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    form.fields.should be_empty
  end

  it "checks need appearances flag" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    form.need_appearances?.should be_false
  end
end

describe "PDTextField" do
  it "creates text field" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(form, dict, nil)

    field.field_type.should eq("Tx")
    field.value_as_string.should eq("")
  end

  it "sets and gets value" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(form, dict, nil)

    field.value = "Test Value"
    field.value_as_string.should eq("Test Value")
  end

  it "checks multiline flag" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(form, dict, nil)

    field.multiline?.should be_false
  end
end

describe "PDCheckBox" do
  it "creates checkbox" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(form, dict, nil)

    field.field_type.should eq("Btn")
  end

  it "checks value" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(form, dict, nil)

    field.value = "Yes"
    field.value_as_string.should eq("Yes")
    field.checked?.should be_true
  end
end

describe "PDChoice" do
  it "creates choice field" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDChoice.new(form, dict, nil)

    field.field_type.should eq("Ch")
    field.options.should be_empty
  end

  it "sets options" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    dict = Pdfbox::Cos::Dictionary.new
    field = Pdfbox::Pdmodel::Interactive::Form::PDChoice.new(form, dict, nil)

    field.options = [{"Display1", "Export1"}, {"Display2", "Export2"}]
    field.options.size.should eq(2)
  end
end
