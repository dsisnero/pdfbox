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

# Ports of PDTransitionTest.java
describe Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition do
  it "creates a transition with default replace style" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq("Trans")
    transition.style.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionStyle::R.to_s)
  end

  it "creates a transition with a given style" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new(
      Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionStyle::Fade
    )
    transition.cos_object.get_name_as_string(Pdfbox::Cos::Name.new("Type")).should eq("Trans")
    transition.style.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionStyle::Fade.to_s)
  end

  it "returns default values for an empty dictionary" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new(Pdfbox::Cos::Dictionary.new)
    transition.style.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionStyle::R.to_s)
    transition.dimension.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDimension::H.to_s)
    transition.motion.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionMotion::I.to_s)
    transition.direction.should eq(Pdfbox::Cos::Integer::ZERO)
    transition.duration.should eq(1.0_f64)
    transition.fly_scale.should eq(1.0_f64)
    transition.fly_area_opaque?.should be_false
  end

  it "sets the dimension" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.dimension = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDimension::H
    transition.dimension.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDimension::H.to_s)
  end

  it "sets the motion" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.motion = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionMotion::O
    transition.motion.should eq(Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionMotion::O.to_s)
  end

  it "sets the duration" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.duration = 4.0_f64
    transition.duration.should eq(4.0_f64)
  end

  it "sets the fly scale" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.fly_scale = 4.0_f64
    transition.fly_scale.should eq(4.0_f64)
  end

  it "sets the fly area opacity" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.fly_area_opaque = true
    transition.fly_area_opaque?.should be_true
  end

  it "sets a direction of NONE as a COS name" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.direction = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::NONE
    transition.direction.should be_a(Pdfbox::Cos::Name)
    transition.direction.should eq(Pdfbox::Cos::Name.new("None"))
  end

  it "sets a numeric direction as a COS integer" do
    transition = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransition.new
    transition.direction = Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::LEFT_TO_RIGHT
    transition.direction.should be_a(Pdfbox::Cos::Integer)
    transition.direction.should eq(Pdfbox::Cos::Integer::ZERO)
  end
end

# Ports of PDTransitionDirectionTest.java
describe Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection do
  it "exposes the underlying COS base values" do
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::NONE.cos_base.should eq(Pdfbox::Cos::Name.new("None"))
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::LEFT_TO_RIGHT.cos_base.should eq(Pdfbox::Cos::Integer.get(0))
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::BOTTOM_TO_TOP.cos_base.should eq(Pdfbox::Cos::Integer.get(90))
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::RIGHT_TO_LEFT.cos_base.should eq(Pdfbox::Cos::Integer.get(180))
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::TOP_TO_BOTTOM.cos_base.should eq(Pdfbox::Cos::Integer.get(270))
    Pdfbox::Pdmodel::Interactive::Pagenavigation::PDTransitionDirection::TOP_LEFT_TO_BOTTOM_RIGHT.cos_base.should eq(Pdfbox::Cos::Integer.get(315))
  end
end
