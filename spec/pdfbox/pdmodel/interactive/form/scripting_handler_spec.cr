require "../../../../spec_helper"
require "../../../../../src/pdfbox"

private class TestScriptingHandler
  include Pdfbox::Pdmodel::Interactive::Form::ScriptingHandler

  def keyboard(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String
    "#{java_script_action.action}-#{value}"
  end

  def format(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String
    "#{java_script_action.action}:#{value}"
  end

  def validate(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : Bool
    !java_script_action.action.to_s.empty? && !value.empty?
  end

  def calculate(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String
    "#{value}=#{java_script_action.action}"
  end
end

describe Pdfbox::Pdmodel::Interactive::Form::ScriptingHandler do
  it "defines the Java scripting callbacks" do
    action = Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript.new
    action.action = "app.alert('x')"
    handler = TestScriptingHandler.new

    handler.keyboard(action, "12").should eq("app.alert('x')-12")
    handler.format(action, "12").should eq("app.alert('x'):12")
    handler.validate(action, "12").should be_true
    handler.calculate(action, "12").should eq("12=app.alert('x')")
  end
end
