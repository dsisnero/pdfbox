module Pdfbox::Pdmodel::Interactive::Action
  class PDPageAdditionalActions
    @actions : Cos::Dictionary

    def initialize
      @actions = Cos::Dictionary.new
    end

    def initialize(@actions : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @actions
    end

    def o : PDAction?
      action_for("O")
    end

    def o=(action : PDAction) : PDAction
      set_action("O", action)
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
