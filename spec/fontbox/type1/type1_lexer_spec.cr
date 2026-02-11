require "../../spec_helper"

module Fontbox::Type1
  describe Type1Lexer do
    it "test real numbers" do
      s = "/FontMatrix [1e-3 0e-3 0e-3 -1E-03 0 0 1.23 -1.23 ] readonly def"
      t1l = Type1Lexer.new(s.to_slice)
      read_tokens = ->(t1l : Type1Lexer) do
        tokens = [] of Token
        loop do
          token = t1l.next_token
          break if token.nil?
          tokens << token
        end
        tokens
      end
      tokens = read_tokens.call(t1l)

      tokens[0].get_kind.should eq Kind::LITERAL
      tokens[0].get_text.should eq "FontMatrix"
      tokens[1].get_kind.should eq Kind::START_ARRAY
      tokens[2].get_kind.should eq Kind::REAL
      tokens[3].get_kind.should eq Kind::REAL
      tokens[4].get_kind.should eq Kind::REAL
      tokens[5].get_kind.should eq Kind::REAL
      tokens[6].get_kind.should eq Kind::INTEGER
      tokens[7].get_kind.should eq Kind::INTEGER
      tokens[8].get_kind.should eq Kind::REAL
      tokens[9].get_kind.should eq Kind::REAL
      tokens[2].get_text.should eq "1e-3"
      tokens[3].get_text.should eq "0e-3"
      tokens[4].get_text.should eq "0e-3"
      tokens[5].get_text.should eq "-1E-03"
      tokens[5].float_value.should eq -1e-3_f32
      tokens[6].get_text.should eq "0"
      tokens[7].get_text.should eq "0"
      tokens[8].get_text.should eq "1.23"
      tokens[9].get_text.should eq "-1.23"
      tokens[10].get_kind.should eq Kind::END_ARRAY
      tokens[11].get_kind.should eq Kind::NAME
      tokens[12].get_kind.should eq Kind::NAME
    end

    it "test empty name" do
      s = "dup 127 / put"
      t1l = Type1Lexer.new(s.to_slice)
      expect_raises(DamagedFontException, "Could not read token at position 9") do
        loop do
          token = t1l.next_token
          break if token.nil?
        end
      end
    end

    it "test proc and name and dict and string" do
      s = "/ND {noaccess def} executeonly def \n 8#173 +2#110 \n%comment \n<< (string \\n \\r \\t \\b \\f \\\\ \\( \\) \\123) >>"
      t1l = Type1Lexer.new(s.to_slice)
      read_tokens = ->(t1l : Type1Lexer) do
        tokens = [] of Token
        loop do
          token = t1l.next_token
          break if token.nil?
          tokens << token
        end
        tokens
      end
      tokens = read_tokens.call(t1l)

      tokens[0].get_kind.should eq Kind::LITERAL
      tokens[0].get_text.should eq "ND"
      tokens[1].get_kind.should eq Kind::START_PROC
      tokens[2].get_kind.should eq Kind::NAME
      tokens[2].get_text.should eq "noaccess"
      tokens[3].get_kind.should eq Kind::NAME
      tokens[3].get_text.should eq "def"
      tokens[4].get_kind.should eq Kind::END_PROC
      tokens[5].get_kind.should eq Kind::NAME
      tokens[5].get_text.should eq "executeonly"
      tokens[6].get_kind.should eq Kind::NAME
      tokens[6].get_text.should eq "def"
      tokens[7].get_kind.should eq Kind::INTEGER
      tokens[7].get_text.should eq "123"
      tokens[8].get_kind.should eq Kind::INTEGER
      tokens[8].get_text.should eq "6"
      tokens[9].get_kind.should eq Kind::START_DICT
      tokens[10].get_kind.should eq Kind::STRING
      tokens[10].get_text.should eq "string \n \n \t \b \f \\ ( ) \123"
      tokens[11].get_kind.should eq Kind::END_DICT
    end

    it "test data" do
      s = "3 RD 123 ND"
      t1l = Type1Lexer.new(s.to_slice)
      read_tokens = ->(t1l : Type1Lexer) do
        tokens = [] of Token
        loop do
          token = t1l.next_token
          break if token.nil?
          tokens << token
        end
        tokens
      end
      tokens = read_tokens.call(t1l)

      tokens[0].get_kind.should eq Kind::INTEGER
      tokens[0].int_value.should eq 3
      tokens[1].get_kind.should eq Kind::CHARSTRING
      tokens[1].get_data.should eq "123".to_slice
      tokens[2].get_kind.should eq Kind::NAME
      tokens[2].get_text.should eq "ND"
    end

    it "test PDFBOX-6043: detection of illegal string length" do
      s = "999 RD"
      t1l = Type1Lexer.new(s.to_slice)
      expect_raises(IO::Error, "String length 999 is larger than input") do
        read_tokens = ->(t1l : Type1Lexer) do
          tokens = [] of Token
          loop do
            token = t1l.next_token
            break if token.nil?
            tokens << token
          end
          tokens
        end
        read_tokens.call(t1l)
      end
    end
  end
end
