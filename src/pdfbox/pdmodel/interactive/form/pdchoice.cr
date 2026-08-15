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

    def value=(value : String)
      @dictionary[Cos::Name.new("V")] = Cos::String.new(value)
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

    # Check if combo box
    def combo? : Bool
      (field_flags & FLAG_COMBO) != 0
    end

    # Check if editable
    def editable? : Bool
      (field_flags & FLAG_EDIT) != 0
    end

    # Check if multi-select
    def multi_select? : Bool
      (field_flags & FLAG_MULTI_SELECT) != 0
    end
  end
end
