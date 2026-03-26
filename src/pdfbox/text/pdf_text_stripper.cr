# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "../pdmodel"
require "../pdmodel/document"
require "../pdmodel/font"
require "./text_position"
require "../contentstream/legacy_pdf_stream_engine"

module Pdfbox::Text
  # This class will take a pdf document and strip out all of the text and ignore the formatting and such.
  # Corresponds to org.apache.pdfbox.text.PDFTextStripper in Apache PDFBox.
  class PDFTextStripper < Contentstream::LegacyPDFStreamEngine
    Log = ::Log.for(self)

    @output : ::IO::Memory?
    @document : Pdfbox::Pdmodel::Document?
    @current_page_no : Int32 = 1
    @line_separator : String = "\n"
    @page_start : String = ""
    @paragraph_end : String = ""
    @article_start : String = ""
    @article_end : String = ""
    @add_more_formatting : Bool = false
    @start_bookmark : Pdfbox::Pdmodel::Page? = nil
    @end_bookmark : Pdfbox::Pdmodel::Page? = nil
    @start_page_number : Int32 = 1
    @end_page_number : Int32 = -1
    @text_positions : Array(TextPosition) = [] of TextPosition
    @word_separator : String = " "
    @spacing_tolerance : Float32 = 0.5_f32
    @average_char_tolerance : Float32 = 0.3_f32
    @sort_by_position : Bool = false
    @suppress_duplicate_overlapping_text : Bool = true
    @character_list_mapping = {} of String => Array({Float32, Float32})

    # Get the text from a PDF document
    #
    # @param doc The document to extract text from
    # @return The extracted text
    def get_text(doc : Pdfbox::Pdmodel::Document) : String
      output = ::IO::Memory.new
      write_text(doc, output)
      output.to_s
    end

    # Write text from a PDF document to an output stream
    #
    # @param doc The document to extract text from
    # @param output_stream The output stream to write to
    def write_text(doc : Pdfbox::Pdmodel::Document, output_stream : ::IO) : Nil
      reset_engine
      @document = doc
      @output = output_stream.as(::IO::Memory?)

      if @add_more_formatting
        @paragraph_end = @line_separator
        @page_start = @line_separator
        @article_start = @line_separator
        @article_end = @line_separator
      end

      start_document(doc)
      process_pages(doc.pages)
      end_document(doc)
    end

    # Process all pages in the document
    def process_pages(pages : Pdfbox::Pdmodel::PDPageTree) : Nil
      # Calculate start and end bookmark page numbers
      start_bookmark_page = @start_bookmark
      if start_bookmark_page
        # TODO: Find page number in tree
      end

      end_bookmark_page = @end_bookmark
      if end_bookmark_page
        # TODO: Find page number in tree
      end

      pages.each do |page|
        process_page(page)
      end
    end

    # Process all pages from an array
    def process_pages(pages : Array(Pdfbox::Pdmodel::Page)) : Nil
      pages.each do |page|
        process_page(page)
      end
    end

    # Process a single page
    #
    # @param page The page to process
    def process_page(page : Pdfbox::Pdmodel::Page) : Nil
      @current_page_no += 1

      # Check if we should process this page based on page number range
      if @start_page_number > 0 && @current_page_no < @start_page_number
        return
      end

      if @end_page_number > 0 && @current_page_no > @end_page_number
        return
      end

      # Clear text positions for new page
      @text_positions.clear

      # Process the page content using the parent engine
      super(page)

      # Write collected text positions to output
      output = @output
      if output
        output << render_text_positions(@text_positions)
      end
    end

    # Override process_text_position to collect text positions
    def process_text_position(text : TextPosition) : Nil
      return if suppress_duplicate_overlapping_text?(text)
      @text_positions << text
    end

    # Called at the start of document processing
    def start_document(doc : Pdfbox::Pdmodel::Document) : Nil
    end

    # Called at the end of document processing
    def end_document(doc : Pdfbox::Pdmodel::Document) : Nil
    end

    private def reset_engine
      @current_page_no = 0
      @document = nil
      @text_positions.clear
      @character_list_mapping.clear
    end

    def suppress_duplicate_overlapping_text=(value : Bool) : Bool
      @suppress_duplicate_overlapping_text = value
    end

    def line_separator=(value : String) : String
      @line_separator = value
    end

    def sort_by_position=(value : Bool) : Bool
      @sort_by_position = value
    end

    def sort_by_position? : Bool
      @sort_by_position
    end

    private def suppress_duplicate_overlapping_text?(text : TextPosition) : Bool
      return false unless @suppress_duplicate_overlapping_text

      text_character = text.unicode
      return false if text_character.empty?

      char_count = text_character.size
      char_count = 1 if char_count <= 0
      tolerance = text.width / char_count / 3.0_f32

      same_text_characters = @character_list_mapping[text_character]? || [] of {Float32, Float32}
      same_text_characters.each do |(x, y)|
        if (text.x - x).abs <= tolerance && (text.y - y).abs <= tolerance
          return true
        end
      end

      same_text_characters << {text.x, text.y}
      @character_list_mapping[text_character] = same_text_characters
      false
    end

    private def normalize_extracted_text(text : String) : String
      String.build do |io|
        token = String::Builder.new
        in_whitespace = nil

        flush = -> do
          value = token.to_s
          unless value.empty?
            io << if in_whitespace == true
              value
            else
              normalize_word(value)
            end
          end
          token = String::Builder.new
        end

        text.each_char do |char|
          whitespace = char.whitespace?
          if in_whitespace.nil?
            in_whitespace = whitespace
          elsif in_whitespace != whitespace
            flush.call
            in_whitespace = whitespace
          end
          token << char
        end

        flush.call
      end
    end

    private def normalize_line_text(text : String) : String
      normalized = text.gsub("Ãá", "«").gsub("Ãà", "»")
      tokens = normalized.scan(/\s+|\S+/).map(&.[0])
      suffix_start = bidi_suffix_start(tokens)
      return normalized.strip if suffix_start <= 0 || suffix_start >= tokens.size

      prefix = tokens[0, suffix_start].join
      suffix = reorder_bidi_suffix(tokens[suffix_start..])
      separator = if !prefix.empty? && !suffix.empty? && !prefix[-1].whitespace? && !suffix[0].whitespace?
                    " "
                  else
                    ""
                  end
      (prefix + separator + suffix).strip
    end

    private def build_lines(text_positions : Array(TextPosition)) : Array(Array(TextPosition))
      lines = [] of Array(TextPosition)

      text_positions.each do |text_pos|
        current_line = lines.last?
        if current_line && same_line?(current_line.first, text_pos)
          current_line << text_pos
        else
          lines << [text_pos]
        end
      end

      lines
    end

    private def quantize_y(y : Float32) : Int32
      (y * 10).round.to_i
    end

    private def same_line?(reference : TextPosition, candidate : TextPosition) : Bool
      delta_y = (reference.y - candidate.y).abs
      tolerance = {reference.height, candidate.height, 5.0_f32}.max * 0.25_f32
      delta_y <= tolerance
    end

    private def sort_text_positions!(text_positions : Array(TextPosition)) : Nil
      sorted = stable_merge_sort(text_positions)
      text_positions.clear
      text_positions.concat(sorted)
      remove_contained_spaces(text_positions)
    end

    private def stable_merge_sort(text_positions : Array(TextPosition)) : Array(TextPosition)
      size = text_positions.size
      return text_positions.dup if size <= 1

      midpoint = size // 2
      left = stable_merge_sort(text_positions[0, midpoint])
      right = stable_merge_sort(text_positions[midpoint, size - midpoint])
      merge_text_positions(left, right)
    end

    private def merge_text_positions(left : Array(TextPosition), right : Array(TextPosition)) : Array(TextPosition)
      merged = Array(TextPosition).new(left.size + right.size)
      left_index = 0
      right_index = 0

      while left_index < left.size && right_index < right.size
        if compare_text_positions(left[left_index], right[right_index]) <= 0
          merged << left[left_index]
          left_index += 1
        else
          merged << right[right_index]
          right_index += 1
        end
      end

      while left_index < left.size
        merged << left[left_index]
        left_index += 1
      end

      while right_index < right.size
        merged << right[right_index]
        right_index += 1
      end

      merged
    end

    private def float_compare(left : Float32, right : Float32) : Int32
      return 0 if left == right
      return 1 if left.nan?
      return -1 if right.nan?

      if left < right
        -1
      else
        1
      end
    end

    private def compare_text_positions(left : TextPosition, right : TextPosition) : Int32
      cmp = float_compare(left.dir, right.dir)
      return cmp if cmp != 0

      left_y_bottom = left.y_dir_adj
      right_y_bottom = right.y_dir_adj
      left_y_top = left_y_bottom - left.height_dir
      right_y_top = right_y_bottom - right.height_dir
      y_difference = (left_y_bottom - right_y_bottom).abs

      if y_difference < 0.1_f32 ||
         (right_y_bottom >= left_y_top && right_y_bottom <= left_y_bottom) ||
         (left_y_bottom >= right_y_top && left_y_bottom <= right_y_bottom)
        0
      elsif left_y_bottom < right_y_bottom
        -1
      else
        1
      end
    end

    private def remove_contained_spaces(text_positions : Array(TextPosition)) : Nil
      return if text_positions.empty?

      filtered = [] of TextPosition
      previous_position = text_positions.first
      filtered << previous_position

      text_positions.each_with_index do |position, index|
        next if index == 0

        if position.unicode == " " && previous_position.completely_contains(position)
          next
        end

        filtered << position
        previous_position = position
      end

      text_positions.clear
      text_positions.concat(filtered)
    end

    private def overlap?(y1 : Float32, height1 : Float32, y2 : Float32, height2 : Float32) : Bool
      within?(y1, y2, 0.1_f32) ||
        (y2 <= y1 && y2 >= y1 - height1) ||
        (y1 <= y2 && y1 >= y2 - height2)
    end

    private def within?(first : Float32, second : Float32, variance : Float32) : Bool
      (first - second).abs <= variance
    end

    protected def render_text_positions(text_positions : Array(TextPosition)) : String
      sort_text_positions!(text_positions) if @sort_by_position

      String.build do |io|
        build_lines(text_positions).each do |line|
          line_text = String.build do |line_io|
            previous = nil.as(TextPosition?)
            previous_average_char_width = -1.0_f32

            line.each do |text_pos|
              if previous && word_break?(previous, text_pos, previous_average_char_width)
                line_io << @word_separator
              end
              line_io << text_pos.visually_ordered_unicode
              previous_average_char_width = average_char_width(text_pos, previous_average_char_width)
              previous = text_pos
            end
          end
          io << normalize_line_text(normalize_extracted_text(line_text))
          io << @line_separator
        end
      end
    end

    protected def collected_text_positions : Array(TextPosition)
      @text_positions
    end

    protected def line_groups_for(text_positions : Array(TextPosition)) : Array(Array(TextPosition))
      build_lines(text_positions)
    end

    protected def ordered_text_positions(text_positions : Array(TextPosition)) : Array(TextPosition)
      return text_positions.dup unless @sort_by_position
      stable_merge_sort(text_positions)
    end

    private def average_char_width(text_pos : TextPosition, previous_average : Float32) : Float32
      char_count = text_pos.unicode.size
      char_count = 1 if char_count <= 0
      current_average = text_pos.width / char_count
      return current_average if previous_average < 0
      (previous_average + current_average) / 2.0_f32
    end

    private def word_break?(previous : TextPosition, current : TextPosition, previous_average_char_width : Float32) : Bool
      word_spacing = current.width_of_space
      delta_space = if word_spacing == 0 || word_spacing.nan?
                      Float32::MAX
                    else
                      word_spacing * @spacing_tolerance
                    end
      delta_char_width = average_char_width(current, previous_average_char_width) * @average_char_tolerance
      expected_start = previous.end_x + Math.min(delta_space, delta_char_width)
      expected_start < current.x &&
        !previous.unicode.ends_with?(@word_separator) &&
        !current.unicode.starts_with?(@word_separator)
    end

    private def normalize_word(word : String) : String
      builder = nil.as(String::Builder?)
      start_index = 0
      byte_offset = 0

      word.each_char do |char|
        codepoint = char.ord
        unless presentation_form_codepoint?(codepoint)
          byte_offset += char.bytesize
          next
        end

        builder ||= String::Builder.new(word.size * 2)
        if current = builder
          current << word.byte_slice(0, start_index) if start_index == 0 && byte_offset > 0

          normalized = char.to_s.unicode_normalize(:nfkc).strip
          normalized = normalized.reverse if codepoint >= 0xFB1D && normalized.size > 1
          current << normalized
        end
        start_index = byte_offset + char.bytesize
        byte_offset = start_index
      end

      normalized_word = if builder
                          builder << word.byte_slice(start_index)
                          builder.to_s
                        else
                          word
                        end

      handle_direction(normalized_word)
    end

    private def handle_direction(word : String) : String
      has_rtl = word.each_char.any? { |char| rtl_codepoint?(char.ord) }
      return word unless has_rtl

      runs = [] of Tuple(Symbol, String)
      current_kind = nil.as(Symbol?)
      current = String::Builder.new

      flush = -> do
        if kind = current_kind
          value = current.to_s
          runs << {kind, value} unless value.empty?
        end
        current = String::Builder.new
      end

      word.each_char do |char|
        kind = bidi_run_kind(char)
        if current_kind && current_kind != kind
          flush.call
        end
        current_kind = kind
        current << char
      end
      flush.call

      if runs.size == 1 && runs[0][0] == :rtl
        return runs[0][1].reverse
      end

      String.build do |io|
        runs.reverse_each do |kind, text|
          io << if kind == :rtl
            text.reverse
          elsif kind == :neutral
            mirror_text(text)
          else
            text
          end
        end
      end
    end

    private def bidi_run_kind(char : Char) : Symbol
      codepoint = char.ord
      return :rtl if rtl_codepoint?(codepoint) && !char.number?
      return :ltr if char.ascii_letter? || char.number?
      :neutral
    end

    private def bidi_suffix_start(tokens : Array(String)) : Int32
      seen_bidi = false
      index = tokens.size - 1

      while index >= 0
        token = tokens[index]
        if whitespace_token?(token)
          index -= 1
          next
        end
        if bidi_related_token?(token)
          seen_bidi = true
          index -= 1
          next
        end
        break
      end

      return tokens.size unless seen_bidi

      start_index = index + 1
      if start_index > 0 && whitespace_token?(tokens[start_index - 1])
        start_index -= 1
      end
      start_index
    end

    private def reorder_bidi_suffix(tokens : Array(String)) : String
      parts = collect_bidi_suffix_parts(tokens)
      return tokens.join.strip if parts.words.size <= 1

      result = String.build do |io|
        io << parts.leading_space if parts.leading_space
        io << parts.opener if parts.opener
        append_reordered_words(io, parts.words, parts.spaces)
      end

      parts.closer ? result.rstrip + parts.closer.to_s : result
    end

    private record BidiSuffixParts,
      words : Array(String),
      spaces : Array(String),
      leading_space : String?,
      opener : Char?,
      closer : Char?

    private def collect_bidi_suffix_parts(tokens : Array(String)) : BidiSuffixParts
      words = [] of String
      spaces = [] of String
      opener = nil.as(Char?)
      closer = nil.as(Char?)
      leading_space = nil.as(String?)
      skipped_leading_space = false

      tokens.each_with_index do |token, index|
        if whitespace_token?(token)
          leading_space, skipped_leading_space = collect_bidi_space_token(
            token, index, words.empty?, opener, leading_space, skipped_leading_space, spaces
          )
          next
        end

        if opener.nil? && standalone_opener_token?(token)
          opener = token[0]
          next
        end

        transformed, closer = transform_bidi_suffix_word(token, opener, closer)
        words << transformed
      end

      BidiSuffixParts.new(words, spaces, leading_space, opener, closer)
    end

    private def collect_bidi_space_token(token : String, index : Int32, words_empty : Bool, opener : Char?,
                                         leading_space : String?, skipped_leading_space : Bool,
                                         spaces : Array(String)) : {String?, Bool}
      if words_empty && opener.nil?
        return {leading_space || token, skipped_leading_space}
      end

      if opener && !skipped_leading_space && index == 1
        return {leading_space, true}
      end

      spaces << token
      {leading_space, skipped_leading_space}
    end

    private def transform_bidi_suffix_word(token : String, opener : Char?, closer : Char?) : {String, Char?}
      return {token, closer} unless opener && token.size > 1 && token[0] == opener && token_has_rtl?(token)

      transformed = token.byte_slice(token[0].bytesize)
      {transformed, mirrored_char(opener)}
    end

    private def append_reordered_words(io : ::IO, words : Array(String), spaces : Array(String)) : Nil
      reversed_words = words.reverse
      reversed_spaces = spaces.reverse
      reversed_words.each_with_index do |word, index|
        io << word
        io << reversed_spaces[index] if index < reversed_spaces.size
      end
    end

    private def whitespace_token?(token : String) : Bool
      token.each_char.all?(&.whitespace?)
    end

    private def bidi_related_token?(token : String) : Bool
      token_has_rtl?(token) || standalone_opener_token?(token)
    end

    private def token_has_rtl?(token : String) : Bool
      token.each_char.any? { |char| rtl_codepoint?(char.ord) }
    end

    private def standalone_opener_token?(token : String) : Bool
      token.size == 1 && opener_char?(token[0])
    end

    private def opener_char?(char : Char) : Bool
      case char
      when '(', '[', '{', '<', '«'
        true
      else
        false
      end
    end

    private def mirror_text(text : String) : String
      String.build do |io|
        text.each_char.to_a.reverse_each do |char|
          io << mirrored_char(char)
        end
      end
    end

    private def mirrored_char(char : Char) : Char
      case char
      when '(' then ')'
      when ')' then '('
      when '[' then ']'
      when ']' then '['
      when '{' then '}'
      when '}' then '{'
      when '<' then '>'
      when '>' then '<'
      when '«' then '»'
      when '»' then '«'
      else          char
      end
    end

    private def presentation_form_codepoint?(codepoint : Int32) : Bool
      (0xFB00 <= codepoint && codepoint <= 0xFDFF) ||
        (0xFE70 <= codepoint && codepoint <= 0xFEFF)
    end

    private def rtl_codepoint?(codepoint : Int32) : Bool
      (0x0590 <= codepoint && codepoint <= 0x08FF) ||
        (0xFB1D <= codepoint && codepoint <= 0xFDFF) ||
        (0xFE70 <= codepoint && codepoint <= 0xFEFF)
    end
  end

  # Position wrapper class to track text positions with flags
  class PositionWrapper
    @is_line_start : Bool = false
    @is_paragraph_start : Bool = false
    @is_page_break : Bool = false
    @is_hanging_indent : Bool = false
    @is_article_start : Bool = false
    @position : TextPosition?

    def initialize(@position : TextPosition? = nil)
    end

    def text_position : TextPosition?
      @position
    end

    def line_start? : Bool
      @is_line_start
    end

    def set_line_start : Nil
      @is_line_start = true
    end

    def paragraph_start? : Bool
      @is_paragraph_start
    end

    def set_paragraph_start : Nil
      @is_paragraph_start = true
    end

    def page_break? : Bool
      @is_page_break
    end

    def set_page_break : Nil
      @is_page_break = true
    end

    def hanging_indent? : Bool
      @is_hanging_indent
    end

    def set_hanging_indent : Nil
      @is_hanging_indent = true
    end

    def article_start? : Bool
      @is_article_start
    end

    def set_article_start : Nil
      @is_article_start = true
    end
  end

  # Word with text positions
  class WordWithTextPositions
    getter text : String
    getter text_positions : Array(TextPosition)

    def initialize(@text : String, @text_positions : Array(TextPosition))
    end
  end
end
