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

module Fontbox::CFF
  # This class represents a CharStringCommand.
  class CharStringCommand
    # Enum of all valid type1 key words
    enum Type1KeyWord
      HSTEM
      VSTEM
      VMOVETO
      RLINETO
      HLINETO
      VLINETO
      RRCURVETO
      CLOSEPATH
      CALLSUBR
      RET
      ESCAPE
      HSBW
      ENDCHAR
      RMOVETO
      HMOVETO
      VHCURVETO
      HVCURVETO
      DOTSECTION
      VSTEM3
      HSTEM3
      SEAC
      SBW
      DIV
      CALLOTHERSUBR
      POP
      SETCURRENTPOINT
    end

    # Enum of all valid type2 key words
    enum Type2KeyWord
      HSTEM
      VSTEM
      VMOVETO
      RLINETO
      HLINETO
      VLINETO
      RRCURVETO
      CALLSUBR
      RET
      ESCAPE
      ENDCHAR
      HSTEMHM
      HINTMASK
      CNTRMASK
      RMOVETO
      HMOVETO
      VSTEMHM
      RCURVELINE
      RLINECURVE
      VVCURVETO
      HHCURVETO
      SHORTINT
      CALLGSUBR
      VHCURVETO
      HVCURVETO
      AND
      OR
      NOT
      ABS
      ADD
      SUB
      DIV
      NEG
      EQ
      DROP
      PUT
      GET
      IFELSE
      RANDOM
      MUL
      SQRT
      DUP
      EXCH
      INDEX
      ROLL
      HFLEX
      FLEX
      HFLEX1
      FLEX1
    end

    getter type1_keyword : Type1KeyWord?
    getter type2_keyword : Type2KeyWord?
    getter value : Int32
    getter name : String

    # Array for lookup by value
    @@commands_by_value = Array(CharStringCommand?).new(230) { nil } # max value is 229

    # Command constants
    HSTEM = new(Type1KeyWord::HSTEM, Type2KeyWord::HSTEM, 1, "HSTEM"); @@commands_by_value[1] = HSTEM
    VSTEM = new(Type1KeyWord::VSTEM, Type2KeyWord::VSTEM, 3, "VSTEM"); @@commands_by_value[3] = VSTEM
    VMOVETO = new(Type1KeyWord::VMOVETO, Type2KeyWord::VMOVETO, 4, "VMOVETO"); @@commands_by_value[4] = VMOVETO
    RLINETO = new(Type1KeyWord::RLINETO, Type2KeyWord::RLINETO, 5, "RLINETO"); @@commands_by_value[5] = RLINETO
    HLINETO = new(Type1KeyWord::HLINETO, Type2KeyWord::HLINETO, 6, "HLINETO"); @@commands_by_value[6] = HLINETO
    VLINETO = new(Type1KeyWord::VLINETO, Type2KeyWord::VLINETO, 7, "VLINETO"); @@commands_by_value[7] = VLINETO
    RRCURVETO = new(Type1KeyWord::RRCURVETO, Type2KeyWord::RRCURVETO, 8, "RRCURVETO"); @@commands_by_value[8] = RRCURVETO
    CLOSEPATH = new(Type1KeyWord::CLOSEPATH, nil, 9, "CLOSEPATH"); @@commands_by_value[9] = CLOSEPATH
    CALLSUBR = new(Type1KeyWord::CALLSUBR, Type2KeyWord::CALLSUBR, 10, "CALLSUBR"); @@commands_by_value[10] = CALLSUBR
    RET = new(Type1KeyWord::RET, Type2KeyWord::RET, 11, "RET"); @@commands_by_value[11] = RET
    ESCAPE = new(Type1KeyWord::ESCAPE, Type2KeyWord::ESCAPE, 12, "ESCAPE"); @@commands_by_value[12] = ESCAPE
    HSBW = new(Type1KeyWord::HSBW, nil, 13, "HSBW"); @@commands_by_value[13] = HSBW
    ENDCHAR = new(Type1KeyWord::ENDCHAR, Type2KeyWord::ENDCHAR, 14, "ENDCHAR"); @@commands_by_value[14] = ENDCHAR
    HSTEMHM = new(nil, Type2KeyWord::HSTEMHM, 18, "HSTEMHM"); @@commands_by_value[18] = HSTEMHM
    HINTMASK = new(nil, Type2KeyWord::HINTMASK, 19, "HINTMASK"); @@commands_by_value[19] = HINTMASK
    CNTRMASK = new(nil, Type2KeyWord::CNTRMASK, 20, "CNTRMASK"); @@commands_by_value[20] = CNTRMASK
    RMOVETO = new(Type1KeyWord::RMOVETO, Type2KeyWord::RMOVETO, 21, "RMOVETO"); @@commands_by_value[21] = RMOVETO
    HMOVETO = new(Type1KeyWord::HMOVETO, Type2KeyWord::HMOVETO, 22, "HMOVETO"); @@commands_by_value[22] = HMOVETO
    VSTEMHM = new(nil, Type2KeyWord::VSTEMHM, 23, "VSTEMHM"); @@commands_by_value[23] = VSTEMHM
    RCURVELINE = new(nil, Type2KeyWord::RCURVELINE, 24, "RCURVELINE"); @@commands_by_value[24] = RCURVELINE
    RLINECURVE = new(nil, Type2KeyWord::RLINECURVE, 25, "RLINECURVE"); @@commands_by_value[25] = RLINECURVE
    VVCURVETO = new(nil, Type2KeyWord::VVCURVETO, 26, "VVCURVETO"); @@commands_by_value[26] = VVCURVETO
    HHCURVETO = new(nil, Type2KeyWord::HHCURVETO, 27, "HHCURVETO"); @@commands_by_value[27] = HHCURVETO
    SHORTINT = new(nil, Type2KeyWord::SHORTINT, 28, "SHORTINT"); @@commands_by_value[28] = SHORTINT
    CALLGSUBR = new(nil, Type2KeyWord::CALLGSUBR, 29, "CALLGSUBR"); @@commands_by_value[29] = CALLGSUBR
    VHCURVETO = new(Type1KeyWord::VHCURVETO, Type2KeyWord::VHCURVETO, 30, "VHCURVETO"); @@commands_by_value[30] = VHCURVETO
    HVCURVETO = new(Type1KeyWord::HVCURVETO, Type2KeyWord::HVCURVETO, 31, "HVCURVETO"); @@commands_by_value[31] = HVCURVETO
    DOTSECTION = new(Type1KeyWord::DOTSECTION, nil, 192, "DOTSECTION"); @@commands_by_value[192] = DOTSECTION
    VSTEM3 = new(Type1KeyWord::VSTEM3, nil, 193, "VSTEM3"); @@commands_by_value[193] = VSTEM3
    HSTEM3 = new(Type1KeyWord::HSTEM3, nil, 194, "HSTEM3"); @@commands_by_value[194] = HSTEM3
    AND = new(nil, Type2KeyWord::AND, 195, "AND"); @@commands_by_value[195] = AND
    OR = new(nil, Type2KeyWord::OR, 196, "OR"); @@commands_by_value[196] = OR
    NOT = new(nil, Type2KeyWord::NOT, 197, "NOT"); @@commands_by_value[197] = NOT
    SEAC = new(Type1KeyWord::SEAC, nil, 198, "SEAC"); @@commands_by_value[198] = SEAC
    SBW = new(Type1KeyWord::SBW, nil, 199, "SBW"); @@commands_by_value[199] = SBW
    ABS = new(nil, Type2KeyWord::ABS, 201, "ABS"); @@commands_by_value[201] = ABS
    ADD = new(nil, Type2KeyWord::ADD, 202, "ADD"); @@commands_by_value[202] = ADD
    SUB = new(nil, Type2KeyWord::SUB, 203, "SUB"); @@commands_by_value[203] = SUB
    DIV = new(Type1KeyWord::DIV, Type2KeyWord::DIV, 204, "DIV"); @@commands_by_value[204] = DIV
    NEG = new(nil, Type2KeyWord::NEG, 206, "NEG"); @@commands_by_value[206] = NEG
    EQ = new(nil, Type2KeyWord::EQ, 207, "EQ"); @@commands_by_value[207] = EQ
    CALLOTHERSUBR = new(Type1KeyWord::CALLOTHERSUBR, nil, 208, "CALLOTHERSUBR"); @@commands_by_value[208] = CALLOTHERSUBR
    POP = new(Type1KeyWord::POP, nil, 209, "POP"); @@commands_by_value[209] = POP
    DROP = new(nil, Type2KeyWord::DROP, 210, "DROP"); @@commands_by_value[210] = DROP
    PUT = new(nil, Type2KeyWord::PUT, 212, "PUT"); @@commands_by_value[212] = PUT
    GET = new(nil, Type2KeyWord::GET, 213, "GET"); @@commands_by_value[213] = GET
    IFELSE = new(nil, Type2KeyWord::IFELSE, 214, "IFELSE"); @@commands_by_value[214] = IFELSE
    RANDOM = new(nil, Type2KeyWord::RANDOM, 215, "RANDOM"); @@commands_by_value[215] = RANDOM
    MUL = new(nil, Type2KeyWord::MUL, 216, "MUL"); @@commands_by_value[216] = MUL
    SQRT = new(nil, Type2KeyWord::SQRT, 218, "SQRT"); @@commands_by_value[218] = SQRT
    DUP = new(nil, Type2KeyWord::DUP, 219, "DUP"); @@commands_by_value[219] = DUP
    EXCH = new(nil, Type2KeyWord::EXCH, 220, "EXCH"); @@commands_by_value[220] = EXCH
    INDEX = new(nil, Type2KeyWord::INDEX, 221, "INDEX"); @@commands_by_value[221] = INDEX
    ROLL = new(nil, Type2KeyWord::ROLL, 222, "ROLL"); @@commands_by_value[222] = ROLL
    SETCURRENTPOINT = new(Type1KeyWord::SETCURRENTPOINT, nil, 225, "SETCURRENTPOINT"); @@commands_by_value[225] = SETCURRENTPOINT
    HFLEX = new(nil, Type2KeyWord::HFLEX, 226, "HFLEX"); @@commands_by_value[226] = HFLEX
    FLEX = new(nil, Type2KeyWord::FLEX, 227, "FLEX"); @@commands_by_value[227] = FLEX
    HFLEX1 = new(nil, Type2KeyWord::HFLEX1, 228, "HFLEX1"); @@commands_by_value[228] = HFLEX1
    FLEX1 = new(nil, Type2KeyWord::FLEX1, 229, "FLEX1"); @@commands_by_value[229] = FLEX1
    UNKNOWN = new(nil, nil, 99, "unknown command"); @@commands_by_value[99] = UNKNOWN

    private def initialize(@type1_keyword : Type1KeyWord?, @type2_keyword : Type2KeyWord?, @value : Int32, @name : String)
    end

    # Get an instance of the CharStringCommand represented by the given value.
    def self.get_instance(b0 : Int32) : CharStringCommand
      if b0 >= 0 && b0 < @@commands_by_value.size
        cmd = @@commands_by_value[b0]
        return cmd if cmd
      end
      UNKNOWN
    end

    # Get an instance of the CharStringCommand represented by the given two values.
    def self.get_instance(b0 : Int32, b1 : Int32) : CharStringCommand
      get_instance((b0 << 4) + b1)
    end

    # Get an instance of the CharStringCommand represented by the given array.
    def self.get_instance(values : Array(Int32)) : CharStringCommand
      case values.size
      when 1
        get_instance(values[0])
      when 2
        get_instance(values[0], values[1])
      else
        UNKNOWN
      end
    end

    def to_s(io : IO) : Nil
      io << @name << "|"
    end
  end
end
