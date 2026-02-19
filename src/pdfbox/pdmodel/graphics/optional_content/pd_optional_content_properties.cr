module Pdfbox::Pdmodel::Graphics::OptionalContent
  class PDOptionalContentProperties
    enum BaseState
      On
      Off
      Unchanged
    end

    @dict : Pdfbox::Cos::Dictionary

    def initialize
      @dict = Pdfbox::Cos::Dictionary.new
      @dict.set_item("OCGs", Pdfbox::Cos::Array.new)
      d = Pdfbox::Cos::Dictionary.new
      d.set_string("Name", "Top")
      @dict.set_item("D", d)
    end

    def initialize(@dict : Pdfbox::Cos::Dictionary)
    end

    def cos_object : Pdfbox::Cos::Dictionary
      @dict
    end

    def group(name : String) : PDOptionalContentGroup?
      get_ocgs.items.each do |item|
        dictionary = to_dictionary(item)
        next unless dictionary
        group_name = dictionary[Pdfbox::Cos::Name.new("Name")].as?(Pdfbox::Cos::String).try(&.value)
        return PDOptionalContentGroup.new(dictionary) if group_name == name
      end
      nil
    end

    def add_group(ocg : PDOptionalContentGroup) : Nil
      get_ocgs.add(ocg.cos_object)

      order = get_d[Pdfbox::Cos::Name.new("Order")].as?(Pdfbox::Cos::Array)
      unless order
        order = Pdfbox::Cos::Array.new
        get_d.set_item("Order", order)
      end
      order.add(ocg.cos_object)
    end

    def optional_content_groups : Array(PDOptionalContentGroup)
      groups = [] of PDOptionalContentGroup
      get_ocgs.items.each do |item|
        dictionary = to_dictionary(item)
        groups << PDOptionalContentGroup.new(dictionary) if dictionary
      end
      groups
    end

    def base_state : BaseState
      value = get_d[Pdfbox::Cos::Name.new("BaseState")]
      state = value.as?(Pdfbox::Cos::Name).try(&.value)
      case state
      when "OFF"       then BaseState::Off
      when "UNCHANGED" then BaseState::Unchanged
      else                  BaseState::On
      end
    end

    def base_state=(state : BaseState) : BaseState
      name = case state
             when BaseState::On        then "ON"
             when BaseState::Off       then "OFF"
             when BaseState::Unchanged then "UNCHANGED"
             end
      get_d.set_name("BaseState", name)
      state
    end

    def group_names : Array(String)
      get_ocgs.items.map do |item|
        dictionary = to_dictionary(item)
        next "" unless dictionary
        dictionary[Pdfbox::Cos::Name.new("Name")].as?(Pdfbox::Cos::String).try(&.value) || ""
      end
    end

    def has_group?(group_name : String) : Bool
      group_names.includes?(group_name)
    end

    def group_enabled?(group_name : String) : Bool
      result = false
      get_ocgs.items.each do |item|
        dictionary = to_dictionary(item)
        next unless dictionary
        name = dictionary[Pdfbox::Cos::Name.new("Name")].as?(Pdfbox::Cos::String).try(&.value)
        if group_name == name && group_enabled?(PDOptionalContentGroup.new(dictionary))
          result = true
        end
      end
      result
    end

    def group_enabled?(group : PDOptionalContentGroup?) : Bool
      enabled = base_state != BaseState::Off
      return enabled unless group

      on = get_d[Pdfbox::Cos::Name.new("ON")].as?(Pdfbox::Cos::Array)
      if on && includes_group?(on, group)
        return true
      end

      off = get_d[Pdfbox::Cos::Name.new("OFF")].as?(Pdfbox::Cos::Array)
      if off && includes_group?(off, group)
        return false
      end

      enabled
    end

    def set_group_enabled(group_name : String, enable : Bool) : Bool
      result = false
      get_ocgs.items.each do |item|
        dictionary = to_dictionary(item)
        next unless dictionary
        name = dictionary[Pdfbox::Cos::Name.new("Name")].as?(Pdfbox::Cos::String).try(&.value)
        if group_name == name && set_group_enabled(PDOptionalContentGroup.new(dictionary), enable)
          result = true
        end
      end
      result
    end

    def set_group_enabled(group : PDOptionalContentGroup, enable : Bool) : Bool
      d = get_d
      on = d[Pdfbox::Cos::Name.new("ON")].as?(Pdfbox::Cos::Array)
      if on.nil?
        on = Pdfbox::Cos::Array.new
        d.set_item("ON", on)
      end

      off = d[Pdfbox::Cos::Name.new("OFF")].as?(Pdfbox::Cos::Array)
      if off.nil?
        off = Pdfbox::Cos::Array.new
        d.set_item("OFF", off)
      end

      found = false
      if enable
        off.items.each do |item|
          dictionary = to_dictionary(item)
          next unless dictionary
          if dictionary.same?(group.cos_object)
            off.remove_object(item)
            on.add(item)
            found = true
            break
          end
        end
      else
        on.items.each do |item|
          dictionary = to_dictionary(item)
          next unless dictionary
          if dictionary.same?(group.cos_object)
            on.remove_object(item)
            off.add(item)
            found = true
            break
          end
        end
      end

      unless found
        if enable
          on.add(group.cos_object)
        else
          off.add(group.cos_object)
        end
      end

      found
    end

    private def get_ocgs : Pdfbox::Cos::Array
      ocgs = @dict[Pdfbox::Cos::Name.new("OCGs")].as?(Pdfbox::Cos::Array)
      unless ocgs
        ocgs = Pdfbox::Cos::Array.new
        @dict.set_item("OCGs", ocgs)
      end
      ocgs
    end

    private def get_d : Pdfbox::Cos::Dictionary
      d = @dict[Pdfbox::Cos::Name.new("D")].as?(Pdfbox::Cos::Dictionary)
      unless d
        d = Pdfbox::Cos::Dictionary.new
        d.set_string("Name", "Top")
        @dict.set_item("D", d)
      end
      d
    end

    private def to_dictionary(object : Pdfbox::Cos::Base) : Pdfbox::Cos::Dictionary?
      object.as?(Pdfbox::Cos::Dictionary)
    end

    private def includes_group?(array : Pdfbox::Cos::Array, group : PDOptionalContentGroup) : Bool
      array.items.any? do |item|
        dictionary = to_dictionary(item)
        !dictionary.nil? && dictionary.same?(group.cos_object)
      end
    end
  end
end
