require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/TestListBox.java
private def build_choice_field : {Pdfbox::Pdmodel::Document, Pdfbox::Pdmodel::Interactive::Form::PDListBox}
  document = Pdfbox::Pdmodel::Document.new
  page = Pdfbox::Pdmodel::Page.new
  document.add_page(page)
  form = Pdfbox::Pdmodel::Interactive::Form::PDAcroForm.new(document)

  font = Pdfbox::Pdmodel::Font::PDType1Font.new(Pdfbox::Pdmodel::Font::Standard14Fonts::FontName::HELVETICA)
  resources = Pdfbox::Pdmodel::PDResources.new
  resources.put(Pdfbox::Cos::Name.new("Helv"), font)
  form.default_resources = resources
  form.default_appearance = "/Helv 0 Tf 0 g"

  choice = Pdfbox::Pdmodel::Interactive::Form::PDListBox.new(form)
  choice.default_appearance = "/Helv 12 Tf 0g"

  widget = choice.widgets[0]
  widget.rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(50.0_f32, 750.0_f32, 200.0_f32, 50.0_f32)
  widget.page = page
  page.annotations.add(widget)

  {document, choice}
end

describe Pdfbox::Pdmodel::Interactive::Form::PDListBox do
  it "TestListBox#testNoNullsReturned" do
    document, choice = build_choice_field
    begin
      choice.get_options.should_not be_nil
      choice.value.should_not be_nil
    ensure
      document.close
    end
  end

  it "TestListBox#testExportValuesGetterSetter" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]

      choice.set_options(export_values)
      choice.get_options_display_values.should eq(export_values)
      choice.get_options_export_values.should eq(export_values)

      choice.top_index = 1
      choice.value = export_values[2]
      choice.value[0].should eq(export_values[2])
      choice.top_index = nil

      opt_item = choice.cos_object[Pdfbox::Cos::Name.new("Opt")]?.as(Pdfbox::Cos::Array)
      choice.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should_not be_nil
      opt_item.size.should eq(export_values.size)
      opt_item.get_string(0).should eq(export_values[0])

      retrieved_options = choice.get_options
      retrieved_options.size.should eq(export_values.size)
      retrieved_options.should eq(export_values)
    ensure
      document.close
    end
  end

  it "TestListBox#testFieldValueSetterGetter" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]

      choice.set_options(export_values)
      choice.multi_select = true
      choice.set_values(export_values)

      value_items = choice.cos_object[Pdfbox::Cos::Name.new("V")]?.as(Pdfbox::Cos::Array)
      value_items.size.should eq(export_values.size)
      value_items.get_string(0).should eq(export_values[0])

      index_items = choice.cos_object[Pdfbox::Cos::Name.new("I")]?.as(Pdfbox::Cos::Array)
      index_items.size.should eq(export_values.size)

      choice.value = "export01"
      choice.cos_object[Pdfbox::Cos::Name.new("I")]?.should be_nil
    ensure
      document.close
    end
  end

  it "TestListBox#testMultiselect" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]
      choice.set_options(export_values)

      choice.multi_select = false

      exception = expect_raises(ArgumentError, /The list box does not allow multiple selections./) do
        choice.set_values(export_values)
      end

      choice.multi_select = true
      choice.set_values(export_values)
    ensure
      document.close
    end
  end

  it "TestListBox#testOptIsRemovedForNull" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]
      choice.set_options(export_values)
      choice.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should_not be_nil
      choice.set_options(nil)
      choice.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should be_nil
      choice.get_options.should be_empty
    ensure
      document.close
    end
  end

  it "TestListBox#testSetExportAndDisplay" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]
      display_values = ["display02", "display01", "display03"]

      choice.set_options(export_values, display_values)
      choice.get_options_display_values.should eq(display_values)
      choice.get_options_export_values.should eq(export_values)
    ensure
      document.close
    end
  end

  it "TestListBox#testSortOption" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]
      display_values = ["display02", "display01", "display03"]

      choice.set_options(export_values, display_values)
      choice.get_options_display_values[0].should eq("display02")

      choice.sort = true
      choice.set_options(export_values, display_values)
      choice.get_options_display_values[0].should eq("display01")
      choice.get_options_display_values[1].should eq("display02")
      choice.get_options_display_values[2].should eq("display03")
    ensure
      document.close
    end
  end

  it "TestListBox#testEmptyOptionsNotNull" do
    document, choice = build_choice_field
    begin
      display_values = ["display02", "display01", "display03"]
      choice.set_options(nil, display_values)
      choice.cos_object[Pdfbox::Cos::Name.new("Opt")]?.should be_nil

      choice.get_options.should be_empty
      choice.get_options_display_values.should be_empty
      choice.get_options_export_values.should be_empty
    ensure
      document.close
    end
  end

  it "TestListBox#testExceptionForDifferentNumberOfEntries" do
    document, choice = build_choice_field
    begin
      export_values = ["export01", "export02", "export03"]
      display_values = ["display02", "display01", "display03"]
      export_values = export_values[0, 2]

      expect_raises(ArgumentError, /The number of entries for exportValue and displayValue shall be the same./) do
        choice.set_options(export_values, display_values)
      end
    ensure
      document.close
    end
  end
end
