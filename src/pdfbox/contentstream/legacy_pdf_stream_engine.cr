# Legacy PDF Stream Engine for PDFBox Crystal
#
# This class exists only so that we don't break the code of users who have their own subclasses of
# PDFTextStripper. It replaces the mostly empty implementation of showGlyph() in PDFStreamEngine
# with a heuristic implementation which is backwards compatible.
#
# DO NOT USE THIS CODE UNLESS YOU ARE WORKING WITH PDFTextStripper.
# THIS CODE IS DELIBERATELY INCORRECT, USE PDFStreamEngine INSTEAD.
#
# Corresponds to org.apache.pdfbox.text.LegacyPDFStreamEngine in Apache PDFBox.

require "./pdf_stream_engine"
require "../text/text_position"
require "../pdmodel/font/encoding/glyph_list"
require "../util"

module Pdfbox::Contentstream
  # Legacy text calculations which are known to be incorrect but are depended on by PDFTextStripper.
  class LegacyPDFStreamEngine < PDFStreamEngine
    Log = ::Log.for(self)

    @page_rotation : Int32 = 0
    @page_size : Pdmodel::Rectangle?
    @translate_matrix : Util::Matrix?
    @font_height_map = {} of Cos::Dictionary => Float64

    # Constructor
    def initialize
      super
      # Add operators for text processing
      # In a full implementation, this would add all the operators
    end

    # Process a page
    def process_page(page : Pdmodel::Page) : Nil
      @page_rotation = page.rotation
      @page_size = page.crop_box || page.media_box

      page_size = @page_size
      if page_size
        lower_left_x = page_size.lower_left_x
        lower_left_y = page_size.lower_left_y
        if lower_left_x == 0 && lower_left_y == 0
          @translate_matrix = nil
        else
          # Translation matrix for cropbox
          @translate_matrix = Util::Matrix.translate(-lower_left_x.to_f32, -lower_left_y.to_f32)
        end
      end

      super(page)
    end

    # Called when a glyph is to be processed. The heuristic calculations here were originally
    # written by Ben Litchfield for PDFStreamEngine.
    def show_glyph(text_rendering_matrix : Util::Matrix, font : Pdmodel::Font::PDFont, code : Int32, displacement : Pdmodel::Font::PDFont::Vector) : Nil
      #
      # Legacy calculations which were previously in PDFStreamEngine
      #
      # DO NOT USE THIS CODE UNLESS YOU ARE WORKING WITH PDFTextStripper.
      # THIS CODE IS DELIBERATELY INCORRECT
      #

      state = graphics_state
      ctm = state.current_transformation_matrix
      font_size = state.font_size
      horizontal_scaling = state.horizontal_scaling / 100.0
      text_matrix = self.text_matrix

      displacement_x = displacement.x
      # The sorting algorithm is based on the width of the character. As the displacement
      # for vertical characters doesn't provide any suitable value for it, we have to
      # calculate our own
      if font.vertical?
        displacement_x = font.width(code) / 1000.0
        # There may be an additional scaling factor for true type fonts
        # Simplified implementation - skip TTF scaling for now
      end

      #
      # Legacy calculations which were previously in PDFStreamEngine
      #
      # DO NOT USE THIS CODE UNLESS YOU ARE WORKING WITH PDFTextStripper.
      # THIS CODE IS DELIBERATELY INCORRECT
      #

      # (modified) combined displacement, this is calculated *without* taking the character
      # spacing and word spacing into account, due to legacy code in TextStripper
      tx = (displacement_x * font_size * horizontal_scaling).to_f32
      ty = (displacement.y * font_size).to_f32

      # (modified) combined displacement matrix
      td = Util::Matrix.translate(tx, ty)

      # (modified) text rendering matrix
      next_text_rendering_matrix = td.multiply(text_matrix).multiply(ctm) # text space -> device space
      next_x = next_text_rendering_matrix.translate_x
      next_y = next_text_rendering_matrix.translate_y

      # (modified) width and height calculations
      dx_display = next_x - text_rendering_matrix.translate_x
      font_height = @font_height_map[font.cos_object]?
      unless font_height
        font_height = compute_font_height(font)
        @font_height_map[font.cos_object] = font_height
      end
      dy_display = font_height * text_rendering_matrix.scaling_factor_y

      #
      # Start of the original method
      #

      # Note on variable names. There are three different units being used in this code.
      # Character sizes are given in glyph units, text locations are initially given in text
      # units, and we want to save the data in display units. The variable names should end with
      # Text or Disp to represent if the values are in text or disp units (no glyph units are
      # saved).

      glyph_space_to_text_space_factor = 1.0 / 1000.0
      if font.is_a?(Pdmodel::Font::PDType3Font)
        glyph_space_to_text_space_factor = font.font_matrix.scale_x
      end

      space_width_text = 0.0
      begin
        # To avoid crash as described in PDFBOX-614, see what the space displacement should be
        space_width_text = font.space_width * glyph_space_to_text_space_factor
      rescue ex
        Log.warn { ex.message }
      end

      if space_width_text == 0
        space_width_text = font.average_font_width * glyph_space_to_text_space_factor
        # The average space width appears to be higher than necessary so make it smaller
        space_width_text *= 0.80
      end
      if space_width_text == 0
        space_width_text = 1.0 # If could not find font, use a generic value
      end

      # The space width has to be transformed into display units
      space_width_display = space_width_text * text_rendering_matrix.scaling_factor_x

      # Use our additional glyph list for Unicode mapping
      glyph_list = Pdmodel::Font::GlyphList.adobe_glyph_list
      unicode = font.to_unicode(code, glyph_list)

      # When there is no Unicode mapping available, Acrobat simply coerces the character code
      # into Unicode, so we do the same. Subclasses of PDFStreamEngine don't necessarily want
      # this, which is why we leave it until this point in PDFTextStreamEngine.
      if unicode.nil?
        if font.is_a?(Pdmodel::Font::PDSimpleFont)
          unicode = code.chr.to_s
        else
          # Acrobat doesn't seem to coerce composite font's character codes, instead it
          # skips them. See the "allah2.pdf" TestTextStripper file.
          return
        end
      end

      # Adjust for cropbox if needed
      translate_matrix = @translate_matrix
      page_size = @page_size
      translated_text_rendering_matrix = if translate_matrix.nil?
                                           text_rendering_matrix
                                         else
                                           return text_rendering_matrix unless page_size
                                           next_x -= page_size.lower_left_x.to_f32
                                           next_y -= page_size.lower_left_y.to_f32
                                           Util::Matrix.concatenate(translate_matrix, text_rendering_matrix)
                                         end

      if page_size
        process_text_position(Text::TextPosition.new(
          @page_rotation,
          page_size.width.to_f32,
          page_size.height.to_f32,
          translated_text_rendering_matrix,
          next_x.to_f32,
          next_y.to_f32,
          dy_display.abs.to_f32,
          dx_display.to_f32,
          space_width_display.abs.to_f32,
          unicode || "",
          [code],
          font,
          font_size.to_f32,
          (font_size * text_matrix.scaling_factor_x).to_i32
        ))
      end
    end

    # Compute the font height. Override this if you want to use own calculations.
    def compute_font_height(font : Pdmodel::Font::PDFont) : Float64
      bbox = font.bounding_box
      if bbox.lower_left_y < -32768
        # PDFBOX-2158 and PDFBOX-3130
        bbox = Pdmodel::Font::PDFont::BoundingBox.new(
          bbox.lower_left_x,
          -(bbox.lower_left_y + 65536),
          bbox.upper_right_x,
          bbox.upper_right_y
        )
      end

      # 1/2 the bbox is used as the height todo: why?
      glyph_height = bbox.height / 2.0

      # Sometimes the bbox has very high values, but CapHeight is OK
      font_descriptor = font.font_descriptor
      if font_descriptor
        cap_height = font_descriptor.cap_height
        if cap_height != 0 && (cap_height < glyph_height || glyph_height == 0)
          glyph_height = cap_height.to_f
        end

        # PDFBOX-3464, PDFBOX-4480, PDFBOX-4553:
        # Sometimes even CapHeight has very high value, but Ascent and Descent are ok
        ascent = font_descriptor.ascent
        descent = font_descriptor.descent
        if cap_height > ascent && ascent > 0 && descent < 0 &&
           ((ascent - descent) / 2 < glyph_height || glyph_height == 0)
          glyph_height = (ascent - descent) / 2
        end
      end

      # TransformPoint from glyph space -> text space
      height : Float64 = if font.is_a?(Pdmodel::Font::PDType3Font)
        font.font_matrix.transform_point(0.0, glyph_height.to_f64).y.to_f64
      else
        glyph_height / 1000.0
      end

      height
    end

    # A method provided as an event interface to allow a subclass to perform some specific
    # functionality when text needs to be processed.
    def process_text_position(text : Text::TextPosition) : Nil
      # Subclasses can override to provide specific functionality
    end
  end
end
