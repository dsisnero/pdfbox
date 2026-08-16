# Generate field entries from page level widget annotations if the AcroForm
# /Fields entry is empty.
#
# Ported from Apache PDFBox AcroFormOrphanWidgetsProcessor (PDFBOX-3891/4985).
module Pdfbox::Pdmodel::Interactive::Form
  class AcroFormOrphanWidgetsProcessor
    Log = ::Log.for(self)

    @document : Pdfbox::Pdmodel::Document

    def initialize(@document : Pdfbox::Pdmodel::Document)
    end

    def process : Nil
      acro_form = @document.document_catalog.try(&.acro_form)
      return if acro_form.nil?

      resolve_fields_from_widgets(acro_form)
    end

    private def resolve_fields_from_widgets(acro_form : PDAcroForm) : Nil
      Log.debug { "rebuilding fields from widgets" }
      Log.debug { "acro_form nil? #{acro_form.nil?} default_resources nil? #{acro_form.default_resources.nil?}" }

      resources = acro_form.default_resources
      if resources.nil?
        # failsafe. Currently resources is never null because defaultfixup is
        # called first.
        Log.debug { "AcroForm default resources is null" }
        return
      end

      fields = [] of PDField
      non_terminal_fields_map = {} of String => PDField

      @document.pages.each do |page|
        begin
          handle_annotations(acro_form, resources, fields, page.annotations, non_terminal_fields_map)
        rescue ex
          Log.debug { "couldn't read annotations for page #{ex.message}" }
        end
      end

      Log.debug { "set_fields with #{fields.size} fields" }
      acro_form.set_fields(fields)

      acro_form.get_field_tree.each do |field|
        if field.is_a?(PDVariableText)
          ensure_font_resources(resources, field)
        end
      end
    end

    private def handle_annotations(
      acro_form : PDAcroForm,
      acro_form_resources : Pdfbox::Pdmodel::PDResources,
      fields : Array(PDField),
      annotations : Enumerable(Annotation::PDAnnotation),
      non_terminal_fields_map : Hash(String, PDField),
    ) : Nil
      annotations.each do |ann|
        next unless ann.is_a?(Annotation::PDAnnotationWidget)

        add_font_from_widget(acro_form_resources, ann)

        parent = ann.cos_object[Cos::Name.new("Parent")]?
        parent = parent.object if parent.is_a?(Cos::Object)
        if parent.is_a?(Cos::Dictionary)
          resolved_field = resolve_non_root_field(acro_form, parent, non_terminal_fields_map)
          if resolved_field
            fields << resolved_field
          end
        else
          field = PDFieldFactory.create_field(acro_form, ann.cos_object, nil)
          if field
            fields << field
          end
        end
      end
    end

    # Add font resources from the widget to the AcroForm to make sure embedded
    # fonts are being used and not added by ensure_font_resources potentially
    # using a fallback font.
    private def add_font_from_widget(
      acro_form_resources : Pdfbox::Pdmodel::PDResources,
      annotation_widget : Annotation::PDAnnotationWidget,
    ) : Nil
      normal_appearance_stream = annotation_widget.normal_appearance_stream
      return if normal_appearance_stream.nil?

      appearance_stream = normal_appearance_stream
      return if appearance_stream.nil?

      widget_resources = appearance_stream.resources
      return if widget_resources.nil?

      widget_resources = widget_resources.as(Pdfbox::Pdmodel::PDResources)
      widget_resources.font_names.each do |font_name|
        next if font_name.value.starts_with?("+")

        begin
          if acro_form_resources.get_font(font_name).nil?
            if font = widget_resources.get_font(font_name)
              acro_form_resources.put(font_name, font)
              Log.debug { "added font resource to AcroForm from widget for font name #{font_name}" }
            end
          end
        rescue ex
          Log.debug { "unable to add font to AcroForm for font name #{font_name}: #{ex.message}" }
        end
      end
    end

    # Widgets having a /Parent entry are non root fields. Go up until the root
    # node is found and handle from there.
    private def resolve_non_root_field(
      acro_form : PDAcroForm,
      parent : Cos::Dictionary,
      non_terminal_fields_map : Hash(String, PDField),
    ) : PDField?
      while parent.has_key?(Cos::Name.new("Parent"))
        parent_value = parent[Cos::Name.new("Parent")]?
        parent_value = parent_value.object if parent_value.is_a?(Cos::Object)
        return nil unless parent_value.is_a?(Cos::Dictionary)
        parent = parent_value
      end

      parent_name = parent.get_string(Cos::Name.new("T"))
      if non_terminal_fields_map[parent_name]?.nil?
        field = PDFieldFactory.create_field(acro_form, parent, nil)
        if field
          non_terminal_fields_map[field.fully_qualified_name] = field
        end
        return field
      end

      # this should not happen, likely broken PDF
      nil
    end

    # Look up the font used in the default appearance and if this is not
    # available try to find a suitable font and use that.
    private def ensure_font_resources(default_resources : Pdfbox::Pdmodel::PDResources, field : PDVariableText) : Nil
      da_string = field.default_appearance
      if da_string && da_string.starts_with?("/") && da_string.size > 1
        space_index = da_string.index(' ')
        font_name = if space_index
                      Cos::Name.new(da_string[1, space_index - 1])
                    else
                      Cos::Name.new(da_string[1..])
                    end
        begin
          if default_resources.get_font(font_name).nil?
            Log.debug { "trying to add missing font resource for field #{field.fully_qualified_name}" }
            mapper = Pdfbox::Pdmodel::Font::FontMappers.instance
            font_mapping = mapper.get_true_type_font(font_name.value, nil)
            if ttf = font_mapping.font
              font_doc = Pdfbox::Pdmodel::PDDocument.new(Bytes.new(0))
              pd_font = Pdfbox::Pdmodel::Font::PDType0Font.load(font_doc, ttf, false)
              Log.debug { "looked up font for #{font_name.value} - found #{ttf.name}" }
              default_resources.put(font_name, pd_font)
            else
              Log.debug { "no suitable font found for field #{field.fully_qualified_name} for font name #{font_name.value}" }
            end
          end
        rescue ex
          Log.debug { "unable to handle font resources for field #{field.fully_qualified_name}: #{ex.message}" }
        end
      end
    end
  end
end
