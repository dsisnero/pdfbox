require "../../../../../spec_helper"
require "../../../../../helpers/type4_tester"

module Pdfbox::Pdmodel::Common::Function::Type4
  describe "Operators" do
    describe "add" do
      it "adds integers" do
        Spec::Helpers::Type4Tester.create("5 6 add").pop(11).is_empty
      end

      it "adds integer and real" do
        Spec::Helpers::Type4Tester.create("5 0.23 add").pop(5.23_f32).is_empty
      end

      it "handles integer overflow" do
        big_value = Int32::MAX - 2
        context = Spec::Helpers::Type4Tester.create("#{big_value} #{big_value} add").to_execution_context
        float_result = context.stack.pop
        unless float_result.is_a?(Float32)
          raise "Expected Float32, got #{float_result.class}"
        end
        expected = 2_i64 * Int32::MAX - 4
        float_result.should be_close(expected.to_f32, 1.0_f32)
        context.stack.empty?.should be_true
      end
    end

    describe "abs" do
      it "computes absolute values" do
        Spec::Helpers::Type4Tester.create("-3 abs 2.1 abs -2.1 abs -7.5 abs")
          .pop(7.5_f32).pop(2.1_f32).pop(2.1_f32).pop(3).is_empty
      end
    end

    describe "and" do
      it "performs logical AND" do
        Spec::Helpers::Type4Tester.create("true true and true false and")
          .pop(false).pop(true).is_empty
      end

      it "performs bitwise AND" do
        Spec::Helpers::Type4Tester.create("99 1 and 52 7 and")
          .pop(4).pop(1).is_empty
      end
    end

    describe "atan" do
      it "computes arctangent" do
        Spec::Helpers::Type4Tester.create("0 1 atan").pop(0_f32).is_empty
        Spec::Helpers::Type4Tester.create("1 0 atan").pop(90_f32).is_empty
        Spec::Helpers::Type4Tester.create("-100 0 atan").pop(270_f32).is_empty
        Spec::Helpers::Type4Tester.create("4 4 atan").pop(45_f32).is_empty
      end
    end

    describe "ceiling" do
      it "computes ceiling" do
        Spec::Helpers::Type4Tester.create("3.2 ceiling -4.8 ceiling 99 ceiling")
          .pop(99).pop(-4_f32).pop(4_f32).is_empty
      end
    end

    describe "cos" do
      it "computes cosine" do
        Spec::Helpers::Type4Tester.create("0 cos").pop_real(1_f32).is_empty
        Spec::Helpers::Type4Tester.create("90 cos").pop_real(0_f32).is_empty
      end
    end

    describe "cvi" do
      it "converts to integer" do
        Spec::Helpers::Type4Tester.create("-47.8 cvi").pop(-47).is_empty
        Spec::Helpers::Type4Tester.create("520.9 cvi").pop(520).is_empty
      end
    end

    describe "cvr" do
      it "converts to real" do
        Spec::Helpers::Type4Tester.create("-47.8 cvr").pop_real(-47.8_f32).is_empty
        Spec::Helpers::Type4Tester.create("520.9 cvr").pop_real(520.9_f32).is_empty
        Spec::Helpers::Type4Tester.create("77 cvr").pop_real(77_f32).is_empty
      end

      it "ensures correct data types" do
        context = Spec::Helpers::Type4Tester.create("77 77 cvr").to_execution_context
        context.stack.pop.should be_a(Float32)
        context.stack.pop.should be_a(Int32)
        context.stack.empty?.should be_true
      end
    end

    describe "div" do
      it "performs division" do
        Spec::Helpers::Type4Tester.create("3 2 div").pop_real(1.5_f32).is_empty
        Spec::Helpers::Type4Tester.create("4 2 div").pop_real(2.0_f32).is_empty
      end
    end

    describe "exp" do
      it "computes exponentiation" do
        Spec::Helpers::Type4Tester.create("9 0.5 exp").pop_real(3.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("-9 -1 exp").pop_real(-0.111111_f32, 0.000001_f32).is_empty
      end
    end

    describe "floor" do
      it "computes floor" do
        Spec::Helpers::Type4Tester.create("3.2 floor -4.8 floor 99 floor")
          .pop(99).pop(-5_f32).pop(3_f32).is_empty
      end
    end

    describe "idiv" do
      it "performs integer division" do
        Spec::Helpers::Type4Tester.create("3 2 idiv").pop(1).is_empty
        Spec::Helpers::Type4Tester.create("4 2 idiv").pop(2).is_empty
        Spec::Helpers::Type4Tester.create("-5 2 idiv").pop(-2).is_empty
      end

      it "raises on non-integer arguments" do
        expect_raises(Exception) do
          Spec::Helpers::Type4Tester.create("4.4 2 idiv")
        end
      end
    end

    describe "ln" do
      it "computes natural logarithm" do
        Spec::Helpers::Type4Tester.create("10 ln").pop_real(2.30259_f32, 0.00001_f32).is_empty
        Spec::Helpers::Type4Tester.create("100 ln").pop_real(4.60517_f32, 0.00001_f32).is_empty
      end
    end

    describe "log" do
      it "computes base-10 logarithm" do
        Spec::Helpers::Type4Tester.create("10 log").pop_real(1.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("100 log").pop_real(2.0_f32).is_empty
      end
    end

    describe "mod" do
      it "computes modulus" do
        Spec::Helpers::Type4Tester.create("5 3 mod").pop(2).is_empty
        Spec::Helpers::Type4Tester.create("5 2 mod").pop(1).is_empty
        Spec::Helpers::Type4Tester.create("-5 3 mod").pop(-2).is_empty
      end

      it "raises on non-integer arguments" do
        expect_raises(Exception) do
          Spec::Helpers::Type4Tester.create("4.4 2 mod")
        end
      end
    end

    describe "mul" do
      it "multiplies numbers" do
        Spec::Helpers::Type4Tester.create("1 2 mul").pop(2).is_empty
        Spec::Helpers::Type4Tester.create("1.5 2 mul").pop_real(3.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("1.5 2.1 mul").pop_real(3.15_f32, 0.001_f32).is_empty
      end

      it "handles integer overflow" do
        big_value = Int32::MAX - 3
        Spec::Helpers::Type4Tester.create("#{big_value} 2 mul").pop_real(2_i64 * (Int32::MAX - 3).to_f32, 0.001_f32).is_empty
      end
    end

    describe "neg" do
      it "negates numbers" do
        Spec::Helpers::Type4Tester.create("4.5 neg").pop_real(-4.5_f32).is_empty
        Spec::Helpers::Type4Tester.create("-3 neg").pop(3).is_empty
      end

      it "handles border cases" do
        border = Int32::MIN + 1
        Spec::Helpers::Type4Tester.create("#{border} neg").pop(Int32::MAX).is_empty
        Spec::Helpers::Type4Tester.create("#{Int32::MIN} neg").pop_real(-(Int32::MIN).to_f32).is_empty
      end
    end

    describe "round" do
      it "rounds numbers" do
        Spec::Helpers::Type4Tester.create("3.2 round").pop_real(3.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("6.5 round").pop_real(7.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("-4.8 round").pop_real(-5.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("-6.5 round").pop_real(-6.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("99 round").pop(99).is_empty
      end
    end

    describe "sin" do
      it "computes sine" do
        Spec::Helpers::Type4Tester.create("0 sin").pop_real(0_f32).is_empty
        Spec::Helpers::Type4Tester.create("90 sin").pop_real(1_f32).is_empty
        Spec::Helpers::Type4Tester.create("-90.0 sin").pop_real(-1_f32).is_empty
      end
    end

    describe "sqrt" do
      it "computes square root" do
        Spec::Helpers::Type4Tester.create("0 sqrt").pop_real(0_f32).is_empty
        Spec::Helpers::Type4Tester.create("1 sqrt").pop_real(1_f32).is_empty
        Spec::Helpers::Type4Tester.create("4 sqrt").pop_real(2_f32).is_empty
        Spec::Helpers::Type4Tester.create("4.4 sqrt").pop_real(2.097617_f32, 0.000001_f32).is_empty
      end

      it "raises on negative argument" do
        expect_raises(Exception) do
          Spec::Helpers::Type4Tester.create("-4.1 sqrt")
        end
      end
    end

    describe "sub" do
      it "subtracts numbers" do
        Spec::Helpers::Type4Tester.create("5 2 sub -7.5 1 sub").pop(-8.5_f32).pop(3).is_empty
      end
    end

    describe "truncate" do
      it "truncates numbers" do
        Spec::Helpers::Type4Tester.create("3.2 truncate").pop_real(3.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("-4.8 truncate").pop_real(-4.0_f32).is_empty
        Spec::Helpers::Type4Tester.create("99 truncate").pop(99).is_empty
      end
    end

    describe "bitshift" do
      it "shifts bits" do
        Spec::Helpers::Type4Tester.create("7 3 bitshift 142 -3 bitshift")
          .pop(17).pop(56).is_empty
      end
    end

    describe "eq" do
      it "performs equality comparison" do
        Spec::Helpers::Type4Tester.create("7 7 eq 7 6 eq 7 -7 eq true true eq false true eq 7.7 7.7 eq")
          .pop(true).pop(false).pop(true).pop(false).pop(false).pop(true).is_empty
      end
    end

    describe "ge" do
      it "performs greater-or-equal comparison" do
        Spec::Helpers::Type4Tester.create("5 7 ge 7 5 ge 7 7 ge -1 2 ge")
          .pop(false).pop(true).pop(true).pop(false).is_empty
      end
    end

    describe "gt" do
      it "performs greater-than comparison" do
        Spec::Helpers::Type4Tester.create("5 7 gt 7 5 gt 7 7 gt -1 2 gt")
          .pop(false).pop(false).pop(true).pop(false).is_empty
      end
    end

    describe "le" do
      it "performs less-or-equal comparison" do
        Spec::Helpers::Type4Tester.create("5 7 le 7 5 le 7 7 le -1 2 le")
          .pop(true).pop(true).pop(false).pop(true).is_empty
      end
    end

    describe "lt" do
      it "performs less-than comparison" do
        Spec::Helpers::Type4Tester.create("5 7 lt 7 5 lt 7 7 lt -1 2 lt")
          .pop(true).pop(false).pop(false).pop(true).is_empty
      end
    end

    describe "ne" do
      it "performs inequality comparison" do
        Spec::Helpers::Type4Tester.create("7 7 ne 7 6 ne 7 -7 ne true true ne false true ne 7.7 7.7 ne")
          .pop(false).pop(true).pop(false).pop(true).pop(true).pop(false).is_empty
      end
    end

    describe "not" do
      it "performs logical NOT" do
        Spec::Helpers::Type4Tester.create("true not false not")
          .pop(true).pop(false).is_empty
      end

      it "performs bitwise NOT" do
        Spec::Helpers::Type4Tester.create("52 not -37 not")
          .pop(37).pop(-52).is_empty
      end
    end

    describe "or" do
      it "performs logical OR" do
        Spec::Helpers::Type4Tester.create("true true or true false or false false or")
          .pop(false).pop(true).pop(true).is_empty
      end

      it "performs bitwise OR" do
        Spec::Helpers::Type4Tester.create("17 5 or 1 1 or")
          .pop(1).pop(21).is_empty
      end
    end

    describe "xor" do
      it "performs logical XOR" do
        Spec::Helpers::Type4Tester.create("true true xor true false xor false false xor")
          .pop(false).pop(true).pop(false).is_empty
      end

      it "performs bitwise XOR" do
        Spec::Helpers::Type4Tester.create("7 3 xor 12 3 or")
          .pop(15).pop(4).is_empty
      end
    end

    describe "if" do
      it "executes conditional if true" do
        Spec::Helpers::Type4Tester.create("true { 2 1 add } if")
          .pop(3).is_empty
      end

      it "does nothing if false" do
        Spec::Helpers::Type4Tester.create("false { 2 1 add } if")
          .is_empty
      end

      it "raises on non-boolean condition" do
        expect_raises(Exception) do
          Spec::Helpers::Type4Tester.create("0 { 2 1 add } if")
        end
      end
    end

    describe "ifelse" do
      it "executes true branch" do
        Spec::Helpers::Type4Tester.create("true { 2 1 add } { 2 1 sub } ifelse")
          .pop(3).is_empty
      end

      it "executes false branch" do
        Spec::Helpers::Type4Tester.create("false { 2 1 add } { 2 1 sub } ifelse")
          .pop(1).is_empty
      end
    end

    describe "copy" do
      it "copies stack elements" do
        Spec::Helpers::Type4Tester.create("true 1 2 3 3 copy")
          .pop(3).pop(2).pop(1)
          .pop(3).pop(2).pop(1)
          .pop(true)
          .is_empty
      end
    end

    describe "dup" do
      it "duplicates top element" do
        Spec::Helpers::Type4Tester.create("true 1 2 dup")
          .pop(2).pop(2).pop(1)
          .pop(true)
          .is_empty
        Spec::Helpers::Type4Tester.create("true dup")
          .pop(true).pop(true).is_empty
      end
    end

    describe "exch" do
      it "exchanges top two elements" do
        Spec::Helpers::Type4Tester.create("true 1 exch")
          .pop(true).pop(1).is_empty
        Spec::Helpers::Type4Tester.create("1 2.5 exch")
          .pop(1).pop(2.5_f32).is_empty
      end
    end

    describe "index" do
      it "indexes stack elements" do
        Spec::Helpers::Type4Tester.create("1 2 3 4 0 index")
          .pop(4).pop(4).pop(3).pop(2).pop(1).is_empty
        Spec::Helpers::Type4Tester.create("1 2 3 4 3 index")
          .pop(1).pop(4).pop(3).pop(2).pop(1).is_empty
      end
    end

    describe "pop" do
      it "pops elements" do
        Spec::Helpers::Type4Tester.create("1 pop 7 2 pop")
          .pop(7).is_empty
        Spec::Helpers::Type4Tester.create("1 2 3 pop pop")
          .pop(1).is_empty
      end
    end

    describe "roll" do
      it "rolls stack elements" do
        Spec::Helpers::Type4Tester.create("1 2 3 4 5 5 -2 roll")
          .pop(2).pop(1).pop(5).pop(4).pop(3).is_empty
        Spec::Helpers::Type4Tester.create("1 2 3 4 5 5 2 roll")
          .pop(3).pop(2).pop(1).pop(5).pop(4).is_empty
        Spec::Helpers::Type4Tester.create("1 2 3 3 0 roll")
          .pop(3).pop(2).pop(1).is_empty
      end
    end
  end
end
