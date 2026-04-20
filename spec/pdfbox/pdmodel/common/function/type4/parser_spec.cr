require "../../../../../spec_helper"
require "../../../../../helpers/type4_tester"

module Pdfbox::Pdmodel::Common::Function::Type4
  describe "Parser" do
    it "tests parser basics" do
      Spec::Helpers::Type4Tester.create("3 4 add 2 sub").pop(5).empty?
    end

    it "tests nested blocks" do
      Spec::Helpers::Type4Tester.create("true { 2 1 add } { 2 1 sub } ifelse")
        .pop(3).empty?
      Spec::Helpers::Type4Tester.create("{ true }").pop(true).empty?
    end

    describe "parseReal" do
      it "parses float values" do
        # Test parse_real method directly
        InstructionSequenceBuilder.parse_real("0").should be_close(0.0_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("1").should be_close(1.0_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("+1").should be_close(1.0_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("-1").should be_close(-1.0_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("3.14157").should be_close(3.14157_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("-1.2").should be_close(-1.2_f32, 0.00001_f32)
        InstructionSequenceBuilder.parse_real("1.0E-5").should be_close(1.0e-5_f32, 0.00001_f32)
      end
    end

    it "tests problematic functions from PDFBOX-804" do
      # This is an example of a tint to CMYK function
      # Problems here were:
      # 1. no whitespace between "mul" and "}" (token was detected as "mul}")
      # 2. line breaks cause endless loops
      Spec::Helpers::Type4Tester.create("1 {dup dup .72 mul exch 0 exch .38 mul}\n")
        .pop(0.38_f32).pop(0_f32).pop(0.72_f32).pop(1.0_f32).empty?
    end
  end
end
