require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private ANNOTATION_DIR = "vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/form"
private NAME_OF_PDF    = "ControlCharacters.pdf"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/form/ControlCharacterTest.java
# PDFBOX-3461: value strings are normalized the same way Acrobat normalizes
# them, so the generated appearance strings match the acrobat-* reference
# fields (after trimming, as Acrobat adds trailing spaces where PDFBox doesn't).
private def strings_from_stream(field : Pdfbox::Pdmodel::Interactive::Form::PDField) : Array(String)
  widget = field.widgets[0]
  stream = widget.normal_appearance_stream
  return [] of String unless stream

  parser = Pdfbox::Pdfparser::PDFStreamParser.new(stream.not_nil!.require_stream_object.create_input_stream.getb_to_end)
  tokens = parser.parse
  tokens.compact_map do |token|
    token.as?(Pdfbox::Cos::String).try(&.value.strip)
  end
end

describe Pdfbox::Pdmodel::Interactive::Form::PDField do
  it "ControlCharacterTest#characterNUL" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("pdfbox-nul").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
      expect_raises(ArgumentError) { field.value = "NUL\0NUL" }
    ensure
      document.close
    end
  end

  it "ControlCharacterTest#characterTAB" do
    file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
    document = Pdfbox::Loader.load_pdf(file)
    begin
      acro_form = document.document_catalog.not_nil!.acro_form
      field = acro_form.not_nil!.get_field("pdfbox-tab").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
      field.value = "TAB\tTAB"

      strings_from_stream(field).each { |token| token.should eq("TAB") }
    ensure
      document.close
    end
  end

  {"space" => "SPACE SPACE", "cr" => "CR\rCR", "lf" => "LF\nLF", "crlf" => "CRLF\r\nCRLF",
   "lfcr" => "LFCR\n\rLFCR", "linebreak" => "linebreak\u2028linebreak",
   "paragraphbreak" => "paragraphbreak\u2029paragraphbreak"}.each do |name_suffix, value|
    it "ControlCharacterTest#testCharacter (#{name_suffix})" do
      file = SpecPaths.resolve("#{ANNOTATION_DIR}/#{NAME_OF_PDF}")
      document = Pdfbox::Loader.load_pdf(file)
      begin
        acro_form = document.document_catalog.not_nil!.acro_form
        field = acro_form.not_nil!.get_field("pdfbox-#{name_suffix}").as(Pdfbox::Pdmodel::Interactive::Form::PDField)
        field.value = value

        pdfbox_values = strings_from_stream(field)
        acrobat_values = strings_from_stream(acro_form.not_nil!.get_field("acrobat-#{name_suffix}").as(Pdfbox::Pdmodel::Interactive::Form::PDField))

        pdfbox_values.should eq(acrobat_values)
      ensure
        document.close
      end
    end
  end
end
