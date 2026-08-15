# A button field represents an interactive control on the screen that the user
# can manipulate with the mouse.
module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDButton < PDTerminalField
    FLAG_NO_TOGGLE_TO_OFF = 1 << 14
    FLAG_RADIO            = 1 << 15
    FLAG_PUSHBUTTON       = 1 << 16
    FLAG_RADIOS_IN_UNISON = 1 << 25

    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new button field (Java PDButton(PDAcroForm)).
    protected def initialize(acro_form : PDAcroForm)
      super(acro_form, Cos::Dictionary.new, nil)
      @dictionary[Cos::Name.new("FT")] = Cos::Name.new("Btn")
    end

    def field_type : String
      "Btn"
    end

    # Java PDButton#isPushButton.
    def push_button? : Bool
      (field_flags & FLAG_PUSHBUTTON) != 0
    end

    # Java PDButton#isRadioButton.
    def radio_button? : Bool
      (field_flags & FLAG_RADIO) != 0
    end

    # Returns the selected value.
    #
    # Off is the default value which will also be returned if the value hasn't
    # been set at all. Java PDButton#getValue.
    def value : String
      value = get_inheritable_attribute(Cos::Name.new("V"))
      if value.is_a?(Cos::Name)
        string_value = value.value
        export_values = get_export_values
        unless export_values.empty?
          begin
            idx = string_value.to_i
            if idx >= 0 && idx < export_values.size
              return export_values[idx]
            end
          rescue ArgumentError
            return string_value
          end
        end
        string_value
      else
        # Off is the default value if there is nothing else set. See PDF Spec.
        "Off"
      end
    end

    # Set the selected option given its name, and try to update the visual appearance.
    def value=(value : String)
      check_value(value)

      # if there are export values/an Opt entry there is a different approach
      # to setting the value
      if get_export_values.empty?
        update_by_value(value)
      else
        update_by_option(value)
      end

      apply_change
    end

    # Set the selected option given its index.
    #
    # NOTE: this method is only usable if there are export values and used for
    # radio buttons with FLAG_RADIOS_IN_UNISON not set.
    # ameba:disable Naming/AccessorMethodName
    def set_value_index(index : Int) : Nil
      export_values = get_export_values
      if export_values.empty? || index < 0 || index >= export_values.size
        raise ArgumentError.new("index '#{index}' is not a valid index for the field #{fully_qualified_name}, valid indices are from 0 to #{export_values.size - 1}")
      end

      update_by_value(index.to_s)

      apply_change
    end

    # Returns the default value, if any.
    def default_value : String
      value = get_inheritable_attribute(Cos::Name.new("DV"))
      if value.is_a?(Cos::Name)
        value.value
      else
        ""
      end
    end

    # Sets the default value.
    def default_value=(value : String) : String
      check_value(value)
      @dictionary.set_name(Cos::Name.new("DV"), value)
      value
    end

    def value_as_string : String
      value
    end

    # Get the (optional) export values defined in the field dictionary's /Opt key.
    # ameba:disable Naming/AccessorMethodName
    def get_export_values : Array(String)
      value = get_inheritable_attribute(Cos::Name.new("Opt"))
      case value
      when Cos::String
        [value.value]
      when Cos::Array
        value.items.compact_map do |item|
          item.as?(Cos::String).try(&.value)
        end
      else
        [] of String
      end
    end

    # Set the export values.
    # ameba:disable Naming/AccessorMethodName
    def set_export_values(values : Array(String)?) : Nil
      if values && !values.empty?
        cos_values = Cos::Array.new
        values.each do |entry|
          cos_values.add(Cos::String.new(entry))
        end
        @dictionary[Cos::Name.new("Opt")] = cos_values
      else
        @dictionary.delete(Cos::Name.new("Opt"))
      end
    end

    # Java PDButton#constructAppearances: update each widget's appearance state
    # from the field value.
    def construct_appearances : Nil
      widgets.each do |widget|
        appearance = widget.appearance
        next if appearance.nil?

        appearance_entry = appearance.normal_appearance
        value = @dictionary.get_name_as_string(Cos::Name.new("V"))
        if value && appearance_entry && appearance_entry.sub_dictionary.has_key?(Cos::Name.new(value))
          widget.appearance_state = value
        else
          widget.appearance_state = "Off"
        end
      end
    end

    # Get the values to set individual buttons within a group to the on state.
    # Java PDButton#getOnValues.
    # ameba:disable Naming/AccessorMethodName
    def get_on_values : Set(String)
      on_values = Set(String).new
      export_values = get_export_values
      unless export_values.empty?
        on_values.concat(export_values)
        return on_values
      end

      widgets.each do |widget|
        on_values.add(get_on_value_for_widget(widget))
      end
      on_values
    end

    # Get the on value for an individual widget by its index.
    protected def get_on_value(index : Int) : String
      widget_list = widgets
      if index < widget_list.size
        return get_on_value_for_widget(widget_list[index])
      end
      ""
    end

    # Get the on value for an individual widget.
    protected def get_on_value_for_widget(widget : Annotation::PDAnnotationWidget) : String
      ap_dictionary = widget.appearance
      if ap_dictionary
        normal_appearance = ap_dictionary.normal_appearance
        if normal_appearance
          normal_appearance.sub_dictionary.keys.each do |entry|
            return entry.value unless entry == Cos::Name.new("Off")
          end
        end
      end
      ""
    end

    # Checks value. Java PDButton#checkValue.
    def check_value(value : String) : Nil
      on_values = get_on_values
      if Cos::Name.new("Off").value != value && !on_values.includes?(value)
        raise ArgumentError.new("value '#{value}' is not a valid option for the field #{fully_qualified_name}, valid values are: #{on_values.to_a} and #{Cos::Name.new("Off").value}")
      end
    end

    protected def apply_change : Nil
      construct_appearances
    end

    private def update_by_value(value : String) : Nil
      @dictionary.set_name(Cos::Name.new("V"), value)
      # update the appearance state (AS)
      widgets.each do |widget|
        appearance = widget.appearance
        next if appearance.nil?

        appearance_entry = appearance.normal_appearance
        if appearance_entry && appearance_entry.sub_dictionary.has_key?(Cos::Name.new(value))
          widget.appearance_state = value
        else
          widget.appearance_state = Cos::Name.new("Off").value
        end
      end
    end

    private def update_by_option(value : String) : Nil
      widget_list = widgets
      options = get_export_values

      if widget_list.size != options.size
        raise ArgumentError.new("The number of options doesn't match the number of widgets")
      end

      if value == Cos::Name.new("Off").value
        update_by_value(value)
      else
        # the value is the index of the matching option
        options_index = options.index(value)

        # get the values the options are pointing to as this might not be
        # numerical, see PDFBOX-3682
        if options_index
          update_by_value(get_on_value(options_index))
        end
      end
    end
  end
end
