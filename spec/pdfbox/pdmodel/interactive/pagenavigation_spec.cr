require "../../../spec_helper"
require "../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThread do
  it "stores thread info and first bead" do
    thread = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThread.new
    info = Pdfbox::Pdmodel::DocumentInformation.new
    info.title = "Article"

    bead = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead.new

    thread.thread_info = info
    thread.first_bead = bead

    thread.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq("Thread")
    thread.thread_info.as(Pdfbox::Pdmodel::DocumentInformation).title.should eq("Article")
    thread.first_bead.should be_a(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead)
    thread.first_bead.not_nil!.thread.not_nil!.cos_object.same?(thread.cos_object).should be_true
  end
end

describe Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead do
  it "initializes a circular bead list and appends new beads" do
    bead = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead.new
    appended = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead.new

    bead.next_bead.cos_object.same?(bead.cos_object).should be_true
    bead.previous_bead.cos_object.same?(bead.cos_object).should be_true

    bead.append_bead(appended)

    bead.next_bead.cos_object.same?(appended.cos_object).should be_true
    appended.previous_bead.cos_object.same?(bead.cos_object).should be_true
    appended.next_bead.cos_object.same?(bead.cos_object).should be_true
    bead.previous_bead.cos_object.same?(appended.cos_object).should be_true
  end

  it "stores page, rectangle, and thread references" do
    bead = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThreadBead.new
    thread = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDThread.new
    page = Pdfbox::Pdmodel::Page.new
    rectangle = Pdfbox::Pdmodel::Common::PDRectangle.new(10.0_f32, 20.0_f32, 30.0_f32, 40.0_f32)

    bead.thread = thread
    bead.page = page
    bead.rectangle = rectangle

    bead.thread.not_nil!.cos_object.same?(thread.cos_object).should be_true
    bead.page.not_nil!.cos_object.same?(page.cos_object).should be_true
    bead.rectangle.not_nil!.lower_left_x.should eq(10.0_f32)
    bead.rectangle.not_nil!.lower_left_y.should eq(20.0_f32)
    bead.rectangle.not_nil!.width.should eq(30.0_f32)
    bead.rectangle.not_nil!.height.should eq(40.0_f32)
  end
end
