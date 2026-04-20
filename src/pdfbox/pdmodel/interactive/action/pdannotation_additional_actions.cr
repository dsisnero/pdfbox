module Pdfbox::Pdmodel::Interactive::Action
  class PDAnnotationAdditionalActions
    @actions : Cos::Dictionary

    def initialize
      @actions = Cos::Dictionary.new
    end

    def initialize(@actions : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @actions
    end

    def e : PDAction?
      action_for("E")
    end

    def e=(action : PDAction) : PDAction
      set_action("E", action)
    end

    def x : PDAction?
      action_for("X")
    end

    def x=(action : PDAction) : PDAction
      set_action("X", action)
    end

    def d : PDAction?
      action_for("D")
    end

    def d=(action : PDAction) : PDAction
      set_action("D", action)
    end

    def u : PDAction?
      action_for("U")
    end

    def u=(action : PDAction) : PDAction
      set_action("U", action)
    end

    def fo : PDAction?
      action_for("Fo")
    end

    def fo=(action : PDAction) : PDAction
      set_action("Fo", action)
    end

    def bl : PDAction?
      action_for("Bl")
    end

    def bl=(action : PDAction) : PDAction
      set_action("Bl", action)
    end

    def po : PDAction?
      action_for("PO")
    end

    def po=(action : PDAction) : PDAction
      set_action("PO", action)
    end

    def pc : PDAction?
      action_for("PC")
    end

    def pc=(action : PDAction) : PDAction
      set_action("PC", action)
    end

    def pv : PDAction?
      action_for("PV")
    end

    def pv=(action : PDAction) : PDAction
      set_action("PV", action)
    end

    def pi : PDAction?
      action_for("PI")
    end

    def pi=(action : PDAction) : PDAction
      set_action("PI", action)
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
