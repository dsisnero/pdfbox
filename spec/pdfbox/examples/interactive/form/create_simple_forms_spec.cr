require "../../../../spec_helper"

describe "Examples::Interactive::Form::CreateSimpleForms parity" do
  it "creates a simple form with text field and verifies value serialization" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    if catalog = doc.document_catalog
      catalog.acro_form = acro_form
    end

    # Create a text field with widget
    text_dict = Pdfbox::Cos::Dictionary.new
    text_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
    text_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("SampleField")
    text_dict[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("Widget")
    text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(acro_form, text_dict, nil)
    acro_form.add_field(text_field)

    # Set and verify value
    text_field.value = "Sample field content"
    text_field.value_as_string.should eq("Sample field content")

    # Verify widget exists
    widgets = text_field.widgets
    widgets.should_not be_empty

    # Save and verify roundtrip
    output = ::IO::Memory.new
    doc.save(output)
    reloaded = Pdfbox::Pdmodel::Document.load(::IO::Memory.new(output.to_slice))

    reloaded_form = reloaded.document_catalog.not_nil!.acro_form
    reloaded_form.should_not be_nil
    reloaded_field = reloaded_form.not_nil!.get_field("SampleField")
    reloaded_field.should_not be_nil
    reloaded_field.as(Pdfbox::Pdmodel::Interactive::Form::PDField).value_as_string.should eq("Sample field content")

    doc.close
    reloaded.close
  end

  it "handles checkbox field creation and value" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    if catalog = doc.document_catalog
      catalog.acro_form = acro_form
    end

    check_dict = Pdfbox::Cos::Dictionary.new
    check_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Btn")
    check_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("CheckBox1")
    check_field = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(acro_form, check_dict, nil)
    acro_form.add_field(check_field)

    # Checkbox value
    check_field.value = "Yes"
    check_field.value_as_string.should eq("Yes")

    check_field.value = "Off"
    check_field.value_as_string.should eq("Off")

    doc.close
  end

  it "handles list box field creation and value" do
    doc = Pdfbox::Pdmodel::Document.new
    page = Pdfbox::Pdmodel::Page.new
    doc.add_page(page)

    acro_form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    if catalog = doc.document_catalog
      catalog.acro_form = acro_form
    end

    list_dict = Pdfbox::Cos::Dictionary.new
    list_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Ch")
    list_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("ListBox1")

    # Add options
    opts = Pdfbox::Cos::Array.new
    opts << Pdfbox::Cos::String.new("Option1")
    opts << Pdfbox::Cos::String.new("Option2")
    opts << Pdfbox::Cos::String.new("Option3")
    list_dict[Pdfbox::Cos::Name.new("Opt")] = opts

    list_field = Pdfbox::Pdmodel::Interactive::Form::PDListBox.new(acro_form, list_dict, nil)
    acro_form.add_field(list_field)

    list_field.value = "Option2"
    list_field.value_as_string.should eq("Option2")

    doc.close
  end
end
