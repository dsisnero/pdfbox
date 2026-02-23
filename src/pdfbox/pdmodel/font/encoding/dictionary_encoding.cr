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

require "../encoding"

module Pdfbox::Pdmodel::Font
  # This will perform the encoding from a dictionary.
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.DictionaryEncoding in Apache PDFBox.
  class DictionaryEncoding < Encoding
    # Singleton instance? Not used; this class is instantiated per font encoding.

    @encoding : Cos::Dictionary
    @base_encoding : Encoding?
    @differences : Hash(Int32, String)

    # Creates a new DictionaryEncoding from a PDF.
    #
    # @param font_encoding The encoding dictionary.
    # @param is_non_symbolic True if the font is non-symbolic. False for Type 3 fonts.
    # @param built_in The font's built-in encoding. Nil for Type 3 fonts.
    def initialize(font_encoding : Cos::Dictionary, is_non_symbolic : Bool, built_in : Encoding?)
      @encoding = font_encoding
      @differences = Hash(Int32, String).new

      base = nil
      has_base_encoding = @encoding.has_key?(Cos::Name::BASE_ENCODING)
      if has_base_encoding
        name = get_cos_name(Cos::Name::BASE_ENCODING)
        base = Encoding.get_instance(name) if name
      end

      if base.nil?
        if is_non_symbolic
          # Otherwise, for a nonsymbolic font, it is StandardEncoding
          base = StandardEncoding::INSTANCE
        else
          # and for a symbolic font, it is the font's built-in encoding.
          if built_in
            base = built_in
          else
            # triggering this error indicates a bug in PDFBox. Every font should always have
            # a built-in encoding, if not, we parsed it incorrectly.
            raise ArgumentError.new("Symbolic fonts must have a built-in encoding")
          end
        end
      end
      @base_encoding = base

      # Copy mappings from base encoding
      base_map = base.get_code_to_name_map
      base_map.each do |code, name|
        add(code, name)
      end

      apply_differences
    end

    # Helper to get a Cos::Name from the dictionary, dereferencing COSObject wrappers.
    private def get_cos_name(key : Cos::Name) : Cos::Name?
      entry = @encoding[key]
      # Dereference COSObject
      while entry.is_a?(Cos::Object)
        entry = entry.object
      end
      # COSNull treated as nil
      return if entry.nil? || entry.is_a?(Cos::Null)
      entry.as?(Cos::Name)
    end

    # Helper to get a Cos::Array from the dictionary, dereferencing COSObject wrappers.
    private def get_cos_array(key : Cos::Name) : Cos::Array?
      entry = @encoding[key]
      while entry.is_a?(Cos::Object)
        entry = entry.object
      end
      return if entry.nil? || entry.is_a?(Cos::Null)
      entry.as?(Cos::Array)
    end

    private def apply_differences : Nil
      diff_array = get_cos_array(Cos::Name::DIFFERENCES)
      return unless diff_array

      current_index = -1
      diff_array.size.times do |i|
        next_item = diff_array[i]
        # Dereference COSObject
        while next_item.is_a?(Cos::Object)
          next_item = next_item.object
        end
        if next_item.is_a?(Cos::Integer) || next_item.is_a?(Cos::Float)
          # PDF spec says differences array contains integer numbers, but we accept float too
          current_index = next_item.value.to_i
        elsif next_item.is_a?(Cos::Name)
          name = next_item
          overwrite(current_index, name.value)
          @differences[current_index] = name.value
          current_index += 1
        end
      end
    end

    # Returns the base encoding. Will be nil for Type 3 fonts.
    #
    # @return the base encoding or nil
    def base_encoding : Encoding?
      @base_encoding
    end

    # Returns the Differences array.
    #
    # @return a hash containing all differences
    def differences : Hash(Int32, String)
      @differences
    end

    # Convert this standard java object to a COS object.
    #
    # @return The cos object that matches this Java object.
    def cos_object : Cos::Base
      @encoding
    end

    # Returns the name of this encoding.
    #
    # @return the name of the encoding
    def get_encoding_name : String
      if base = @base_encoding
        base.get_encoding_name + " with differences"
      else
        "differences"
      end
    end
  end
end
