# Token class for Adobe Type 1 font lexer
# Port of Apache PDFBox Token.java
module Fontbox::Type1
  # All different types of tokens
  enum Kind
    NONE
    STRING
    NAME
    LITERAL
    REAL
    INTEGER
    START_ARRAY
    END_ARRAY
    START_PROC
    END_PROC
    START_DICT
    END_DICT
    CHARSTRING
  end

  class Token
    property text : String?
    property data : Bytes?
    property kind : Kind

    # Constructs a new Token object given its text and kind
    def initialize(text : String, kind : Kind)
      @text = text
      @kind = kind
      @data = nil
    end

    # Constructs a new Token object given its single-character text and kind
    def initialize(character : Char, kind : Kind)
      @text = character.to_s
      @kind = kind
      @data = nil
    end

    # Constructs a new Token object given its raw data and kind
    # This is for CHARSTRING tokens only
    def initialize(data : Bytes, kind : Kind)
      @data = data
      @kind = kind
      @text = nil
    end

    # Some fonts have reals where integers should be, so we tolerate it
    def int_value : Int32
      if text = @text
        text.to_f.to_i
      else
        raise "No text for int_value"
      end
    end

    def float_value : Float32
      if text = @text
        text.to_f32
      else
        raise "No text for float_value"
      end
    end

    def boolean_value : Bool
      if text = @text
        text == "true"
      else
        false
      end
    end

    def to_s : String
      if @kind == Kind::CHARSTRING && (data = @data)
        "Token[kind=CHARSTRING, data=#{data.size} bytes]"
      else
        "Token[kind=#{@kind}, text=#{@text}]"
      end
    end
  end
end
