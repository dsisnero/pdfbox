# Port of org.apache.pdfbox.pdmodel.graphics.optionalcontent.TestOptionalContentGroups
# (model-level generation tests: testOCGGeneration, testOCGsWithSameNameCanHaveDifferentVisibility,
# testOCGGenerationSameNameCanHaveSameVisibilityOff)
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties do
  it "testOCGGeneration - add groups and toggle enabled state" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new

    background = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("background")
    ocprops.add_group(background)
    ocprops.group_enabled?("background").should be_true

    enabled = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("enabled")
    ocprops.add_group(enabled)
    ocprops.set_group_enabled("enabled", true).should be_false
    ocprops.group_enabled?("enabled").should be_true

    disabled = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("disabled")
    ocprops.add_group(disabled)
    ocprops.set_group_enabled("disabled", true).should be_false
    ocprops.group_enabled?("disabled").should be_true
    ocprops.set_group_enabled("disabled", false).should be_true
    ocprops.group_enabled?("disabled").should be_false
  end

  it "testOCGsWithSameNameCanHaveDifferentVisibility" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new

    visible = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("layer")
    ocprops.add_group(visible)
    ocprops.group_enabled?(visible).should be_true

    invisible = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("layer")
    ocprops.add_group(invisible)
    ocprops.set_group_enabled(invisible, false).should be_false
    ocprops.group_enabled?(invisible).should be_false

    ocprops.group_enabled?(visible).should be_true
  end

  it "testOCGGenerationSameNameCanHaveSameVisibilityOff (PDFBOX-4496 model part)" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new

    background = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("background")
    ocprops.add_group(background)
    ocprops.group_enabled?("background").should be_true

    enabled = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("science")
    ocprops.add_group(enabled)
    ocprops.set_group_enabled("science", true).should be_false
    ocprops.group_enabled?("science").should be_true

    disabled1 = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("alternative")
    ocprops.add_group(disabled1)

    disabled2 = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("alternative")
    ocprops.add_group(disabled2)

    ocprops.set_group_enabled("alternative", false).should be_false
    ocprops.group_enabled?("alternative").should be_false
  end

  it "base state defaults to ON and can be set" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new
    ocprops.base_state.should eq(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties::BaseState::On)

    ocprops.base_state = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties::BaseState::Off
    ocprops.base_state.should eq(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties::BaseState::Off)
  end

  it "group names and optional content groups collections" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new
    group = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup

    ocprops.add_group(group.new("background"))
    ocprops.add_group(group.new("enabled"))
    ocprops.add_group(group.new("disabled"))

    ocprops.group_names.should contain("background")
    ocprops.group_names.should contain("enabled")
    ocprops.group_names.should contain("disabled")
    ocprops.group_names.size.should eq(3)

    ocprops.has_group?("background").should be_true
    ocprops.has_group?("inexistent").should be_false

    ocprops.group("background").should_not be_nil
    ocprops.group("background").not_nil!.name.should eq("background")
    ocprops.group("inexistent").should be_nil

    groups = ocprops.optional_content_groups
    groups.size.should eq(3)
    groups.map(&.name).should contain("background")
    groups.map(&.name).should contain("enabled")
    groups.map(&.name).should contain("disabled")
  end

  it "group constructor validates /Type OCG" do
    group = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("background")
    group.name.should eq("background")

    dict = Pdfbox::Cos::Dictionary.new
    expect_raises(ArgumentError) do
      Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new(dict)
    end
  end

  it "setOCProperties bumps document version to 1.5 and getOCProperties round-trips" do
    doc = Pdfbox::Pdmodel::Document.new
    catalog = doc.document_catalog
    catalog.should_not be_nil

    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new
    group = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("background")
    ocprops.add_group(group)

    catalog.not_nil!.oc_properties = ocprops
    doc.version.should eq(1.5_f32)

    read_back = catalog.not_nil!.oc_properties
    read_back.should_not be_nil
    read_back.not_nil!.has_group?("background").should be_true
  end
end
