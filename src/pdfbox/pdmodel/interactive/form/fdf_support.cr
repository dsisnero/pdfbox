module Pdfbox::Pdmodel::Interactive::Form
  abstract class PDField
    def import_fdf(fdf_field : Pdfbox::Pdmodel::Fdf::FDFField) : Nil
      cos_value = fdf_field.cos_value
      if terminal_field = self.as?(PDTerminalField)
        import_terminal_value(cos_value, terminal_field) if cos_value
      elsif cos_value
        @dictionary[Pdfbox::Cos::Name.new("V")] = cos_value
      end

      if value = fdf_field.field_flags
        self.field_flags = value
      else
        if value = fdf_field.set_field_flags
          self.field_flags = field_flags | value
        end
        if value = fdf_field.clear_field_flags
          self.field_flags = field_flags & ~value
        end
      end
    end

    abstract def export_fdf : Pdfbox::Pdmodel::Fdf::FDFField

    private def import_terminal_value(cos_value : Pdfbox::Cos::Base, terminal_field : PDTerminalField) : Nil
      case cos_value
      when Pdfbox::Cos::Name
        terminal_field.value = cos_value.value
      when Pdfbox::Cos::String
        terminal_field.value = cos_value.value
      when Pdfbox::Cos::Stream
        terminal_field.value = cos_value.create_input_stream.gets_to_end
      when Pdfbox::Cos::Array
        if choice = self.as?(PDChoice)
          choice.values = cos_value.to_cos_string_string_list.compact
        else
          raise ::IO::Error.new("Error:Unknown type for field import#{cos_value}")
        end
      else
        raise ::IO::Error.new("Error:Unknown type for field import#{cos_value}")
      end
    end
  end

  abstract class PDTerminalField < PDField
    def import_fdf(fdf_field : Pdfbox::Pdmodel::Fdf::FDFField) : Nil
      super

      widgets.each do |widget|
        if value = fdf_field.widget_field_flags
          widget.flags = value
        else
          if value = fdf_field.set_widget_field_flags
            widget.flags = widget.flags | value
          end
          if value = fdf_field.clear_widget_field_flags
            widget.flags = widget.flags & ~value
          end
        end
      end
    end

    def export_fdf : Pdfbox::Pdmodel::Fdf::FDFField
      field = Pdfbox::Pdmodel::Fdf::FDFField.new(partial_name, @dictionary[Pdfbox::Cos::Name.new("V")]?)
      field.field_flags = field_flags
      field.widget_field_flags = widgets.first?.try(&.flags)
      field
    end
  end

  class PDNonTerminalField
    def import_fdf(fdf_field : Pdfbox::Pdmodel::Fdf::FDFField) : Nil
      super
      children_by_name = children.compact_map { |child| name = child.partial_name; name ? {name, child} : nil }.to_h
      fdf_field.kids.try(&.each do |kid|
        next unless name = kid.partial_field_name
        children_by_name[name]?.try(&.import_fdf(kid))
      end)
    end

    def export_fdf : Pdfbox::Pdmodel::Fdf::FDFField
      kids = children.map(&.export_fdf)
      field = Pdfbox::Pdmodel::Fdf::FDFField.new(partial_name, @dictionary[Pdfbox::Cos::Name.new("V")]?, kids)
      field.field_flags = field_flags
      field
    end
  end

  class PDChoice
    def values : Array(String)
      current = @dictionary[Pdfbox::Cos::Name.new("V")]?
      if current.is_a?(Pdfbox::Cos::Array)
        current.to_cos_string_string_list.compact
      else
        value = value_as_string
        value.empty? ? [] of String : [value]
      end
    end

    def values=(values : Array(String)) : Nil
      if values.size <= 1
        self.value = values.first? || ""
      else
        array = Pdfbox::Cos::Array.new
        values.each { |value| array.add(Pdfbox::Cos::String.new(value)) }
        @dictionary[Pdfbox::Cos::Name.new("V")] = array
      end
    end
  end
end
