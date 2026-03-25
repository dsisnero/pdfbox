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
        raw_text = String.build do |io|
          @text_positions.each do |text_pos|
            io << text_pos.unicode
          end
        end
        output << normalize_extracted_text(raw_text)
        output << @line_separator
      end
    end

    # Override process_text_position to collect text positions
    def process_text_position(text : TextPosition) : Nil
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
      has_ltr = word.each_char.any? { |char| char.ascii_letter? || char.number? }
      return word unless has_rtl
      return word if has_ltr

      word.reverse
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
