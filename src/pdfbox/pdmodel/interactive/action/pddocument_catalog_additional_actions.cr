module Pdfbox::Pdmodel::Interactive::Action
  class PDDocumentCatalogAdditionalActions
    @actions : Cos::Dictionary

    def initialize
      @actions = Cos::Dictionary.new
    end

    def initialize(@actions : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @actions
    end

    def wc : PDAction?
      action_for("WC")
    end

    def wc=(action : PDAction) : PDAction
      set_action("WC", action)
    end

    def ws : PDAction?
      action_for("WS")
    end

    def ws=(action : PDAction) : PDAction
      set_action("WS", action)
    end

    def ds : PDAction?
      action_for("DS")
    end

    def ds=(action : PDAction) : PDAction
      set_action("DS", action)
    end

    def wp : PDAction?
      action_for("WP")
    end

    def wp=(action : PDAction) : PDAction
      set_action("WP", action)
    end

    def dp : PDAction?
      action_for("DP")
    end

    def dp=(action : PDAction) : PDAction
      set_action("DP", action)
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
