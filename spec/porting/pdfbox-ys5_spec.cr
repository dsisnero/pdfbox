require "../spec_helper"

describe "Porting parity pdfbox-ys5" do
  # Source of truth:
  # vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/TestOptionalContentGroups.java
  it "supports enabling and disabling optional content groups by name and object" do
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

    ocprops.base_state.should eq(Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties::BaseState::On)
    names = ocprops.group_names
    names.size.should eq(3)
    names.includes?("background").should be_true

    found_background = ocprops.group("background")
    found_background.should_not be_nil
    found_background.try(&.name).should eq("background")
    ocprops.group("inexistent").should be_nil

    groups = ocprops.optional_content_groups
    groups.size.should eq(3)
    group_names = groups.compact_map(&.name)
    group_names.includes?("background").should be_true
    group_names.includes?("enabled").should be_true
    group_names.includes?("disabled").should be_true
  end

  it "allows same name groups with different visibility" do
    ocprops = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentProperties.new

    visible = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("layer")
    ocprops.add_group(visible)
    ocprops.group_enabled?(visible).should be_true

    invisible = Pdfbox::Pdmodel::Graphics::OptionalContent::PDOptionalContentGroup.new("layer")
    ocprops.add_group(invisible)
    ocprops.set_group_enabled(invisible, false).should be_false
    ocprops.group_enabled?(invisible).should be_false

    ocprops.group_enabled?(visible).should be_true
    ocprops.group_enabled?("layer").should be_true
  end
end
