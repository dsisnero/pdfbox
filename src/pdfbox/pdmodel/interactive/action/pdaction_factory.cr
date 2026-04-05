module Pdfbox::Pdmodel::Interactive::Action
  module PDActionFactory
    def self.create_action(action : Cos::Dictionary?) : PDAction?
      return nil unless action

      case action[Cos::Name.new("S")]?.as?(Cos::Name).try(&.value)
      when PDActionJavaScript::SUB_TYPE
        PDActionJavaScript.new(action)
      when PDActionURI::SUB_TYPE
        PDActionURI.new(action)
      when PDActionNamed::SUB_TYPE
        PDActionNamed.new(action)
      when PDActionImportData::SUB_TYPE
        PDActionImportData.new(action)
      when PDActionEmbeddedGoTo::SUB_TYPE
        PDActionEmbeddedGoTo.new(action)
      when PDActionHide::SUB_TYPE
        PDActionHide.new(action)
      when PDActionSubmitForm::SUB_TYPE
        PDActionSubmitForm.new(action)
      when PDActionLaunch::SUB_TYPE
        PDActionLaunch.new(action)
      when PDActionGoTo::SUB_TYPE
        PDActionGoTo.new(action)
      when PDActionRemoteGoTo::SUB_TYPE
        PDActionRemoteGoTo.new(action)
      else
        PDAction.new(action)
      end
    end
  end
end
