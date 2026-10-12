require "../../spec_helper"

module Fontbox::CFF
  # Test reader: maps glyph names to Type1CharString objects.
  class SeacTestReader < Type1CharStringReader
    getter glyphs = {} of String => Type1CharString

    def register(name : String, charstring : Type1CharString) : Nil
      glyphs[name] = charstring
    end

    def type1_char_string(name : String) : Type1CharString
      glyphs[name]
    end
  end

  describe Type1CharString do
    commands_of = ->(path : Fontbox::Util::Path) do
      commands = [] of Tuple(Symbol, Array(Float64))
      path.each_command { |kind, points| commands << {kind, points} }
      commands
    end

    it "renders seac (Standard Encoding Accented Character)" do
      reader = SeacTestReader.new

      base = Type1CharString.new(reader, "TestFont", "A", [
        100, 0, 500, CharStringCommand::SBW,
        0, 0, CharStringCommand::RMOVETO,
        50, 50, CharStringCommand::RLINETO,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      accent = Type1CharString.new(reader, "TestFont", "acute", [
        110, 0, 260, CharStringCommand::SBW,
        0, 0, CharStringCommand::RMOVETO,
        10, 30, CharStringCommand::RLINETO,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      reader.register("A", base)
      reader.register("acute", accent)

      cs = Type1CharString.new(reader, "TestFont", "Aacute", [
        50, 0, 400, CharStringCommand::SBW,
        20, 15, -5, 65, 194, CharStringCommand::SEAC,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)

      commands_of.call(cs.path).should eq([
        {:move_to, [100.0, 0.0]},  # base "A" appended untranslated
        {:line_to, [150.0, 50.0]}, #   (rmoveto 0,0 then rlineto 50,50 from lsb (100,0))
        {:move_to, [155.0, -5.0]}, # accent translated by lsb.x+adx-asb = 50+15-20
        {:line_to, [165.0, 25.0]}, #   and lsb.y+ady = 0-5
      ] of Tuple(Symbol, Array(Float64)))
    end

    it "does not mutate the accent charstring path when rendering seac" do
      reader = SeacTestReader.new

      base = Type1CharString.new(reader, "TestFont", "A", [
        100, 0, 500, CharStringCommand::SBW,
        0, 0, CharStringCommand::RMOVETO,
        50, 50, CharStringCommand::RLINETO,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      accent = Type1CharString.new(reader, "TestFont", "acute", [
        110, 0, 260, CharStringCommand::SBW,
        0, 0, CharStringCommand::RMOVETO,
        10, 30, CharStringCommand::RLINETO,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      reader.register("A", base)
      reader.register("acute", accent)

      cs = Type1CharString.new(reader, "TestFont", "Aacute", [
        50, 0, 400, CharStringCommand::SBW,
        20, 15, -5, 65, 194, CharStringCommand::SEAC,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)

      cs.path
      commands_of.call(accent.path).should eq([
        {:move_to, [110.0, 0.0]},
        {:line_to, [120.0, 30.0]},
      ] of Tuple(Symbol, Array(Float64)))
    end

    it "ignores a self-referencing seac accent (PDFBOX-5339) without recursing" do
      reader = SeacTestReader.new

      base = Type1CharString.new(reader, "TestFont", "a", [
        130, 0, 300, CharStringCommand::SBW,
        0, 0, CharStringCommand::RMOVETO,
        40, 60, CharStringCommand::RLINETO,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      reader.register("a", base)

      # The glyph's own seac references "acute" (code 194) which is itself.
      cs = Type1CharString.new(reader, "TestFont", "acute", [
        110, 0, 260, CharStringCommand::SBW,
        200, 1, 2, 97, 194, CharStringCommand::SEAC,
        CharStringCommand::ENDCHAR,
      ] of CharStringCommand | Int32 | Float64)
      reader.register("acute", cs)

      # must terminate and contain only the base glyph path (accent == path, ignored)
      commands_of.call(cs.path).should eq([
        {:move_to, [130.0, 0.0]},
        {:line_to, [170.0, 60.0]},
      ] of Tuple(Symbol, Array(Float64)))
    end
  end
end
