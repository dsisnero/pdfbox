require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Action::PDPageAdditionalActions do
  it "stores and resolves page event actions through the action factory" do
    actions = Pdfbox::Pdmodel::Interactive::Action::PDPageAdditionalActions.new

    open_action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    open_action.action = "app.alert('open')"

    close_action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    close_action.uri = "https://example.com/close"

    actions.o = open_action
    actions.c = close_action

    actions.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    actions.o.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    actions.o.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('open')")
    actions.c.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    actions.c.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/close")
  end
end
