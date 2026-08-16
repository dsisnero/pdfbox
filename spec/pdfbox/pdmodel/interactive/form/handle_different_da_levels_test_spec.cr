require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "DifferentDALevels.pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/HandleDifferentDALevelsTest.java
# The Java rendering comparison is advisory; the behavioral assertions check
# that each widget's generated appearance content stream contains the font
# setting from the applicable /DA string.
private def font_setting_from_da(default_appearance : String?) : String
  return "" unless default_appearance
  tf_index = default_appearance.rindex("Tf")
  return default_appearance unless tf_index
  default_appearance[0, tf_index + 2]
end

describe Pdfbox::Pdmodel::Interactive::Form::PDTextField do
  it "HandleDifferentDALevelsTest#checkSingleAnnotation and #checkSameLayout" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form

      single = acro_form.not_nil!.get_field("SingleAnnotation").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      single.value = "single annotation"
      single_font_setting = font_setting_from_da(single.default_appearance)

      single.widgets.each do |widget|
        content = String.new(widget.normal_appearance_stream.not_nil!.require_stream_object.create_input_stream.getb_to_end)
        content.index(single_font_setting).should_not be_nil
      end

      same_layout = acro_form.not_nil!.get_field("MultipeAnnotations-SameLayout").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      same_layout.value = "same layout"
      same_layout_font_setting = font_setting_from_da(same_layout.default_appearance)

      same_layout.widgets.each do |widget|
        content = String.new(widget.normal_appearance_stream.not_nil!.require_stream_object.create_input_stream.getb_to_end)
        content.index(same_layout_font_setting).should_not be_nil
      end
    ensure
      document.close
    end
  end

  it "HandleDifferentDALevelsTest#checkDifferentLayout" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("MultipleAnnotations-DifferentLayout").as(Pdfbox::Pdmodel::Interactive::Form::PDTextField)
      field.value = "different layout"

      field_font_setting = font_setting_from_da(field.default_appearance)

      field.widgets.each do |widget|
        widget_font_setting = widget.cos_object.get_string(Pdfbox::Cos::Name.new("DA"))
        font_setting = if widget_font_setting
                         font_setting_from_da(widget_font_setting)
                       else
                         field_font_setting
                       end
        content = String.new(widget.normal_appearance_stream.not_nil!.require_stream_object.create_input_stream.getb_to_end)
        content.index(font_setting).should_not be_nil
      end
    ensure
      document.close
    end
  end
end
