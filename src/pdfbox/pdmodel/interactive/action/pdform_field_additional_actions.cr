module Pdfbox::Pdmodel::Interactive::Action
  class PDFormFieldAdditionalActions
    @actions : Cos::Dictionary

    def initialize
      @actions = Cos::Dictionary.new
    end

    def initialize(@actions : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @actions
    end

    def k : PDAction?
      action_for("K")
    end

    def k=(action : PDAction) : PDAction
      set_action("K", action)
    end

    def f : PDAction?
      action_for("F")
    end

    def f=(action : PDAction) : PDAction
      set_action("F", action)
    end

    def v : PDAction?
      action_for("V")
    end

    def v=(action : PDAction) : PDAction
      set_action("V", action)
    end

    def c : PDAction?
      action_for("C")
    end

    def c=(action : PDAction) : PDAction
      set_action("C", action)
    end

    private def action_for(key : String) : PDAction?
      PDActionFactory.create_action(@actions[Cos::Name.new(key)]?.as?(Cos::Dictionary))
    end

    private def set_action(key : String, action : PDAction) : PDAction
      @actions[Cos::Name.new(key)] = action.cos_object
      action
    end
  end
end
