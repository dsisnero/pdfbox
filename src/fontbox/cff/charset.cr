# CFF charset interface and implementations
#
# A charset is an array of SIDs/CIDs for all glyphs in the font.
module Fontbox::CFF
  # Abstract base class for CFF charsets
  abstract class Charset
    # Indicates if the charset belongs to a CID font.
    abstract def is_cid_font? : Bool

    # Adds a new GID/SID/name combination to the charset.
    abstract def add_sid(gid : Int32, sid : Int32, name : String) : Nil

    # Adds a new GID/CID combination to the charset.
    abstract def add_cid(gid : Int32, cid : Int32) : Nil

    # Returns the SID for a given GID.
    # SIDs are internal to the font and are not public.
    abstract def get_sid_for_gid(gid : Int32) : Int32

    # Returns the GID for the given SID.
    # SIDs are internal to the font and are not public.
    abstract def get_gid_for_sid(sid : Int32) : Int32

    # Returns the GID for a given CID.
    # Returns 0 if the CID is missing.
    abstract def get_gid_for_cid(cid : Int32) : Int32

    # Returns the SID for a given PostScript name.
    # Some fonts have glyphs beyond their encoding with charset SID names.
    abstract def get_sid(name : String) : Int32

    # Returns the PostScript glyph name for the given GID.
    abstract def get_name_for_gid(gid : Int32) : String?

    # Returns the CID for the given GID.
    abstract def get_cid_for_gid(gid : Int32) : Int32
  end

  # Embedded charset that delegates to either CID or Type1 charset
  class EmbeddedCharset < Charset
    @charset : Charset

    def initialize(is_cid_font : Bool)
      @charset = is_cid_font ? CharsetCID.new : CharsetType1.new
    end

    def is_cid_font? : Bool
      @charset.is_cid_font?
    end

    def add_sid(gid : Int32, sid : Int32, name : String) : Nil
      @charset.add_sid(gid, sid, name)
    end

    def add_cid(gid : Int32, cid : Int32) : Nil
      @charset.add_cid(gid, cid)
    end

    def get_sid_for_gid(gid : Int32) : Int32
      @charset.get_sid_for_gid(gid)
    end

    def get_gid_for_sid(sid : Int32) : Int32
      @charset.get_gid_for_sid(sid)
    end

    def get_gid_for_cid(cid : Int32) : Int32
      @charset.get_gid_for_cid(cid)
    end

    def get_sid(name : String) : Int32
      @charset.get_sid(name)
    end

    def get_name_for_gid(gid : Int32) : String?
      @charset.get_name_for_gid(gid)
    end

    def get_cid_for_gid(gid : Int32) : Int32
      @charset.get_cid_for_gid(gid)
    end
  end

  # CFF charset for CID fonts
  class CharsetCID < Charset
    private EXCEPTION_MESSAGE = "Not a Type 1-equivalent font"

    @sid_or_cid_to_gid = Hash(Int32, Int32).new
    @gid_to_cid = Hash(Int32, Int32).new

    def is_cid_font? : Bool
      true
    end

    def add_sid(gid : Int32, sid : Int32, name : String) : Nil
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def add_cid(gid : Int32, cid : Int32) : Nil
      @sid_or_cid_to_gid[cid] = gid
      @gid_to_cid[gid] = cid
    end

    def get_sid_for_gid(gid : Int32) : Int32
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_gid_for_sid(sid : Int32) : Int32
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_gid_for_cid(cid : Int32) : Int32
      @sid_or_cid_to_gid[cid]? || 0
    end

    def get_sid(name : String) : Int32
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_name_for_gid(gid : Int32) : String?
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_cid_for_gid(gid : Int32) : Int32
      @gid_to_cid[gid]? || 0
    end
  end

  # CFF charset for Type1 fonts
  class CharsetType1 < Charset
    private EXCEPTION_MESSAGE = "Not a CIDFont"

    @sid_or_cid_to_gid = Hash(Int32, Int32).new
    @gid_to_sid = Hash(Int32, Int32).new
    @name_to_sid = Hash(String, Int32).new
    @gid_to_name = Hash(Int32, String).new

    def is_cid_font? : Bool
      false
    end

    def add_sid(gid : Int32, sid : Int32, name : String) : Nil
      @sid_or_cid_to_gid[sid] = gid
      @gid_to_sid[gid] = sid
      @name_to_sid[name] = sid
      @gid_to_name[gid] = name
    end

    def add_cid(gid : Int32, cid : Int32) : Nil
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_sid_for_gid(gid : Int32) : Int32
      @gid_to_sid[gid]? || 0
    end

    def get_gid_for_sid(sid : Int32) : Int32
      @sid_or_cid_to_gid[sid]? || 0
    end

    def get_gid_for_cid(cid : Int32) : Int32
      raise Exception.new(EXCEPTION_MESSAGE)
    end

    def get_sid(name : String) : Int32
      @name_to_sid[name]? || 0
    end

    def get_name_for_gid(gid : Int32) : String?
      @gid_to_name[gid]?
    end

    def get_cid_for_gid(gid : Int32) : Int32
      raise Exception.new(EXCEPTION_MESSAGE)
    end
  end

  # Expert charset (CharsetId = 1)
  class ExpertCharset < CharsetType1
    private INSTANCE = new

    def self.instance : ExpertCharset
      INSTANCE
    end

    private def initialize
      # Table of character codes and their corresponding names.
      expert_charset_table = [
        {0, ".notdef"},
        {1, "space"},
        {229, "exclamsmall"},
        {230, "Hungarumlautsmall"},
        {231, "dollaroldstyle"},
        {232, "dollarsuperior"},
        {233, "ampersandsmall"},
        {234, "Acutesmall"},
        {235, "parenleftsuperior"},
        {236, "parenrightsuperior"},
        {237, "twodotenleader"},
        {238, "onedotenleader"},
        {13, "comma"},
        {14, "hyphen"},
        {15, "period"},
        {99, "fraction"},
        {239, "zerooldstyle"},
        {240, "oneoldstyle"},
        {241, "twooldstyle"},
        {242, "threeoldstyle"},
        {243, "fouroldstyle"},
        {244, "fiveoldstyle"},
        {245, "sixoldstyle"},
        {246, "sevenoldstyle"},
        {247, "eightoldstyle"},
        {248, "nineoldstyle"},
        {27, "colon"},
        {28, "semicolon"},
        {249, "commasuperior"},
        {250, "threequartersemdash"},
        {251, "periodsuperior"},
        {252, "questionsmall"},
        {253, "asuperior"},
        {254, "bsuperior"},
        {255, "centsuperior"},
        {256, "dsuperior"},
        {257, "esuperior"},
        {258, "isuperior"},
        {259, "lsuperior"},
        {260, "msuperior"},
        {261, "nsuperior"},
        {262, "osuperior"},
        {263, "rsuperior"},
        {264, "ssuperior"},
        {265, "tsuperior"},
        {266, "ff"},
        {109, "fi"},
        {110, "fl"},
        {267, "ffi"},
        {268, "ffl"},
        {269, "parenleftinferior"},
        {270, "parenrightinferior"},
        {271, "Circumflexsmall"},
        {272, "hyphensuperior"},
        {273, "Gravesmall"},
        {274, "Asmall"},
        {275, "Bsmall"},
        {276, "Csmall"},
        {277, "Dsmall"},
        {278, "Esmall"},
        {279, "Fsmall"},
        {280, "Gsmall"},
        {281, "Hsmall"},
        {282, "Ismall"},
        {283, "Jsmall"},
        {284, "Ksmall"},
        {285, "Lsmall"},
        {286, "Msmall"},
        {287, "Nsmall"},
        {288, "Osmall"},
        {289, "Psmall"},
        {290, "Qsmall"},
        {291, "Rsmall"},
        {292, "Ssmall"},
        {293, "Tsmall"},
        {294, "Usmall"},
        {295, "Vsmall"},
        {296, "Wsmall"},
        {297, "Xsmall"},
        {298, "Ysmall"},
        {299, "Zsmall"},
        {300, "colonmonetary"},
        {301, "onefitted"},
        {302, "rupiah"},
        {303, "Tildesmall"},
        {304, "exclamdownsmall"},
        {305, "centoldstyle"},
        {306, "Lslashsmall"},
        {307, "Scaronsmall"},
        {308, "Zcaronsmall"},
        {309, "Dieresissmall"},
        {310, "Brevesmall"},
        {311, "Caronsmall"},
        {312, "Dotaccentsmall"},
        {313, "Macronsmall"},
        {314, "figuredash"},
        {315, "hypheninferior"},
        {316, "Ogoneksmall"},
        {317, "Ringsmall"},
        {318, "Cedillasmall"},
        {158, "onequarter"},
        {155, "onehalf"},
        {163, "threequarters"},
        {319, "questiondownsmall"},
        {320, "oneeighth"},
        {321, "threeeighths"},
        {322, "fiveeighths"},
        {323, "seveneighths"},
        {324, "onethird"},
        {325, "twothirds"},
        {326, "zerosuperior"},
        {150, "onesuperior"},
        {164, "twosuperior"},
        {169, "threesuperior"},
        {327, "foursuperior"},
        {328, "fivesuperior"},
        {329, "sixsuperior"},
        {330, "sevensuperior"},
        {331, "eightsuperior"},
        {332, "ninesuperior"},
        {333, "zeroinferior"},
        {334, "oneinferior"},
        {335, "twoinferior"},
        {336, "threeinferior"},
        {337, "fourinferior"},
        {338, "fiveinferior"},
        {339, "sixinferior"},
        {340, "seveninferior"},
        {341, "eightinferior"},
        {342, "nineinferior"},
        {343, "centinferior"},
        {344, "dollarinferior"},
        {345, "periodinferior"},
        {346, "commainferior"},
        {347, "Agravesmall"},
        {348, "Aacutesmall"},
        {349, "Acircumflexsmall"},
        {350, "Atildesmall"},
        {351, "Adieresissmall"},
        {352, "Aringsmall"},
        {353, "AEsmall"},
        {354, "Ccedillasmall"},
        {355, "Egravesmall"},
        {356, "Eacutesmall"},
        {357, "Ecircumflexsmall"},
        {358, "Edieresissmall"},
        {359, "Igravesmall"},
        {360, "Iacutesmall"},
        {361, "Icircumflexsmall"},
        {362, "Idieresissmall"},
        {363, "Ethsmall"},
        {364, "Ntildesmall"},
        {365, "Ogravesmall"},
        {366, "Oacutesmall"},
        {367, "Ocircumflexsmall"},
        {368, "Otildesmall"},
        {369, "Odieresissmall"},
        {370, "OEsmall"},
        {371, "Oslashsmall"},
        {372, "Ugravesmall"},
        {373, "Uacutesmall"},
        {374, "Ucircumflexsmall"},
        {375, "Udieresissmall"},
        {376, "Yacutesmall"},
        {377, "Thornsmall"},
        {378, "Ydieresissmall"},
      ]

      gid = 0
      expert_charset_table.each do |entry|
        add_sid(gid, entry[0], entry[1])
        gid += 1
      end
    end
  end

  # Expert subset charset (CharsetId = 2)
  class ExpertSubsetCharset < CharsetType1
    private INSTANCE = new

    def self.instance : ExpertSubsetCharset
      INSTANCE
    end

    private def initialize
      # Table of character codes and their corresponding names.
      expert_subset_charset_table = [
        {0, ".notdef"},
        {1, "space"},
        {231, "dollaroldstyle"},
        {232, "dollarsuperior"},
        {235, "parenleftsuperior"},
        {236, "parenrightsuperior"},
        {237, "twodotenleader"},
        {238, "onedotenleader"},
        {13, "comma"},
        {14, "hyphen"},
        {15, "period"},
        {99, "fraction"},
        {239, "zerooldstyle"},
        {240, "oneoldstyle"},
        {241, "twooldstyle"},
        {242, "threeoldstyle"},
        {243, "fouroldstyle"},
        {244, "fiveoldstyle"},
        {245, "sixoldstyle"},
        {246, "sevenoldstyle"},
        {247, "eightoldstyle"},
        {248, "nineoldstyle"},
        {27, "colon"},
        {28, "semicolon"},
        {249, "commasuperior"},
        {250, "threequartersemdash"},
        {251, "periodsuperior"},
        {253, "asuperior"},
        {254, "bsuperior"},
        {255, "centsuperior"},
        {256, "dsuperior"},
        {257, "esuperior"},
        {258, "isuperior"},
        {259, "lsuperior"},
        {260, "msuperior"},
        {261, "nsuperior"},
        {262, "osuperior"},
        {263, "rsuperior"},
        {264, "ssuperior"},
        {265, "tsuperior"},
        {266, "ff"},
        {109, "fi"},
        {110, "fl"},
        {267, "ffi"},
        {268, "ffl"},
        {269, "parenleftinferior"},
        {270, "parenrightinferior"},
        {272, "hyphensuperior"},
        {300, "colonmonetary"},
        {301, "onefitted"},
        {302, "rupiah"},
        {305, "centoldstyle"},
        {314, "figuredash"},
        {315, "hypheninferior"},
        {158, "onequarter"},
        {155, "onehalf"},
        {163, "threequarters"},
        {320, "oneeighth"},
        {321, "threeeighths"},
        {322, "fiveeighths"},
        {323, "seveneighths"},
        {324, "onethird"},
        {325, "twothirds"},
        {326, "zerosuperior"},
        {150, "onesuperior"},
        {164, "twosuperior"},
        {169, "threesuperior"},
        {327, "foursuperior"},
        {328, "fivesuperior"},
        {329, "sixsuperior"},
        {330, "sevensuperior"},
        {331, "eightsuperior"},
        {332, "ninesuperior"},
        {333, "zeroinferior"},
        {334, "oneinferior"},
        {335, "twoinferior"},
        {336, "threeinferior"},
        {337, "fourinferior"},
        {338, "fiveinferior"},
        {339, "sixinferior"},
        {340, "seveninferior"},
        {341, "eightinferior"},
        {342, "nineinferior"},
        {343, "centinferior"},
        {344, "dollarinferior"},
        {345, "periodinferior"},
        {346, "commainferior"},
      ]

      gid = 0
      expert_subset_charset_table.each do |entry|
        add_sid(gid, entry[0], entry[1])
        gid += 1
      end
    end
  end

  # ISO Adobe charset (CharsetId = 0)
  class ISOAdobeCharset < CharsetType1
    private INSTANCE = new

    def self.instance : ISOAdobeCharset
      INSTANCE
    end

    private def initialize
      # Table of character codes and their corresponding names.
      iso_adobe_charset_table = [
        {0, ".notdef"},
        {1, "space"},
        {2, "exclam"},
        {3, "quotedbl"},
        {4, "numbersign"},
        {5, "dollar"},
        {6, "percent"},
        {7, "ampersand"},
        {8, "quoteright"},
        {9, "parenleft"},
        {10, "parenright"},
        {11, "asterisk"},
        {12, "plus"},
        {13, "comma"},
        {14, "hyphen"},
        {15, "period"},
        {16, "slash"},
        {17, "zero"},
        {18, "one"},
        {19, "two"},
        {20, "three"},
        {21, "four"},
        {22, "five"},
        {23, "six"},
        {24, "seven"},
        {25, "eight"},
        {26, "nine"},
        {27, "colon"},
        {28, "semicolon"},
        {29, "less"},
        {30, "equal"},
        {31, "greater"},
        {32, "question"},
        {33, "at"},
        {34, "A"},
        {35, "B"},
        {36, "C"},
        {37, "D"},
        {38, "E"},
        {39, "F"},
        {40, "G"},
        {41, "H"},
        {42, "I"},
        {43, "J"},
        {44, "K"},
        {45, "L"},
        {46, "M"},
        {47, "N"},
        {48, "O"},
        {49, "P"},
        {50, "Q"},
        {51, "R"},
        {52, "S"},
        {53, "T"},
        {54, "U"},
        {55, "V"},
        {56, "W"},
        {57, "X"},
        {58, "Y"},
        {59, "Z"},
        {60, "bracketleft"},
        {61, "backslash"},
        {62, "bracketright"},
        {63, "asciicircum"},
        {64, "underscore"},
        {65, "quoteleft"},
        {66, "a"},
        {67, "b"},
        {68, "c"},
        {69, "d"},
        {70, "e"},
        {71, "f"},
        {72, "g"},
        {73, "h"},
        {74, "i"},
        {75, "j"},
        {76, "k"},
        {77, "l"},
        {78, "m"},
        {79, "n"},
        {80, "o"},
        {81, "p"},
        {82, "q"},
        {83, "r"},
        {84, "s"},
        {85, "t"},
        {86, "u"},
        {87, "v"},
        {88, "w"},
        {89, "x"},
        {90, "y"},
        {91, "z"},
        {92, "braceleft"},
        {93, "bar"},
        {94, "braceright"},
        {95, "asciitilde"},
        {96, "exclamdown"},
        {97, "cent"},
        {98, "sterling"},
        {99, "fraction"},
        {100, "yen"},
        {101, "florin"},
        {102, "section"},
        {103, "currency"},
        {104, "quotesingle"},
        {105, "quotedblleft"},
        {106, "guillemotleft"},
        {107, "guilsinglleft"},
        {108, "guilsinglright"},
        {109, "fi"},
        {110, "fl"},
        {111, "endash"},
        {112, "dagger"},
        {113, "daggerdbl"},
        {114, "periodcentered"},
        {115, "paragraph"},
        {116, "bullet"},
        {117, "quotesinglbase"},
        {118, "quotedblbase"},
        {119, "quotedblright"},
        {120, "guillemotright"},
        {121, "ellipsis"},
        {122, "perthousand"},
        {123, "questiondown"},
        {124, "grave"},
        {125, "acute"},
        {126, "circumflex"},
        {127, "tilde"},
        {128, "macron"},
        {129, "breve"},
        {130, "dotaccent"},
        {131, "dieresis"},
        {132, "ring"},
        {133, "cedilla"},
        {134, "hungarumlaut"},
        {135, "ogonek"},
        {136, "caron"},
        {137, "emdash"},
        {138, "AE"},
        {139, "ordfeminine"},
        {140, "Lslash"},
        {141, "Oslash"},
        {142, "OE"},
        {143, "ordmasculine"},
        {144, "ae"},
        {145, "dotlessi"},
        {146, "lslash"},
        {147, "oslash"},
        {148, "oe"},
        {149, "germandbls"},
        {150, "onesuperior"},
        {151, "logicalnot"},
        {152, "mu"},
        {153, "trademark"},
        {154, "Eth"},
        {155, "onehalf"},
        {156, "plusminus"},
        {157, "Thorn"},
        {158, "onequarter"},
        {159, "divide"},
        {160, "brokenbar"},
        {161, "degree"},
        {162, "thorn"},
        {163, "threequarters"},
        {164, "twosuperior"},
        {165, "registered"},
        {166, "minus"},
        {167, "eth"},
        {168, "multiply"},
        {169, "threesuperior"},
        {170, "copyright"},
        {171, "Aacute"},
        {172, "Acircumflex"},
        {173, "Adieresis"},
        {174, "Agrave"},
        {175, "Aring"},
        {176, "Atilde"},
        {177, "Ccedilla"},
        {178, "Eacute"},
        {179, "Ecircumflex"},
        {180, "Edieresis"},
        {181, "Egrave"},
        {182, "Iacute"},
        {183, "Icircumflex"},
        {184, "Idieresis"},
        {185, "Igrave"},
        {186, "Ntilde"},
        {187, "Oacute"},
        {188, "Ocircumflex"},
        {189, "Odieresis"},
        {190, "Ograve"},
        {191, "Otilde"},
        {192, "Scaron"},
        {193, "Uacute"},
        {194, "Ucircumflex"},
        {195, "Udieresis"},
        {196, "Ugrave"},
        {197, "Yacute"},
        {198, "Ydieresis"},
        {199, "Zcaron"},
        {200, "aacute"},
        {201, "acircumflex"},
        {202, "adieresis"},
        {203, "agrave"},
        {204, "aring"},
        {205, "atilde"},
        {206, "ccedilla"},
        {207, "eacute"},
        {208, "ecircumflex"},
        {209, "edieresis"},
        {210, "egrave"},
        {211, "iacute"},
        {212, "icircumflex"},
        {213, "idieresis"},
        {214, "igrave"},
        {215, "ntilde"},
        {216, "oacute"},
        {217, "ocircumflex"},
        {218, "odieresis"},
        {219, "ograve"},
        {220, "otilde"},
        {221, "scaron"},
        {222, "uacute"},
        {223, "ucircumflex"},
        {224, "udieresis"},
        {225, "ugrave"},
        {226, "yacute"},
        {227, "ydieresis"},
        {228, "zcaron"},
      ]

      gid = 0
      iso_adobe_charset_table.each do |entry|
        add_sid(gid, entry[0], entry[1])
        gid += 1
      end
    end
  end
end
