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

module Fontbox::TTF
  # Windows Glyph List 4 (WGL4) names for Mac glyphs.
  module WGL4Names
    extend self

    # The number of standard mac glyph names.
    NUMBER_OF_MAC_GLYPHS = 258

    # The 258 standard mac glyph names as used in 'post' format 1 and 2.
    private MAC_GLYPH_NAMES = [
      ".notdef", ".null", "nonmarkingreturn", "space", "exclam", "quotedbl",
      "numbersign", "dollar", "percent", "ampersand", "quotesingle",
      "parenleft", "parenright", "asterisk", "plus", "comma", "hyphen",
      "period", "slash", "zero", "one", "two", "three", "four", "five",
      "six", "seven", "eight", "nine", "colon", "semicolon", "less",
      "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F",
      "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
      "T", "U", "V", "W", "X", "Y", "Z", "bracketleft", "backslash",
      "bracketright", "asciicircum", "underscore", "grave", "a", "b",
      "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o",
      "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft",
      "bar", "braceright", "asciitilde", "Adieresis", "Aring",
      "Ccedilla", "Eacute", "Ntilde", "Odieresis", "Udieresis", "aacute",
      "agrave", "acircumflex", "adieresis", "atilde", "aring",
      "ccedilla", "eacute", "egrave", "ecircumflex", "edieresis",
      "iacute", "igrave", "icircumflex", "idieresis", "ntilde", "oacute",
      "ograve", "ocircumflex", "odieresis", "otilde", "uacute", "ugrave",
      "ucircumflex", "udieresis", "dagger", "degree", "cent", "sterling",
      "section", "bullet", "paragraph", "germandbls", "registered",
      "copyright", "trademark", "acute", "dieresis", "notequal", "AE",
      "Oslash", "infinity", "plusminus", "lessequal", "greaterequal",
      "yen", "mu", "partialdiff", "summation", "product", "pi",
      "integral", "ordfeminine", "ordmasculine", "Omega", "ae", "oslash",
      "questiondown", "exclamdown", "logicalnot", "radical", "florin",
      "approxequal", "Delta", "guillemotleft", "guillemotright",
      "ellipsis", "nonbreakingspace", "Agrave", "Atilde", "Otilde", "OE",
      "oe", "endash", "emdash", "quotedblleft", "quotedblright",
      "quoteleft", "quoteright", "divide", "lozenge", "ydieresis",
      "Ydieresis", "fraction", "currency", "guilsinglleft",
      "guilsinglright", "fi", "fl", "daggerdbl", "periodcentered",
      "quotesinglbase", "quotedblbase", "perthousand", "Acircumflex",
      "Ecircumflex", "Aacute", "Edieresis", "Egrave", "Iacute",
      "Icircumflex", "Idieresis", "Igrave", "Oacute", "Ocircumflex",
      "apple", "Ograve", "Uacute", "Ucircumflex", "Ugrave", "dotlessi",
      "circumflex", "tilde", "macron", "breve", "dotaccent", "ring",
      "cedilla", "hungarumlaut", "ogonek", "caron", "Lslash", "lslash",
      "Scaron", "scaron", "Zcaron", "zcaron", "brokenbar", "Eth", "eth",
      "Yacute", "yacute", "Thorn", "thorn", "minus", "multiply",
      "onesuperior", "twosuperior", "threesuperior", "onehalf",
      "onequarter", "threequarters", "franc", "Gbreve", "gbreve",
      "Idotaccent", "Scedilla", "scedilla", "Cacute", "cacute", "Ccaron",
      "ccaron", "dcroat",
    ]

    # The indices of the standard mac glyph names.
    private MAC_GLYPH_NAMES_INDICES = begin
      indices = {} of String => Int32
      NUMBER_OF_MAC_GLYPHS.times do |i|
        indices[MAC_GLYPH_NAMES[i]] = i
      end
      indices
    end

    # Returns the index of the glyph with the given name.
    # ameba:disable Naming/AccessorMethodName
    def get_glyph_index(name : String) : Int32?
      MAC_GLYPH_NAMES_INDICES[name]?
    end

    # Returns the name of the glyph at the given index.
    # ameba:disable Naming/AccessorMethodName
    def get_glyph_name(index : Int32) : String?
      index >= 0 && index < NUMBER_OF_MAC_GLYPHS ? MAC_GLYPH_NAMES[index] : nil
    end

    # Returns a new array with all glyph names.
    # ameba:disable Naming/AccessorMethodName
    def get_all_names : Array(String)
      MAC_GLYPH_NAMES.dup
    end
  end
end
