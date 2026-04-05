require "../../../spec_helper"
require "../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::PDViewerPreferences do
  it "defaults Java boolean and enum values" do
    prefs = Pdfbox::Pdmodel::Interactive::PDViewerPreferences.new

    prefs.hide_toolbar?.should be_false
    prefs.hide_menubar?.should be_false
    prefs.hide_window_ui?.should be_false
    prefs.fit_window?.should be_false
    prefs.center_window?.should be_false
    prefs.display_doc_title?.should be_false
    prefs.non_full_screen_page_mode.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::NON_FULL_SCREEN_PAGE_MODE::UseNone)
    prefs.reading_direction.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::READING_DIRECTION::L2R)
    prefs.view_area.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::CropBox)
    prefs.view_clip.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::CropBox)
    prefs.print_area.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::CropBox)
    prefs.print_clip.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::CropBox)
    prefs.duplex.should be_nil
    prefs.print_scaling.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::PRINT_SCALING::AppDefault)
  end

  it "reads and writes the supported viewer preference fields" do
    prefs = Pdfbox::Pdmodel::Interactive::PDViewerPreferences.new

    prefs.hide_toolbar = true
    prefs.hide_menubar = true
    prefs.hide_window_ui = true
    prefs.fit_window = true
    prefs.center_window = true
    prefs.display_doc_title = true
    prefs.non_full_screen_page_mode = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::NON_FULL_SCREEN_PAGE_MODE::UseThumbs
    prefs.reading_direction = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::READING_DIRECTION::R2L
    prefs.view_area = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::BleedBox
    prefs.view_clip = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::TrimBox
    prefs.print_area = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::ArtBox
    prefs.print_clip = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::MediaBox
    prefs.duplex = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::DuplexFlipLongEdge
    prefs.print_scaling = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::PRINT_SCALING::None

    clone = Pdfbox::Pdmodel::Interactive::PDViewerPreferences.new(prefs.cos_object)
    clone.hide_toolbar?.should be_true
    clone.hide_menubar?.should be_true
    clone.hide_window_ui?.should be_true
    clone.fit_window?.should be_true
    clone.center_window?.should be_true
    clone.display_doc_title?.should be_true
    clone.non_full_screen_page_mode.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::NON_FULL_SCREEN_PAGE_MODE::UseThumbs)
    clone.reading_direction.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::READING_DIRECTION::R2L)
    clone.view_area.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::BleedBox)
    clone.view_clip.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::TrimBox)
    clone.print_area.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::ArtBox)
    clone.print_clip.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::BOUNDARY::MediaBox)
    clone.duplex.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::DuplexFlipLongEdge)
    clone.print_scaling.should eq(Pdfbox::Pdmodel::Interactive::PDViewerPreferences::PRINT_SCALING::None)
  end

  it "clears duplex when set to nil" do
    prefs = Pdfbox::Pdmodel::Interactive::PDViewerPreferences.new
    prefs.duplex = Pdfbox::Pdmodel::Interactive::PDViewerPreferences::DUPLEX::Simplex
    prefs.duplex = nil

    prefs.duplex.should be_nil
    prefs.cos_object[Pdfbox::Cos::Name.new("Duplex")]?.should be_nil
  end
end
