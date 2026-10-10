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

require "../contentstream/legacy_pdf_stream_engine"
require "../pdmodel/document_interchange/marked_content/pd_marked_content"
require "./text_position"

module Pdfbox::Text
  # A stream engine that extracts the marked-content sequences of a page.
  # Port of Apache PDFBox text/PDFMarkedContentExtractor.
  class PDFMarkedContentExtractor < Pdfbox::Contentstream::LegacyPDFStreamEngine
    @suppress_duplicate_overlapping_text = true
    @marked_contents = [] of Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent
    @current_marked_contents = [] of Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent
    @character_list_mapping = {} of String => Array(TextPosition)

    def suppress_duplicate_overlapping_text? : Bool
      @suppress_duplicate_overlapping_text
    end

    def suppress_duplicate_overlapping_text=(value : Bool) : Bool
      @suppress_duplicate_overlapping_text = value
    end

    # Java PDFMarkedContentExtractor#beginMarkedContentSequence.
    def begin_marked_content_sequence(tag : Cos::Name? = nil, properties : Cos::Base? = nil) : Nil
      marked_content = Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent.create(
        tag, properties.as?(Cos::Dictionary)
      )
      if @current_marked_contents.empty?
        @marked_contents << marked_content
      else
        @current_marked_contents.last.add_marked_content(marked_content)
      end
      @current_marked_contents << marked_content
    end

    # Java PDFMarkedContentExtractor#endMarkedContentSequence.
    def end_marked_content_sequence : Nil
      @current_marked_contents.pop? unless @current_marked_contents.empty?
    end

    # Java PDFMarkedContentExtractor#markedContentPoint.
    def marked_content_point(tag : Cos::Name, properties : Cos::Base?) : Nil
      super
    end

    # Java PDFMarkedContentExtractor#xobject: attach the XObject to the current
    # marked-content sequence.
    def add_x_object(xobject : Cos::Base) : Nil
      @current_marked_contents.last.add_x_object(xobject) unless @current_marked_contents.empty?
    end

    # Java PDFMarkedContentExtractor#processTextPosition.
    def process_text_position(text : TextPosition) : Nil
      show_character = true
      if @suppress_duplicate_overlapping_text
        show_character = false
        unicode = text.unicode
        same_text_characters = @character_list_mapping[unicode] ||= [] of TextPosition
        tolerance = (text.width / [unicode.size, 1].max) / 3.0_f32
        suppress_character = same_text_characters.any? do |same|
          within(same.x, text.x, tolerance) && within(same.y, text.y, tolerance)
        end
        unless suppress_character
          same_text_characters << text
          show_character = true
        end
      end

      if show_character && !@current_marked_contents.empty?
        @current_marked_contents.last.add_text(text)
      end
    end

    # Java PDFMarkedContentExtractor#getMarkedContents.
    def get_marked_contents : Array(Pdfbox::Pdmodel::DocumentInterchange::MarkedContent::PDMarkedContent) # ameba:disable Naming/AccessorMethodName
      @marked_contents
    end

    private def within(first : Float32, second : Float32, variance : Float32) : Bool
      second > first - variance && second < first + variance
    end
  end
end
