# A choice field in an interactive form (base for list box and combo box)
module Pdfbox::Pdmodel::Interactive::Form
  class PDChoice < PDVariableText
    FLAG_COMBO                = 1 << 17
    FLAG_EDIT                 = 1 << 18
    FLAG_SORT                 = 1 << 19
    FLAG_MULTI_SELECT         = 1 << 21
    FLAG_DO_NOT_SPELL_CHECK   = 1 << 22
    FLAG_COMMIT_ON_SEL_CHANGE = 1 << 26

    def initialize(form : PDAcroForm, dictionary : Cos::Dictionary, parent : PDNonTerminalField?)
      super(form, dictionary, parent)
    end

    # Convenience constructor for a new choice field (Java PDChoice(PDAcroForm)).
    def initialize(acro_form : PDAcroForm)
      super(acro_form, Cos::Dictionary.new, nil)
      @dictionary[Cos::Name.new("FT")] = Cos::Name.new("Ch")
    end

    def field_type : String
      "Ch"
    end

    def value_as_string : String
      value = @dictionary[Cos::Name.new("V")]
      case value
      when Cos::String
        value.value
      when Cos::Name
        value.value
      else
        ""
      end
    end

    # Set the selected value of this field, and try to update the visual appearance.
    # Java PDChoice#setValue(String): removes the I key for single valued fields.
    def value=(value : String)
      @dictionary.set_string(Cos::Name.new("V"), value)

      # remove I key for single valued choice field
      set_selected_options_index(nil)

      apply_change
    end

    # Sets the default value of this field.
    def default_value=(value : String) : String
      @dictionary.set_string(Cos::Name.new("DV"), value)
      value
    end

    # Returns the selected values, or an empty Array. This list always contains a
    # single item unless #multi_select? is true. Java PDChoice#getValue.
    def value : Array(String)
      get_value_for(Cos::Name.new("V"))
    end

    # Returns the default values, or an empty Array. Java PDChoice#getDefaultValue.
    def default_value : Array(String)
      get_value_for(Cos::Name.new("DV"))
    end

    private def get_value_for(name : Cos::Name) : Array(String)
      value = @dictionary[name]?
      value = value.object if value.is_a?(Cos::Object)
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

    # Set the selected values. Java PDChoice#setValue(List).
    # ameba:disable Naming/AccessorMethodName
    def set_values(values : Array(String)?) : Nil
      if values && !values.empty?
        unless multi_select?
          raise ArgumentError.new("The list box does not allow multiple selections.")
        end
        options = get_options
        unless options.each.all? { |option| values.includes?(option) }
          raise ArgumentError.new("The values are not contained in the selectable options.")
        end
        cos_values = Cos::Array.new
        values.each do |entry|
          cos_values.add(Cos::String.new(entry))
        end
        @dictionary[Cos::Name.new("V")] = cos_values
        update_selected_options_index(values, options)
      else
        @dictionary.delete(Cos::Name.new("V"))
        @dictionary.delete(Cos::Name.new("I"))
      end
      apply_change
    end

    # Get the options (array of display value / export value pairs)
    def options : Array({String, String})
      result = [] of {String, String}
      opt = @dictionary[Cos::Name.new("Opt")]
      return result unless opt.is_a?(Cos::Array)

      opt.items.each do |item|
        case item
        when Cos::String
          val = item.value
          result << {val, val}
        when Cos::Array
          # [export value, display value]
          if item.items.size >= 2
            export_val = item.items[0].as?(Cos::String).try(&.value) || ""
            display_val = item.items[1].as?(Cos::String).try(&.value) || ""
            result << {display_val, export_val}
          end
        end
      end
      result
    end

    # Java PDChoice#getOptions / #getOptionsExportValues: returns the export
    # values (the first element of each two-element array, or the string itself).
    # ameba:disable Naming/AccessorMethodName
    def get_options : Array(String)
      get_pairable_items(@dictionary[Cos::Name.new("Opt")]?, 0)
    end

    # Java PDChoice#getOptionsDisplayValues: returns the display values (the
    # second element of each two-element array, or the string itself).
    # ameba:disable Naming/AccessorMethodName
    def get_options_display_values : Array(String)
      get_pairable_items(@dictionary[Cos::Name.new("Opt")]?, 1)
    end

    private def get_pairable_items(items : Cos::Base?, pair_index : Int32) : Array(String)
      if pair_index < 0 || pair_index > 1
        raise ArgumentError.new("Only 0 and 1 are allowed as an index into two-element arrays")
      end

      case items
      when Cos::String
        [items.value]
      when Cos::Array
        result = [] of String
        items.items.each do |entry|
          case entry
          when Cos::String
            result << entry.value
          when Cos::Array
            if entry.items.size >= pair_index + 1
              if value = entry.items[pair_index].as?(Cos::String)
                result << value.value
              end
            end
          end
        end
        result
      else
        [] of String
      end
    end

    # Set the options
    def options=(opts : Array({String, String}))
      arr = Cos::Array.new
      opts.each do |display, export|
        if display == export
          arr.add(Cos::String.new(display))
        else
          pair = Cos::Array.new
          pair.add(Cos::String.new(export))
          pair.add(Cos::String.new(display))
          arr.add(pair)
        end
      end
      @dictionary[Cos::Name.new("Opt")] = arr
    end

    # Set the display values - the 'Opt' key. Java PDChoice#setOptions(List).
    # ameba:disable Naming/AccessorMethodName
    def set_options(display_values : Array(String)?) : Nil
      if display_values && !display_values.empty?
        values = sort? ? display_values.sort : display_values
        arr = Cos::Array.new
        values.each do |entry|
          arr.add(Cos::String.new(entry))
        end
        @dictionary[Cos::Name.new("Opt")] = arr
      else
        @dictionary.delete(Cos::Name.new("Opt"))
      end
    end

    # Set the display and export values - the 'Opt' key. Java
    # PDChoice#setOptions(List, List).
    def set_options(export_values : Array(String)?, display_values : Array(String)?) : Nil
      if export_values && display_values && !export_values.empty? && !display_values.empty?
        if export_values.size != display_values.size
          raise ArgumentError.new("The number of entries for exportValue and displayValue shall be the same.")
        end

        key_value_pairs = export_values.zip(display_values)
        if sort?
          key_value_pairs = key_value_pairs.sort_by { |_key, value| value }
        end

        options = Cos::Array.new
        key_value_pairs.each do |key, value|
          entry = Cos::Array.new
          entry.add(Cos::String.new(key))
          entry.add(Cos::String.new(value))
          options.add(entry)
        end
        @dictionary[Cos::Name.new("Opt")] = options
      else
        @dictionary.delete(Cos::Name.new("Opt"))
      end
    end

    # Java PDChoice#getOptionsExportValues: same as #get_options (export values).
    # ameba:disable Naming/AccessorMethodName
    def get_options_export_values : Array(String)
      get_options
    end

    # Set the selected options index - the 'I' key.
    # ameba:disable Naming/AccessorMethodName
    def set_selected_options_index(values : Array(Int)?) : Nil
      if values && !values.empty?
        unless multi_select?
          raise ArgumentError.new("Setting the indices is not allowed for choice fields not allowing multiple selections.")
        end
        arr = Cos::Array.new
        values.each do |entry|
          arr.add(Cos::Integer.new(entry.to_i64))
        end
        @dictionary[Cos::Name.new("I")] = arr
      else
        @dictionary.delete(Cos::Name.new("I"))
      end
    end

    # Get the selected options indices - the 'I' key.
    # ameba:disable Naming/AccessorMethodName
    def get_selected_options_index : Array(Int32)
      value = @dictionary[Cos::Name.new("I")]?
      value = value.object if value.is_a?(Cos::Object)
      return [] of Int32 unless value.is_a?(Cos::Array)
      value.items.compact_map do |item|
        case item
        when Cos::Integer then item.value.to_i32
        when Cos::Float   then item.value.to_i32
        else                   nil
        end
      end
    end

    # Update the 'I' key based on values set.
    private def update_selected_options_index(values : Array(String), options : Array(String)) : Nil
      indices = values.compact_map { |value| options.index(value) }
      indices.sort!
      set_selected_options_index(indices)
    end

    # Check if combo box
    def combo? : Bool
      (field_flags & FLAG_COMBO) != 0
    end

    # Set the Combo bit.
    def combo=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_COMBO, value)
      value
    end

    # Check if editable
    def editable? : Bool
      (field_flags & FLAG_EDIT) != 0
    end

    # Set the Edit bit.
    def editable=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_EDIT, value)
      value
    end

    # Check if sorted. Java PDChoice#isSort.
    def sort? : Bool
      (field_flags & FLAG_SORT) != 0
    end

    # Set the Sort bit.
    def sort=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_SORT, value)
      value
    end

    # Check if multi-select. Java PDChoice#isMultiSelect.
    def multi_select? : Bool
      (field_flags & FLAG_MULTI_SELECT) != 0
    end

    # Set the MultiSelect bit.
    def multi_select=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_MULTI_SELECT, value)
      value
    end

    # Check if do not spell check. Java PDChoice#isDoNotSpellCheck.
    def do_not_spell_check? : Bool
      (field_flags & FLAG_DO_NOT_SPELL_CHECK) != 0
    end

    # Set the DoNotSpellCheck bit.
    def do_not_spell_check=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_DO_NOT_SPELL_CHECK, value)
      value
    end

    # Check if commit on selection change. Java PDChoice#isCommitOnSelChange.
    def commit_on_sel_change? : Bool
      (field_flags & FLAG_COMMIT_ON_SEL_CHANGE) != 0
    end

    # Set the CommitOnSelChange bit.
    def commit_on_sel_change=(value : Bool) : Bool
      @dictionary.set_flag(Cos::Name.new("Ff"), FLAG_COMMIT_ON_SEL_CHANGE, value)
      value
    end

    protected def apply_change : Nil
      construct_appearances
    end

    # Java PDChoice#constructAppearances is abstract; PDListBox/PDComboBox
    # implement it via the AppearanceGeneratorHelper.
    def construct_appearances : Nil
      raise Pdfbox::Cos::UnsupportedOperationError.new("construct_appearances is not supported for a base choice field")
    end
  end
end
