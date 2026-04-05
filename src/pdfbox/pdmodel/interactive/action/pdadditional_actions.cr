module Pdfbox::Pdmodel::Interactive::Action
  class PDAdditionalActions
    @actions : Cos::Dictionary

    def initialize
      @actions = Cos::Dictionary.new
    end

    def initialize(@actions : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @actions
    end

    def f : PDAction?
      PDActionFactory.create_action(@actions[Cos::Name.new("F")]?.as?(Cos::Dictionary))
    end

    def f=(action : PDAction) : PDAction
      @actions[Cos::Name.new("F")] = action.cos_object
      action
    end
  end
end
