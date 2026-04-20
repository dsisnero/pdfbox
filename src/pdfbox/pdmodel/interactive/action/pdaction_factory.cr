module Pdfbox::Pdmodel::Interactive::Action
  module PDActionFactory
    BUILDERS = {
      PDActionJavaScript::SUB_TYPE   => ->(dict : Cos::Dictionary) { PDActionJavaScript.new(dict).as(PDAction) },
      PDActionURI::SUB_TYPE          => ->(dict : Cos::Dictionary) { PDActionURI.new(dict).as(PDAction) },
      PDActionNamed::SUB_TYPE        => ->(dict : Cos::Dictionary) { PDActionNamed.new(dict).as(PDAction) },
      PDActionImportData::SUB_TYPE   => ->(dict : Cos::Dictionary) { PDActionImportData.new(dict).as(PDAction) },
      PDActionEmbeddedGoTo::SUB_TYPE => ->(dict : Cos::Dictionary) { PDActionEmbeddedGoTo.new(dict).as(PDAction) },
      PDActionHide::SUB_TYPE         => ->(dict : Cos::Dictionary) { PDActionHide.new(dict).as(PDAction) },
      PDActionMovie::SUB_TYPE        => ->(dict : Cos::Dictionary) { PDActionMovie.new(dict).as(PDAction) },
      PDActionSound::SUB_TYPE        => ->(dict : Cos::Dictionary) { PDActionSound.new(dict).as(PDAction) },
      PDActionSubmitForm::SUB_TYPE   => ->(dict : Cos::Dictionary) { PDActionSubmitForm.new(dict).as(PDAction) },
      PDActionResetForm::SUB_TYPE    => ->(dict : Cos::Dictionary) { PDActionResetForm.new(dict).as(PDAction) },
      PDActionThread::SUB_TYPE       => ->(dict : Cos::Dictionary) { PDActionThread.new(dict).as(PDAction) },
      PDActionLaunch::SUB_TYPE       => ->(dict : Cos::Dictionary) { PDActionLaunch.new(dict).as(PDAction) },
      PDActionGoTo::SUB_TYPE         => ->(dict : Cos::Dictionary) { PDActionGoTo.new(dict).as(PDAction) },
      PDActionRemoteGoTo::SUB_TYPE   => ->(dict : Cos::Dictionary) { PDActionRemoteGoTo.new(dict).as(PDAction) },
    } of String => Proc(Cos::Dictionary, PDAction)

    def self.create_action(action : Cos::Dictionary?) : PDAction?
      return unless action

      subtype = action[Cos::Name.new("S")]?.as?(Cos::Name).try(&.value)
      BUILDERS[subtype]?.try(&.call(action)) || PDAction.new(action)
    end
  end
end
