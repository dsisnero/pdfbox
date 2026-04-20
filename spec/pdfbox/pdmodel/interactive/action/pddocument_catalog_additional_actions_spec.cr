require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Action::PDDocumentCatalogAdditionalActions do
  it "stores and resolves catalog event actions through the action factory" do
    actions = Pdfbox::Pdmodel::Interactive::Action::PDDocumentCatalogAdditionalActions.new

    will_close = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    will_close.action = "app.alert('wc')"

    will_save = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    will_save.uri = "https://example.com/ws"

    did_save = Pdfbox::Pdmodel::Interactive::Action::PDActionNamed.new
    did_save.n = "Print"

    will_print = Pdfbox::Pdmodel::Interactive::Action::PDActionMovie.new
    did_print = Pdfbox::Pdmodel::Interactive::Action::PDActionResetForm.new

    actions.wc = will_close
    actions.ws = will_save
    actions.ds = did_save
    actions.wp = will_print
    actions.dp = did_print

    actions.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    actions.wc.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    actions.wc.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('wc')")
    actions.ws.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    actions.ws.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/ws")
    actions.ds.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed)
    actions.ds.as(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed).n.should eq("Print")
    actions.wp.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionMovie)
    actions.dp.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionResetForm)
  end
end
