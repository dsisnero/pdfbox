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
  # This is an interface to a text encoder.
  # Corresponds to org.apache.pdfbox.pdmodel.font.encoding.MacExpertEncoding in Apache PDFBox.
  class MacExpertEncoding < Encoding
    # Singleton instance of this class.
    INSTANCE = new

    # Table of octal character codes and their corresponding names.
    private MAC_EXPERT_ENCODING_TABLE = [
      {190, "AEsmall"},
      {135, "Aacutesmall"},
      {137, "Acircumflexsmall"},
      {39, "Acutesmall"},
      {138, "Adieresissmall"},
      {136, "Agravesmall"},
      {140, "Aringsmall"},
      {97, "Asmall"},
      {139, "Atildesmall"},
      {243, "Brevesmall"},
      {98, "Bsmall"},
      {174, "Caronsmall"},
      {141, "Ccedillasmall"},
      {201, "Cedillasmall"},
      {94, "Circumflexsmall"},
      {99, "Csmall"},
      {172, "Dieresissmall"},
      {250, "Dotaccentsmall"},
      {100, "Dsmall"},
      {142, "Eacutesmall"},
      {144, "Ecircumflexsmall"},
      {145, "Edieresissmall"},
      {143, "Egravesmall"},
      {101, "Esmall"},
      {68, "Ethsmall"},
      {102, "Fsmall"},
      {96, "Gravesmall"},
      {103, "Gsmall"},
      {104, "Hsmall"},
      {34, "Hungarumlautsmall"},
      {146, "Iacutesmall"},
      {148, "Icircumflexsmall"},
      {149, "Idieresissmall"},
      {147, "Igravesmall"},
      {105, "Ismall"},
      {106, "Jsmall"},
      {107, "Ksmall"},
      {194, "Lslashsmall"},
      {108, "Lsmall"},
      {244, "Macronsmall"},
      {109, "Msmall"},
      {110, "Nsmall"},
      {150, "Ntildesmall"},
      {207, "OEsmall"},
      {151, "Oacutesmall"},
      {153, "Ocircumflexsmall"},
      {154, "Odieresissmall"},
      {242, "Ogoneksmall"},
      {152, "Ogravesmall"},
      {191, "Oslashsmall"},
      {111, "Osmall"},
      {155, "Otildesmall"},
      {112, "Psmall"},
      {113, "Qsmall"},
      {253, "Ringsmall"},
      {114, "Rsmall"},
      {167, "Scaronsmall"},
      {115, "Ssmall"},
      {185, "Thornsmall"},
      {126, "Tildesmall"},
      {116, "Tsmall"},
      {156, "Uacutesmall"},
      {158, "Ucircumflexsmall"},
      {159, "Udieresissmall"},
      {157, "Ugravesmall"},
      {117, "Usmall"},
      {118, "Vsmall"},
      {119, "Wsmall"},
      {120, "Xsmall"},
      {180, "Yacutesmall"},
      {216, "Ydieresissmall"},
      {121, "Ysmall"},
      {189, "Zcaronsmall"},
      {122, "Zsmall"},
      {38, "ampersandsmall"},
      {129, "asuperior"},
      {245, "bsuperior"},
      {169, "centinferior"},
      {35, "centoldstyle"},
      {130, "centsuperior"},
      {58, "colon"},
      {123, "colonmonetary"},
      {44, "comma"},
      {178, "commainferior"},
      {248, "commasuperior"},
      {182, "dollarinferior"},
      {36, "dollaroldstyle"},
      {37, "dollarsuperior"},
      {235, "dsuperior"},
      {165, "eightinferior"},
      {56, "eightoldstyle"},
      {161, "eightsuperior"},
      {228, "esuperior"},
      {214, "exclamdownsmall"},
      {33, "exclamsmall"},
      {86, "ff"},
      {89, "ffi"},
      {90, "ffl"},
      {87, "fi"},
      {208, "figuredash"},
      {76, "fiveeighths"},
      {176, "fiveinferior"},
      {53, "fiveoldstyle"},
      {222, "fivesuperior"},
      {88, "fl"},
      {162, "fourinferior"},
      {52, "fouroldstyle"},
      {221, "foursuperior"},
      {47, "fraction"},
      {45, "hyphen"},
      {95, "hypheninferior"},
      {209, "hyphensuperior"},
      {233, "isuperior"},
      {241, "lsuperior"},
      {247, "msuperior"},
      {187, "nineinferior"},
      {57, "nineoldstyle"},
      {225, "ninesuperior"},
      {246, "nsuperior"},
      {43, "onedotenleader"},
      {74, "oneeighth"},
      {124, "onefitted"},
      {72, "onehalf"},
      {193, "oneinferior"},
      {49, "oneoldstyle"},
      {71, "onequarter"},
      {218, "onesuperior"},
      {78, "onethird"},
      {175, "osuperior"},
      {91, "parenleftinferior"},
      {40, "parenleftsuperior"},
      {93, "parenrightinferior"},
      {41, "parenrightsuperior"},
      {46, "period"},
      {179, "periodinferior"},
      {249, "periodsuperior"},
      {192, "questiondownsmall"},
      {63, "questionsmall"},
      {229, "rsuperior"},
      {125, "rupiah"},
      {59, "semicolon"},
      {77, "seveneighths"},
      {166, "seveninferior"},
      {55, "sevenoldstyle"},
      {224, "sevensuperior"},
      {164, "sixinferior"},
      {54, "sixoldstyle"},
      {223, "sixsuperior"},
      {32, "space"},
      {234, "ssuperior"},
      {75, "threeeighths"},
      {163, "threeinferior"},
      {51, "threeoldstyle"},
      {73, "threequarters"},
      {61, "threequartersemdash"},
      {220, "threesuperior"},
      {230, "tsuperior"},
      {42, "twodotenleader"},
      {170, "twoinferior"},
      {50, "twooldstyle"},
      {219, "twosuperior"},
      {79, "twothirds"},
      {188, "zeroinferior"},
      {48, "zerooldstyle"},
      {226, "zerosuperior"},
    ]

    # Constructor.
    private def initialize
      MAC_EXPERT_ENCODING_TABLE.each do |encoding_entry|
        add(encoding_entry[CHAR_CODE], encoding_entry[CHAR_NAME])
      end
    end

    # Convert this standard java object to a COS object.
    #
    # @return The cos object that matches this Java object.
    def cos_object : Cos::Base
      Cos::Name::MAC_EXPERT_ENCODING
    end

    # Returns the name of this encoding.
    #
    # @return the name of the encoding
    def get_encoding_name : String
      "MacExpertEncoding"
    end
  end
end
