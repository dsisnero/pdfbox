require "../../spec_helper"

module Fontbox::CFF
  describe CharStringCommand do
    it "test_value" do
      CharStringCommand::HSTEM.value.should eq 1
      CharStringCommand::ESCAPE.value.should eq 12
      CharStringCommand::DOTSECTION.value.should eq (12 << 4) + 0
      CharStringCommand::AND.value.should eq (12 << 4) + 3
      CharStringCommand::HSBW.value.should eq 13
    end

    it "test_char_string_command" do
      char_string_command1 = CharStringCommand.get_instance(1)
      char_string_command1.type1_keyword.should eq CharStringCommand::Type1KeyWord::HSTEM
      char_string_command1.type2_keyword.should eq CharStringCommand::Type2KeyWord::HSTEM
      char_string_command1.to_s.should eq "HSTEM|"

      char_string_command12_0 = CharStringCommand.get_instance(12, 0)
      char_string_command12_0.type1_keyword.should eq CharStringCommand::Type1KeyWord::DOTSECTION
      char_string_command12_0.type2_keyword.should be_nil
      char_string_command12_0.to_s.should eq "DOTSECTION|"

      values12_3 = [12, 3]
      char_string_command12_3 = CharStringCommand.get_instance(values12_3)
      char_string_command12_3.type1_keyword.should be_nil
      char_string_command12_3.type2_keyword.should eq CharStringCommand::Type2KeyWord::AND
      char_string_command12_3.to_s.should eq "AND|"
    end

    it "test_unknown_char_string_command" do
      char_string_command_unknown = CharStringCommand.get_instance(99)
      char_string_command_unknown.to_s.should eq "unknown command|"
    end
  end
end
