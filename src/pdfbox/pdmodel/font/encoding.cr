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

require "../common/cos_objectable"

module Pdfbox::Pdmodel::Font
  # A PostScript encoding vector, maps character codes to glyph names.
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.Encoding in Apache PDFBox.
  module Encoding
    abstract class Encoding
      include Common::COSObjectable

      private CHAR_CODE = 0
      private CHAR_NAME = 1

      # This will get an encoding by name. May return nil.
      #
      # @param name The name of the encoding to get.
      # @return The encoding that matches the name.
      def self.get_instance(name : Cos::Name) : Encoding?
        if name == Cos::Name::STANDARD_ENCODING
          StandardEncoding::INSTANCE
        elsif name == Cos::Name::WIN_ANSI_ENCODING
          WinAnsiEncoding::INSTANCE
        elsif name == Cos::Name::MAC_ROMAN_ENCODING
          MacRomanEncoding::INSTANCE
        elsif name == Cos::Name::MAC_EXPERT_ENCODING
          MacExpertEncoding::INSTANCE
        elsif name == Cos::Name::SYMBOL_ENCODING
          SymbolEncoding::INSTANCE
        elsif name == Cos::Name::ZAPF_DINGBATS_ENCODING
          ZapfDingbatsEncoding::INSTANCE
        else
          nil
        end
      end

      # code-to-name map. Derived classes should not modify the map after class construction.
      @code_to_name = Hash(Int32, String).new

      # name-to-code map. Derived classes should not modify the map after class construction.
      @inverted = Hash(String, Int32).new

      # Returns an unmodifiable view of the code -> name mapping.
      #
      # @return the code -> name map
      def code_to_name_map : Hash(Int32, String)
        @code_to_name.dup
      end

      # Returns an unmodifiable view of the name -> code mapping. More than one name may map to
      # the same code.
      #
      # @return the name -> code map
      def name_to_code_map : Hash(String, Int32)
        @inverted.dup
      end

      # Gets the character code for a glyph name.
      #
      # @param name PostScript glyph name
      # @return character code, or -1 if not found
      def get_code(name : String) : Int32
        @inverted[name]? || -1
      end

      # This will add a character encoding. An already existing mapping is preserved when creating
      # the reverse mapping. Should only be used during construction of the class.
      #
      # @see #overwrite
      #
      # @param code character code
      # @param name PostScript glyph name
      protected def add(code : Int32, name : String) : Nil
        @code_to_name[code] = name
        @inverted[name] = code unless @inverted.has_key?(name)
      end

      # This will add a character encoding. An already existing mapping is overwritten when creating
      # the reverse mapping. Should only be used during construction of the class.
      #
      # @see Encoding#add
      #
      # @param code character code
      # @param name PostScript glyph name
      protected def overwrite(code : Int32, name : String) : Nil
        # remove existing reverse mapping first
        old_name = @code_to_name[code]?
        if old_name
          old_code = @inverted[old_name]?
          if old_code && old_code == code
            @inverted.delete(old_name)
          end
        end
        @inverted[name] = code
        @code_to_name[code] = name
      end

      # Determines if the encoding has a mapping for the given name value.
      #
      # @param name PostScript glyph name
      # @return true if the encoding has a mapping for the given name value
      def contains(name : String) : Bool
        @inverted.has_key?(name)
      end

      # Determines if the encoding has a mapping for the given code value.
      #
      # @param code character code
      # @return if the encoding has a mapping for the given code value
      def contains(code : Int32) : Bool
        @code_to_name.has_key?(code)
      end

      # This will take a character code and get the name from the code.
      #
      # @param code character code
      # @return PostScript glyph name
      def get_name(code : Int32) : String
        @code_to_name[code]? || ".notdef"
      end

      # Returns the name of this encoding.
      #
      # @return the name of the encoding
      abstract def encoding_name : String
    end
  end
end
