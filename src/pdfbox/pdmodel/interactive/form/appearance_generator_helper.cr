# Create the AcroForms field appearance helper.
#
# Ported from Apache PDFBox AppearanceGeneratorHelper. Generates the normal
# appearance stream for a variable text field's widgets from the field's value,
# /DA default appearance string and widget appearance characteristics.
module Pdfbox::Pdmodel::Interactive::Form
  class AppearanceGeneratorHelper
    Log = ::Log.for(self)

    BMC = Pdfbox::ContentStream::Operator.get_operator("BMC")
    EMC = Pdfbox::ContentStream::Operator.get_operator("EMC")

    # PDF line separators (Java Pattern.compile).
    LINE_SEPARATORS = {0x0A, 0x0B, 0x0C, 0x0D, 0x85, 0x2028, 0x2029}

    # The highlight color used by Adobe for selected entries in a list box.
    HIGHLIGHT_COLOR = {153_f32 / 255_f32, 193_f32 / 255_f32, 215_f32 / 255_f32}

    # The scaling factor for font units to PDF units.
    FONT_SCALE = 1000

    # The default font size used for multiline text.
    DEFAULT_FONT_SIZE = 12.0_f32

    # The minimum/maximum font sizes used for multiline text auto sizing.
    MINIMUM_FONT_SIZE = 4.0_f32

    # The default padding applied by Acrobat to the fields bbox.
    DEFAULT_PADDING = 0.5_f32

    @field : PDVariableText
    @default_appearance : PDDefaultAppearanceString
    @value : String = ""

    def initialize(field : PDVariableText)
      @field = field
      validate_and_ensure_acro_form_resources
      @default_appearance = field.default_appearance_string
    end

    # This is the public method for setting the appearance stream.
    # ameba:disable Naming/AccessorMethodName
    def set_appearance_value(ap_value : String) : Nil
      @value = get_formatted_value(ap_value)

      # Treat multiline field values in single lines as single line values.
      # This is in line with how Adobe Reader behaves when entering text
      # interactively (see PDFBOX-3911).
      if @field.is_a?(PDTextField) && !@field.as(PDTextField).multiline?
        @value = normalize_line_separators(@value)
      end

      @field.widgets.each do |widget|
        if widget.cos_object.has_key?(Cos::Name.new("PMD"))
          Log.warn { "widget of field #{@field.fully_qualified_name} is a PaperMetaData widget, no appearance stream created" }
          next
        end

        # Some fields have the /DA at the widget level if the widgets differ in layout.
        acro_form_appearance = @default_appearance
        da_entry = widget.cos_object[Cos::Name.new("DA")]?
        if da_entry
          @default_appearance = get_widget_default_appearance_string(widget)
        end

        rect = widget.rectangle
        if rect.nil?
          widget.cos_object.delete(Cos::Name.new("AP"))
          Log.warn { "widget of field #{@field.fully_qualified_name} has no rectangle, no appearance stream created" }
          next
        end

        appearance_dict = widget.appearance
        if appearance_dict.nil?
          appearance_dict = Annotation::PDAppearanceDictionary.new
          widget.appearance = appearance_dict
        end

        appearance = appearance_dict.normal_appearance

        appearance_stream = if is_valid_appearance_stream(appearance)
                              appearance.as(Annotation::PDAppearanceEntry).appearance_stream
                            else
                              prepared = prepare_normal_appearance_stream(widget)
                              appearance_dict.normal_appearance = prepared
                              prepared
                            end

        appearance_characteristics = widget.appearance_characteristics

        # Adobe Acrobat always recreates the complete appearance stream if there is an
        # appearance characteristics entry. In addition if there is no content yet also
        # create the appearance stream from the entries.
        if appearance_characteristics != nil || appearance_stream.content_stream.length == 0
          initialize_appearance_content(widget, appearance_characteristics, appearance_stream)
        end

        set_appearance_content(widget, appearance_stream)

        # restore the field level appearance
        @default_appearance = acro_form_appearance
      end
    end

    # Adobe Reader/Acrobat add resources which are at the field/widget level to the
    # AcroForm level.
    private def validate_and_ensure_acro_form_resources : Nil
      acro_form_resources = @field.acro_form.default_resources
      return if acro_form_resources.nil?

      @field.widgets.each do |widget|
        stream = widget.normal_appearance_stream
        next if stream.nil?

        widget_resources = stream.resources
        next if widget_resources.nil?

        widget_font_dict = widget_resources.cos_object.get_dictionary(Cos::Name.new("Font"))
        next if widget_font_dict.nil?

        widget_resources.font_names.each do |font_resource_name|
          if acro_form_resources.font(font_resource_name).nil?
            Log.debug { "Adding font resource #{font_resource_name} from widget to AcroForm" }
            # use the COS-object to preserve a possible indirect object reference
            if font_value = widget_font_dict[font_resource_name]?
              font_dict = acro_form_resources.cos_object.get_dictionary(Cos::Name.new("Font")) || begin
                created = Pdfbox::Cos::Dictionary.new
                acro_form_resources.cos_object[Cos::Name.new("Font")] = created
                created
              end
              font_dict[font_resource_name] = font_value
            end
          end
        end
      end
    end

    private def get_formatted_value(ap_value : String) : String
      # format the field value for the appearance if there is scripting support and
      # the field has a format event
      actions = @field.actions
      return ap_value if actions.nil?

      action_f = actions.f
      if action_f
        scripting_handler = @field.acro_form.scripting_handler
        if scripting_handler
          return scripting_handler.format(action_f.as(Action::PDActionJavaScript), ap_value)
        end
        Log.info { "Field contains a formatting action but no ScriptingHandler has been supplied - formatted value might be incorrect" }
      end
      ap_value
    end

    # Replace CRLF and single line separators with spaces (Java PATTERN.matcher(...).replaceAll(" ")).
    private def normalize_line_separators(value : String) : String
      String.build do |io|
        chars = value.chars
        index = 0
        while index < chars.size
          char = chars[index]
          if char == '\r' && index + 1 < chars.size && chars[index + 1] == '\n'
            io << ' '
            index += 2
          elsif LINE_SEPARATORS.includes?(char.ord)
            io << ' '
            index += 1
          else
            io << char
            index += 1
          end
        end
      end
    end

    # ameba:disable Naming/PredicateName
    private def is_valid_appearance_stream(appearance : Annotation::PDAppearanceEntry?) : Bool
      return false if appearance.nil?
      return false unless appearance.stream?
      bbox = appearance.appearance_stream.bbox
      return false if bbox.nil?
      bbox.width.abs > 0 && bbox.height.abs > 0
    end

    private def prepare_normal_appearance_stream(widget : Annotation::PDAnnotationWidget) : Annotation::PDAppearanceStream
      appearance_stream = Annotation::PDAppearanceStream.new(Cos::Stream.new)

      # Calculate the entries for the bounding box and the transformation matrix
      # settings for the appearance stream
      rotation = resolve_rotation(widget)
      rect = widget.rectangle || Common::PDRectangle.new
      matrix = Util::Matrix.get_rotate_instance(rotation.to_f64 * Math::PI / 180.0, 0.0_f32, 0.0_f32)
      point_x = matrix.get_value(0, 0) * rect.width + matrix.get_value(1, 0) * rect.height + matrix.get_value(2, 0)
      point_y = matrix.get_value(0, 1) * rect.width + matrix.get_value(1, 1) * rect.height + matrix.get_value(2, 1)

      bbox = Common::PDRectangle.new(
        0.0_f32,
        0.0_f32,
        point_x.abs,
        point_y.abs
      )
      appearance_stream.bbox = bbox

      at = calculate_matrix(bbox, rotation)
      identity = Util::Matrix.new
      appearance_stream.matrix = at unless at == identity
      appearance_stream.form_type = 1
      appearance_stream.resources = Pdmodel::PDResources.new
      appearance_stream
    end

    private def get_widget_default_appearance_string(widget : Annotation::PDAnnotationWidget) : PDDefaultAppearanceString
      da = widget.cos_object[Cos::Name.new("DA")]?.as?(Cos::String)
      dr = @field.acro_form.default_resources
      PDDefaultAppearanceString.new(da, dr)
    end

    private def resolve_rotation(widget : Annotation::PDAnnotationWidget) : Int32
      characteristics_dictionary = widget.appearance_characteristics
      if characteristics_dictionary
        # 0 is the default value if the R key doesn't exist
        return characteristics_dictionary.rotation
      end
      0
    end

    # Initialize the content of the appearance stream. Get settings like border
    # style, border width and colors to be used to draw a rectangle and background
    # color around the widget.
    private def initialize_appearance_content(
      widget : Annotation::PDAnnotationWidget,
      appearance_characteristics : Annotation::PDAppearanceCharacteristicsDictionary?,
      appearance_stream : Annotation::PDAppearanceStream,
    ) : Nil
      output = ::IO::Memory.new
      contents = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream, output)

      # TODO: support more entries like patterns, etc.
      if appearance_characteristics
        background_colour = appearance_characteristics.background
        if background_colour
          contents.non_stroking_color = background_colour
          bbox = resolve_bounding_box(widget, appearance_stream)
          contents.add_rect(bbox.lower_left_x, bbox.lower_left_y, bbox.width, bbox.height)
          contents.fill
        end

        line_width = 0.0_f32
        border_colour = appearance_characteristics.border_colour
        if border_colour
          contents.stroking_color = border_colour
          line_width = 1.0_f32
        end
        border_style = widget.border_style
        if border_style && border_style.width > 0
          line_width = border_style.width.to_f32
        end

        if line_width > 0 && border_colour
          if line_width != 1
            contents.line_width(line_width)
          end
          bbox = resolve_bounding_box(widget, appearance_stream)
          clip_rect = apply_padding(bbox, Math.max(DEFAULT_PADDING, line_width / 2.0_f32))
          contents.add_rect(clip_rect.lower_left_x, clip_rect.lower_left_y, clip_rect.width, clip_rect.height)
          contents.close_and_stroke
        end

        # draw the dividers for a comb field
        if border_colour && shall_comb
          max_len = @field.as(PDTextField).max_length || -1
          bbox = resolve_bounding_box(widget, appearance_stream)
          clip_rect = apply_padding(bbox, Math.max(DEFAULT_PADDING, line_width / 2.0_f32))
          lower_left = clip_rect.lower_left_x
          height = clip_rect.height

          comb_width = bbox.width / max_len

          (max_len - 1).times do |i|
            contents.move_to(comb_width + comb_width * i, height)
            contents.line_to(comb_width + comb_width * i, lower_left)
          end
          contents.close_and_stroke
        end
      end

      contents.close
      write_to_stream(output.to_slice, appearance_stream)
    end

    # Constructs and sets new contents for given appearance stream.
    private def set_appearance_content(
      widget : Annotation::PDAnnotationWidget,
      appearance_stream : Annotation::PDAppearanceStream,
    ) : Nil
      # first copy any needed resources from the document's DR dictionary into
      # the stream's Resources dictionary
      @default_appearance.copy_needed_resources_to(appearance_stream)

      # then replace the existing contents of the appearance stream from /Tx BMC
      # to the matching EMC
      output = ::IO::Memory.new
      writer = Pdfbox::Pdfwriter::ContentStreamWriter.new(output)

      cos_stream = appearance_stream.require_stream_object
      existing_data = cos_stream.has_data ? cos_stream.create_input_stream.getb_to_end : Bytes.empty
      tokens = Pdfbox::Pdfparser::PDFStreamParser.new(existing_data).parse
      bmc_index = tokens.index(BMC)
      if bmc_index.nil?
        # append to existing stream
        writer.write_tokens(tokens)
        writer.write_tokens(Cos::Name.new("Tx"), BMC)
      else
        # prepend content before BMC
        writer.write_tokens(tokens[0, bmc_index + 1])
      end

      # insert field contents
      insert_generated_appearance(widget, appearance_stream, output)

      emc_index = tokens.index(EMC)
      if emc_index.nil?
        # append EMC
        writer.write_tokens(EMC)
      else
        # append contents after EMC
        writer.write_tokens(tokens[emc_index, tokens.size - emc_index])
      end
      write_to_stream(output.to_slice, appearance_stream)
    end

    # Generate and insert text content and clipping around it.
    private def insert_generated_appearance(
      widget : Annotation::PDAnnotationWidget,
      appearance_stream : Annotation::PDAppearanceStream,
      output : ::IO::Memory,
    ) : Nil
      contents = Pdfbox::Pdmodel::PDAppearanceContentStream.new(appearance_stream, output)

      bbox = resolve_bounding_box(widget, appearance_stream)

      # Acrobat calculates the left and right padding dependent on the offset of the
      # border edge. The minimum distance is always 1f even if there is no rectangle
      # being drawn around.
      border_width = 0.0_f32
      if border_style = widget.border_style
        border_width = border_style.width.to_f32
      end
      padding = Math.max(1.0_f32, border_width)
      clip_rect = apply_padding(bbox, padding)
      clip_rect_lower_left_y = clip_rect.lower_left_y
      clip_rect_height = clip_rect.height

      content_rect = apply_padding(clip_rect, padding)

      contents.save_graphics_state

      # Acrobat always adds a clipping path
      contents.add_rect(clip_rect.lower_left_x, clip_rect_lower_left_y, clip_rect.width, clip_rect_height)
      contents.clip

      # get the font
      font = @default_appearance.font
      if font.nil?
        raise ArgumentError.new("font is null, check whether /DA entry is incomplete or incorrect")
      end
      if font.name.includes?("+")
        Log.warn { "Font '#{@default_appearance.font_name.try(&.value)}' of field '#{@field.fully_qualified_name}' contains subsetted font '#{font.name}'" }
        Log.warn { "This may bring trouble with PDField.setValue(), PDAcroForm.flatten() or PDAcroForm.refreshAppearances()" }
      end

      # calculate the fontSize (because 0 = autosize)
      font_size = @default_appearance.font_size
      font_size = calculate_font_size(font, content_rect) if font_size == 0

      # start the text output
      contents.begin_text

      # write font and color from the /DA string, with the calculated font size
      @default_appearance.write_to(contents, font_size)

      # calculate the y-position of the baseline
      y = 0.0_f32

      # calculate font metrics at font size
      font_scale_y = font_size / FONT_SCALE
      font_bounding_box_at_size = font.bounding_box.height * font_scale_y

      font_cap_at_size = 0.0_f32
      font_descent_at_size = 0.0_f32

      if descriptor = font.font_descriptor
        font_cap_at_size = descriptor.cap_height * font_scale_y
        font_descent_at_size = descriptor.descent * font_scale_y
      else
        font_cap_height = resolve_cap_height(font)
        font_descent = resolve_descent(font)
        Log.debug { "missing font descriptor - resolved Cap/Descent to #{font_cap_height}/#{font_descent}" }
        font_cap_at_size = font_cap_height * font_scale_y
        font_descent_at_size = font_descent * font_scale_y
      end

      if @field.is_a?(PDTextField) && @field.as(PDTextField).multiline?
        y = content_rect.upper_right_y - font_bounding_box_at_size
      else
        # Adobe shows the text 'shifted up' in case the caps don't fit into the clipping area
        if font_cap_at_size > clip_rect_height
          y = clip_rect_lower_left_y + -font_descent_at_size
        else
          # calculate the position based on the content rectangle
          y = clip_rect_lower_left_y + (clip_rect_height - font_cap_at_size) / 2.0_f32

          # check to ensure that ascents and descents fit
          if y - clip_rect_lower_left_y < -font_descent_at_size
            content_rect_lower_left_y = content_rect.lower_left_y
            font_descent_based = -font_descent_at_size + content_rect_lower_left_y
            font_cap_based = content_rect.height - content_rect_lower_left_y - font_cap_at_size

            y = Math.min(font_descent_based, Math.max(y, font_cap_based))
          end
        end
      end

      # show the text
      x = content_rect.lower_left_x

      if shall_comb
        insert_generated_comb_appearance(contents, appearance_stream, font, font_size)
      else
        text_content = Interactive::PlainText.new(@value)
        appearance_style = Interactive::AppearanceStyle.new
        appearance_style.font = font
        appearance_style.font_size = font_size

        # Adobe Acrobat uses the font's bounding box for the leading between the lines
        appearance_style.leading = font.bounding_box.height * font_scale_y

        formatter = Interactive::PlainTextFormatter::Builder.new(contents)
          .style(appearance_style)
          .text(text_content)
          .width(content_rect.width)
          .wrap_lines(is_multi_line)
          .initial_offset(x, y)
          .text_align(get_text_align(widget))
          .build
        formatter.format
      end

      contents.end_text
      contents.restore_graphics_state
      contents.close
    end

    # PDFBox handles a widget with a joined in field dictionary and without an
    # individual name as a widget only. As a result - as a widget can't have a
    # quadding /Q entry we need to do a low level access to the dictionary and
    # otherwise get the quadding from the field.
    private def get_text_align(widget : Annotation::PDAnnotationWidget) : Int32
      # Use quadding value from joined field/widget if set, else use from field.
      widget.cos_object.get_int(Cos::Name.new("Q"), @field.q.to_i64).to_i32
    end

    private def calculate_matrix(bbox : Common::PDRectangle, rotation : Int32) : Util::Matrix
      return Util::Matrix.new if rotation == 0

      tx = 0.0_f32
      ty = 0.0_f32
      case rotation
      when 90
        tx = bbox.upper_right_y
      when 180
        tx = bbox.upper_right_y
        ty = bbox.upper_right_x
      when 270
        ty = bbox.upper_right_x
      end
      Util::Matrix.get_rotate_instance(rotation.to_f64 * Math::PI / 180.0, tx, ty)
    end

    # ameba:disable Naming/PredicateName
    private def is_multi_line : Bool
      @field.is_a?(PDTextField) && @field.as(PDTextField).multiline?
    end

    # Determine if the appearance shall provide a comb output.
    private def shall_comb : Bool
      @field.is_a?(PDTextField) &&
        @field.as(PDTextField).comb? &&
        @field.as(PDTextField).max_length != nil &&
        !@field.as(PDTextField).multiline? &&
        !@field.as(PDTextField).password? &&
        !@field.as(PDTextField).file_select?
    end

    # Generate the appearance for comb fields.
    private def insert_generated_comb_appearance(
      contents : Pdfbox::Pdmodel::PDAppearanceContentStream,
      appearance_stream : Annotation::PDAppearanceStream,
      font : Pdfbox::Pdmodel::Font::PDFont,
      font_size : Float32,
    ) : Nil
      return if @value.nil? || @value.empty?

      max_len = @field.as(PDTextField).max_length || 0
      quadding = @field.q
      num_chars = Math.min(@value.size, max_len)

      b_box = appearance_stream.bbox || Common::PDRectangle.new
      comb_width = b_box.width / max_len
      descriptor = font.font_descriptor || raise ArgumentError.new("font descriptor is null")
      ascent_at_font_size = descriptor.ascent / FONT_SCALE * font_size

      baseline_offset = b_box.lower_left_y + (b_box.height - ascent_at_font_size) / 2.0_f32

      prev_char_width = 0.0_f32

      # set initial offset based on width of first char.
      first_char_width = font.get_string_width(@value[0, 1]) / FONT_SCALE * font_size
      initial_offset = (comb_width - first_char_width) / 2.0_f32

      # add to initial offset if right aligned or centered
      if quadding == 2
        initial_offset = initial_offset + (max_len - num_chars) * comb_width
      elsif quadding == 1
        floored = (max_len - num_chars).to_f64 // 2.0
        initial_offset = initial_offset + floored.to_i32 * comb_width
      end

      x_offset = initial_offset

      num_chars.times do |i|
        comb_string = @value[i, 1]
        curr_char_width = font.get_string_width(comb_string) / FONT_SCALE * font_size / 2.0_f32

        x_offset = x_offset + prev_char_width / 2.0_f32 - curr_char_width / 2.0_f32

        if i == 0
          contents.new_line_at_offset(initial_offset, baseline_offset)
        else
          contents.new_line_at_offset(x_offset, baseline_offset)
        end
        contents.show_text(comb_string)

        baseline_offset = 0.0_f32
        prev_char_width = curr_char_width
        x_offset = comb_width
      end
    end

    # My "not so great" method for calculating the fontsize. It does not work superb,
    # but it handles ok.
    private def calculate_font_size(font : Pdfbox::Pdmodel::Font::PDFont, content_rect : Common::PDRectangle) : Float32
      font_size = @default_appearance.font_size

      # zero is special, it means the text is auto-sized
      if font_size == 0
        if is_multi_line
          text_content = Interactive::PlainText.new(@value)
          unless text_content.paragraphs.empty?
            width = content_rect.width - content_rect.lower_left_x
            fs = MINIMUM_FONT_SIZE
            while fs <= DEFAULT_FONT_SIZE
              # determine the number of lines needed for this font and contentRect
              num_lines = 0
              text_content.paragraphs.each do |paragraph|
                num_lines += paragraph.lines(font, fs, width).size
              end
              # calculate the height required for this font size
              font_scale_y = fs / FONT_SCALE
              leading = font.bounding_box.height * font_scale_y
              height = leading * num_lines

              # if this font size didn't fit, use the prior size that did fit
              if height > content_rect.height
                return Math.max(fs - 1, MINIMUM_FONT_SIZE)
              end
              fs += 1.0_f32
            end
            return Math.min(fs, DEFAULT_FONT_SIZE)
          end

          # Acrobat defaults to 12 for multiline text with size 0
          return DEFAULT_FONT_SIZE
        else
          font_matrix = font.font_matrix
          y_scaling_factor = FONT_SCALE * font_matrix.d
          x_scaling_factor = FONT_SCALE * font_matrix.a

          # fit width
          width = font.get_string_width(@value) * font_matrix.a
          width_based_font_size = content_rect.width / width * x_scaling_factor

          # fit height
          descriptor = font.font_descriptor
          if descriptor
            height = (descriptor.cap_height + -descriptor.descent) * font_matrix.d
            if height <= 0
              height = font.bounding_box.height * font_matrix.d
            end
          else
            height = font.bounding_box.height * font_matrix.d
          end

          height_based_font_size = content_rect.height / height * y_scaling_factor
          if width_based_font_size.infinite?
            # PDFBOX-5763: avoids -Infinity if empty value and tiny rectangle
            return height_based_font_size
          end

          return Math.min(height_based_font_size, width_based_font_size)
        end
      end
      font_size
    end

    # Resolve the cap height. This is a very basic implementation using the height
    # of "H" as reference.
    private def resolve_cap_height(font : Pdfbox::Pdmodel::Font::PDFont) : Float32
      resolve_glyph_height(font, 'H'.ord)
    end

    # Resolve the descent. This is a very basic implementation using the height of
    # "y" - "a" as reference.
    private def resolve_descent(font : Pdfbox::Pdmodel::Font::PDFont) : Float32
      resolve_glyph_height(font, 'y'.ord) - resolve_glyph_height(font, 'a'.ord)
    end

    # Calculate the real (except for type 3 fonts) individual glyph bounds.
    private def resolve_glyph_height(font : Pdfbox::Pdmodel::Font::PDFont, code : Int32) : Float32
      path = resolve_glyph_path(font, code)
      return -1.0_f32 if path.nil?
      path.bounds.height.to_f32
    end

    private def resolve_glyph_path(font : Pdfbox::Pdmodel::Font::PDFont, code : Int32) : Fontbox::Util::Path?
      case font
      when Pdfbox::Pdmodel::Font::PDSimpleFont
        simple_font = font
        # these two lines do not always work, e.g. for the TT fonts in file 032431.pdf
        name = simple_font.encoding.get_name(code)
        path = simple_font.get_path(name)
        path.as?(Fontbox::Util::Path)
      when Pdfbox::Pdmodel::Font::PDVectorFont
        path = font.get_path(code)
        path.as?(Fontbox::Util::Path)
      else
        # shouldn't happen, please open issue in JIRA
        Log.warn { "Unknown font class: #{font.class}" }
        nil
      end
    end

    # Resolve the bounding box.
    private def resolve_bounding_box(
      field_widget : Annotation::PDAnnotationWidget,
      appearance_stream : Annotation::PDAppearanceStream,
    ) : Common::PDRectangle
      bounding_box = appearance_stream.bbox
      if bounding_box.nil?
        if rect = field_widget.rectangle
          bounding_box = rect.create_retranslated_rectangle
        else
          bounding_box = Common::PDRectangle.new
        end
      end
      bounding_box
    end

    # Apply padding to a box.
    private def apply_padding(box : Common::PDRectangle, padding : Float32) : Common::PDRectangle
      Common::PDRectangle.new(
        box.lower_left_x + padding,
        box.lower_left_y + padding,
        box.width - 2 * padding,
        box.height - 2 * padding
      )
    end

    # Writes the stream to the actual stream in the COSStream.
    private def write_to_stream(data : Bytes, appearance_stream : Annotation::PDAppearanceStream) : Nil
      cos_stream = appearance_stream.require_stream_object
      cos_stream.data = data
      cos_stream.set_int(Cos::Name::LENGTH, data.size)
    end
  end
end
