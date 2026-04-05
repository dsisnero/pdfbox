module Pdfbox::Pdmodel::Interactive::Action
  class PDAction
    TYPE = "Action"

    @action : Cos::Dictionary

    def initialize
      @action = Cos::Dictionary.new
      set_type(TYPE)
    end

    def initialize(@action : Cos::Dictionary)
    end

    def cos_object : Cos::Dictionary
      @action
    end

    def type : String?
      @action[Cos::Name::TYPE]?.as?(Cos::Name).try(&.value)
    end

    def subtype : String?
      @action[Cos::Name.new("S")]?.as?(Cos::Name).try(&.value)
    end

    def next : Array(PDAction)?
      next_value = @action[Cos::Name.new("Next")]?
      case next_value
      when Cos::Dictionary
        [PDActionFactory.create_action(next_value)].compact
      when Cos::Array
        actions = [] of PDAction
        next_value.items.each do |item|
          if action_dict = item.as?(Cos::Dictionary)
            if action = PDActionFactory.create_action(action_dict)
              actions << action
            end
          end
        end
        actions.empty? ? nil : actions
      else
        nil
      end
    end

    def next=(actions : Array(PDAction)) : Array(PDAction)
      array = Cos::Array.new
      actions.each { |action| array.add(action.cos_object) }
      @action[Cos::Name.new("Next")] = array
      actions
    end

    protected def set_type(type : String) : String
      @action[Cos::Name::TYPE] = Cos::Name.new(type)
      type
    end

    protected def set_subtype(subtype : String) : String
      @action[Cos::Name.new("S")] = Cos::Name.new(subtype)
      subtype
    end
  end
end
