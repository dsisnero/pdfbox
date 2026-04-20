require "../../spec_helper"

describe Pdfbox::Text::PDFTextStripperByArea do
  it "extracts eu-001 regions like the Java fixture" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/input/eu-001.pdf")

    doc = Pdfbox::Pdmodel::Document.load(pdf_path)
    begin
      region_name = "region"
      stripper = Pdfbox::Text::PDFTextStripperByArea.new
      stripper.should_separate_by_beads = false
      stripper.sort_by_position = true
      stripper.add_region(region_name, Fontbox::Util::Rectangle2D.new(65.0, 227.0, 472.0, 34.0))
      stripper.line_separator = ""

      page0 = doc.pages[0]
      page0.should_not be_nil
      stripper.extract_regions(page0)
      stripper.get_text_for_region(region_name).strip.should eq(
        "In the following tables you will find the 91 E-PRTR pollutants and their thresholds broken down by the 7 groups used in all the searches of the E-PRTR website."
      )

      stripper.remove_region(region_name)
      stripper.add_region(region_name, Fontbox::Util::Rectangle2D.new(230.0, 370.0, 369.0, 10.0))

      page2 = doc.pages[2]
      page2.should_not be_nil
      stripper.extract_regions(page2)
      stripper.get_text_for_region(region_name).strip.should eq("Inorganic substances")
      stripper.regions.size.should eq(1)
    ensure
      doc.close
    end
  end
end
