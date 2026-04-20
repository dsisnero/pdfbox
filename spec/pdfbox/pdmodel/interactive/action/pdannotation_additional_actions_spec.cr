require "../../../../spec_helper"
require "../../../../../src/pdfbox"

describe Pdfbox::Pdmodel::Interactive::Action::PDAnnotationAdditionalActions do
  it "stores and resolves annotation event actions through the action factory" do
    actions = Pdfbox::Pdmodel::Interactive::Action::PDAnnotationAdditionalActions.new

    enter_action = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    enter_action.uri = "https://example.com/enter"

    exit_action = Pdfbox::Pdmodel::Interactive::Action::PDActionNamed.new
    exit_action.n = "NextPage"

    down_action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    down_action.action = "app.alert('down')"

    up_action = Pdfbox::Pdmodel::Interactive::Action::PDActionHide.new
    up_action.h = false

    focus_action = Pdfbox::Pdmodel::Interactive::Action::PDActionMovie.new
    blur_action = Pdfbox::Pdmodel::Interactive::Action::PDActionResetForm.new
    page_open_action = Pdfbox::Pdmodel::Interactive::Action::PDActionSound.new
    page_close_action = Pdfbox::Pdmodel::Interactive::Action::PDActionThread.new
    page_visible_action = Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm.new
    page_invisible_action = Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch.new

    actions.e = enter_action
    actions.x = exit_action
    actions.d = down_action
    actions.u = up_action
    actions.fo = focus_action
    actions.bl = blur_action
    actions.po = page_open_action
    actions.pc = page_close_action
    actions.pv = page_visible_action
    actions.pi = page_invisible_action

    actions.cos_object.should be_a(Pdfbox::Cos::Dictionary)
    actions.e.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionURI)
    actions.e.as(Pdfbox::Pdmodel::Interactive::Action::PDActionURI).uri.should eq("https://example.com/enter")
    actions.x.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed)
    actions.x.as(Pdfbox::Pdmodel::Interactive::Action::PDActionNamed).n.should eq("NextPage")
    actions.d.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript)
    actions.d.as(Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript).action.should eq("app.alert('down')")
    actions.u.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionHide)
    actions.u.as(Pdfbox::Pdmodel::Interactive::Action::PDActionHide).h.should be_false
    actions.fo.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionMovie)
    actions.bl.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionResetForm)
    actions.po.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionSound)
    actions.pc.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionThread)
    actions.pv.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionSubmitForm)
    actions.pi.should be_a(Pdfbox::Pdmodel::Interactive::Action::PDActionLaunch)
  end
end
