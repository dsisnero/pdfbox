require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Action::PDFormFieldAdditionalActions do
  it "stores and resolves form-field event actions through the action factory" do
    actions = Pdfbox::Pdmodel::Interactive::Action::PDFormFieldAdditionalActions.new

    keystroke = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    keystroke.action = "app.alert('k')"

    format_action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    format_action.uri = "https://example.com/f"

    validate = Pdfbox::Pdmodel::Interactive::Action::PDActionNamed.new
    validate.n = "PrevPage"

    calculate = Pdfbox::Pdmodel::Interactive::Action::PDActionMovie.new

    actions.k = keystroke
    actions.f = format_action
    actions.v = validate
    actions.c = calculate

    actions.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    actions.k.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    actions.k.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('k')")
    actions.f.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    actions.f.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/f")
    actions.v.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed)
    actions.v.as(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed).n.should eq("PrevPage")
    actions.c.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionMovie)
  end
end
