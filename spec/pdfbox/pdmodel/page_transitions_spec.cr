require "../../spec_helper"

describe "TestPDPageTransitions" do
  it "readTransitions" do
    pdf_path = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/interactive/pagenavigation/transitions_test.pdf")

    doc = Pdfbox::Loader.load_pdf(pdf_path)
    begin
      first_transition = doc.pages[0]?.try(&.transition)
      first_transition.should_not be_nil

      transition = first_transition.not_nil!
      transition.style.should eq("Glitter")
      transition.duration.should eq(2.0_f64)
      transition.direction.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::TOP_LEFT_TO_BOTTOM_RIGHT.cos_base)
    ensure
      doc.close
    end
  end

  it "saveAndReadTransitions" do
    baos = IO::Memory.new

    document = Pdfbox::Pdmodel::Document.new
    begin
      page = Pdfbox::Pdmodel::Page.new
      document.add_page(page)
      transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new(
        Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionStyle::Fly
      )
      transition.direction = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::NONE
      transition.fly_scale = 0.5_f64
      page.set_transition(transition, 2)
      document.save(baos)
    ensure
      document.close
    end

    loaded = Pdfbox::Loader.load_pdf(baos.to_slice)
    begin
      page = loaded.pages[0]
      loaded_transition = page.transition
      loaded_transition.should_not be_nil

      transition = loaded_transition.not_nil!
      transition.style.should eq("Fly")
      page.cos_object.not_nil!.get_float(Pdfbox::Cos::Name.new("Dur"), 0.0_f64).should eq(2.0_f64)
      transition.direction.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::NONE.cos_base)
    ensure
      loaded.close
    end
  end
end
