require "../../../spec_helper"

module Pdfbox::Pdmodel
  describe "FDFAnnotationTest" do
    it "loadXFDFAnnotations" do
      path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/fdf/xfdf-test-document-annotations.xml")
      fdf_doc = Pdfbox::Loader.load_xfdf(path)
      begin
        fdf_annots = fdf_doc.catalog.fdf.annotations
        fdf_annots.should_not be_nil
        annots = fdf_annots.as(Array(Pdfbox::Pdmodel::Fdf::FDFAnnotation))
        annots.size.should eq 18

        tested = false
        annots.each do |ann|
          if ann.is_a?(Pdfbox::Pdmodel::Fdf::FDFAnnotationFreeText)
            annotation_free_text = ann.as(Pdfbox::Pdmodel::Fdf::FDFAnnotationFreeText)
            if annotation_free_text.contents == "P&1 P&2 P&3"
              tested = true
              expected_rich =
                "<body style=\"font:12pt Helvetica; " \
                "color:#D66C00;\" xfa:APIVersion=\"Acrobat:7.0.8\" " \
                "xfa:spec=\"2.0.2\" xmlns=\"http://www.w3.org/1999/xhtml\" " \
                "xmlns:xfa=\"http://www.xfa.org/schema/xfa-data/1.0/\">\n" \
                "          <p dir=\"ltr\">P&amp;1 <span style=\"text-" \
                "decoration:word;font-family:Helvetica\">P&amp;2</span> " \
                "P&amp;3</p>\n" \
                "        </body>"
              annotation_free_text.rich_contents.to_s.strip.should eq(expected_rich)
            end
          end
        end
        tested.should be_true
      ensure
        fdf_doc.close
      end
    end

    it "testAnnotationWidth" do
      xfdf =
        "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" \
        "<xfdf xmlns=\"http://ns.adobe.com/xfdf/\" xml:space=\"preserve\">" \
        "<annots>" \
        "<freetext" \
        " width=\"0.00\"" \
        " justification=\"left\" page=\"0\"" \
        " date=\"D:20251124141013+01'00'\"" \
        " flags=\"print\"" \
        " name=\"b525be7e-4735-4598-ab7f-163cd0c7e48b\"" \
        " rect=\"372.339325,722.633545,531.075317,736.673523\"" \
        " title=\"Username\"" \
        " BBox=\"372.339325,722.633545,531.075317,736.673523\"" \
        " Matrix=\"1.000000,0.000000,0.000000,1.000000,0.000000,0.000000\"" \
        " creationdate=\"D:20251124141003+01'00'\"" \
        " opacity=\"1\"" \
        " subject=\"Texteingabe\"" \
        " intent=\"FreeTextTypewriter\"" \
        " IT=\"FreeTextTypewriter\">" \
        "<defaultappearance>&#x20;/Helv 12 Tf 0.415686 0.756863 0.690196 rg</defaultappearance>" \
        "<defaultstyle>font: &apos;Helvetica&apos; ,sans-serif 12.00pt;color:#3049D1</defaultstyle>" \
        "<contents>Your text is here.</contents>" \
        "</freetext>" \
        "</annots>" \
        "<f href=\".xfdf\"/>" \
        "</xfdf>"

      input_stream = ::IO::Memory.new(xfdf.to_slice)

      fdf_doc = Pdfbox::Loader.load_xfdf(input_stream)
      begin
        fdf_annots = fdf_doc.catalog.fdf.annotations
        fdf_annots.should_not be_nil
        annots = fdf_annots.as(Array(Pdfbox::Pdmodel::Fdf::FDFAnnotation))
        annots.size.should eq 1

        annot = annots[0]
        annot.border_style.should_not be_nil
        annot.border_style.not_nil!.width.should be_close(0.0_f64, 0.01_f64)
      ensure
        fdf_doc.close
      end
    end
  end
end
