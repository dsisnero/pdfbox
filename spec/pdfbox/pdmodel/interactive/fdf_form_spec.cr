require "../../../spec_helper"
require "../../../../src/tools"

private def build_form_document : Pdfbox::Pdmodel::Document
  doc = Pdfbox::Pdmodel::Document.new
  form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
  doc.document_catalog.not_nil!.acro_form = form

  text_dict = Pdfbox::Cos::Dictionary.new
  text_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
  text_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("name")
  text_dict[Pdfbox::Cos::Name.new("Subtype")] = Pdfbox::Cos::Name.new("Widget")
  text_dict[Pdfbox::Cos::Name.new("F")] = Pdfbox::Cos::Integer.new(4)
  text_field = Pdfbox::Pdmodel::Interactive::Form::PDTextField.new(form, text_dict, nil)
  text_field.value = "Alice"
  text_field.field_flags = Pdfbox::Pdmodel::Interactive::Form::PDField::FLAG_REQUIRED
  form.add_field(text_field)

  choice_dict = Pdfbox::Cos::Dictionary.new
  choice_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Ch")
  choice_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("colors")
  choice_field = Pdfbox::Pdmodel::Interactive::Form::PDChoice.new(form, choice_dict, nil)
  choice_field.values = ["red", "blue"]
  form.add_field(choice_field)

  check_dict = Pdfbox::Cos::Dictionary.new
  check_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Btn")
  check_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("agree")
  check_field = Pdfbox::Pdmodel::Interactive::Form::PDCheckBox.new(form, check_dict, nil)
  check_field.value = "Yes"
  form.add_field(check_field)

  doc
end

describe "PDAcroForm FDF parity" do
  it "exports field values to xfdf and imports them back" do
    doc = build_form_document
    form = doc.document_catalog.not_nil!.acro_form.not_nil!
    field = form.get_field("name").as(Pdfbox::Pdmodel::Interactive::Form::PDField)

    fdf_field = Pdfbox::Pdmodel::Fdf::FDFField.new
    fdf_field.partial_field_name = "name"
    fdf_field.cos_value = Pdfbox::Cos::Stream.new(data: "Charlie".to_slice)
    fdf_field.field_flags = Pdfbox::Pdmodel::Interactive::Form::PDField::FLAG_READ_ONLY
    fdf_field.widget_field_flags = Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation::FLAG_PRINTED

    fdf = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    fdf.catalog.fdf.fields = [fdf_field]
    form.import_fdf(fdf)

    field.value_as_string.should eq("Charlie")
    field.field_flags.should eq(Pdfbox::Pdmodel::Interactive::Form::PDField::FLAG_READ_ONLY)
    field.widgets.first.flags.should eq(Pdfbox::Pdmodel::Interactive::Annotation::PDAnnotation::FLAG_PRINTED)
  end

  it "exports terminal field and widget flags into fdf" do
    doc = build_form_document
    form = doc.document_catalog.not_nil!.acro_form.not_nil!
    field = form.get_field("name").as(Pdfbox::Pdmodel::Interactive::Form::PDField)

    exported = form.export_fdf
    name_field = exported.catalog.fdf.fields.not_nil!.find! { |item| item.partial_field_name == "name" }

    name_field.field_flags.should eq(field.field_flags)
    name_field.widget_field_flags.should eq(field.widgets.first.flags)
  end

  it "imports non-terminal field values into the underlying dictionary before recursing into kids" do
    doc = Pdfbox::Pdmodel::Document.new
    form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(doc)
    doc.document_catalog.not_nil!.acro_form = form

    child_dict = Pdfbox::Cos::Dictionary.new
    child_dict[Pdfbox::Cos::Name.new("FT")] = Pdfbox::Cos::Name.new("Tx")
    child_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("child")

    parent_dict = Pdfbox::Cos::Dictionary.new
    parent_dict[Pdfbox::Cos::Name.new("T")] = Pdfbox::Cos::String.new("parent")
    kids = Pdfbox::Cos::Array.new
    kids.add(child_dict)
    parent_dict[Pdfbox::Cos::Name.new("Kids")] = kids

    parent = Pdfbox::Pdmodel::Interactive::Form::PDNonTerminalField.new(form, parent_dict, nil)
    form.add_field(parent)

    child_fdf = Pdfbox::Pdmodel::Fdf::FDFField.new("child")
    child_fdf.value = "nested"
    parent_fdf = Pdfbox::Pdmodel::Fdf::FDFField.new("parent")
    parent_fdf.cos_value = Pdfbox::Cos::String.new("group")
    parent_fdf.kids = [child_fdf]

    fdf = Pdfbox::Pdmodel::Fdf::FDFDocument.new
    fdf.catalog.fdf.fields = [parent_fdf]

    form.import_fdf(fdf)

    parent.cos_object[Pdfbox::Cos::Name.new("V")].as(Pdfbox::Cos::String).value.should eq("group")
    parent.children.first.value_as_string.should eq("nested")
  end

  it "raises on unsupported terminal field import COS types" do
    doc = build_form_document
    form = doc.document_catalog.not_nil!.acro_form.not_nil!
    field = form.get_field("name").as(Pdfbox::Pdmodel::Interactive::Form::PDField)

    fdf_field = Pdfbox::Pdmodel::Fdf::FDFField.new("name")
    fdf_field.cos_value = Pdfbox::Cos::Integer.new(7)

    expect_raises(IO::Error, /Error:Unknown type for field import/) do
      field.import_fdf(fdf_field)
    end
  end
end
