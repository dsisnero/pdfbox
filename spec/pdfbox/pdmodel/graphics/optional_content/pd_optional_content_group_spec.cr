require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/optionalcontent/PDOptionalContentGroup.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/rendering/RenderDestination.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics::OptionalContent
  describe PDOptionalContentGroup do
    it "returns nil render state when there is no /Usage dictionary" do
      group = PDOptionalContentGroup.new("Layer")
      group.name.should eq("Layer")
      group.render_state(Pdfbox::Rendering::RenderDestination::VIEW).should be_nil
      group.render_state(Pdfbox::Rendering::RenderDestination::PRINT).should be_nil
    end

    it "reads the view/print render state and falls back to export" do
      dict = Pdfbox::Cos::Dictionary.new
      dict.set_name("Type", PDOptionalContentGroup::TYPE)
      usage = Pdfbox::Cos::Dictionary.new
      view = Pdfbox::Cos::Dictionary.new
      view.set_name("ViewState", "ON")
      usage.set_item("View", view)
      print = Pdfbox::Cos::Dictionary.new
      print.set_name("PrintState", "OFF")
      usage.set_item("Print", print)
      export = Pdfbox::Cos::Dictionary.new
      export.set_name("ExportState", "ON")
      usage.set_item("Export", export)
      dict.set_item("Usage", usage)

      group = PDOptionalContentGroup.new(dict)
      group.render_state(Pdfbox::Rendering::RenderDestination::VIEW).should eq(PDOptionalContentGroup::RenderState::ON)
      group.render_state(Pdfbox::Rendering::RenderDestination::PRINT).should eq(PDOptionalContentGroup::RenderState::OFF)
    end

    it "maps the render-state names" do
      PDOptionalContentGroup::RenderState.value_of("on").should eq(PDOptionalContentGroup::RenderState::ON)
      PDOptionalContentGroup::RenderState.value_of("OFF").should eq(PDOptionalContentGroup::RenderState::OFF)
      PDOptionalContentGroup::RenderState.value_of(nil).should be_nil
      expect_raises(ArgumentError) { PDOptionalContentGroup::RenderState.value_of("Maybe") }
    end
  end
end
