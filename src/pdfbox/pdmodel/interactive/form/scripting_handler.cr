module Pdfbox::Pdmodel::Interactive::Form
  module ScriptingHandler
    abstract def keyboard(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String

    abstract def format(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String

    abstract def validate(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : Bool

    abstract def calculate(java_script_action : Pdfbox::Pdmodel::Interactive::Action::PDActionJavaScript, value : String) : String
  end
end
