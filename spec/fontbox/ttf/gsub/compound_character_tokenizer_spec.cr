module Fontbox::TTF::Gsub
  describe CompoundCharacterTokenizer do
    it "testTokenize_happyPath_2" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_84_93_", "_104_82_", "_104_87_",
      })
      text = "_84_112_93_104_82_61_96_102_93_104_87_110_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_84_112_93", "_104_82_", "_61_96_102_93", "_104_87_", "_110_"])
    end

    it "testTokenize_happyPath_3" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_67_112_96_", "_74_112_76_",
      })
      text = "_67_112_96_103_93_108_93_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_67_112_96_", "_103_93_108_93_"])
    end

    it "testTokenize_happyPath_4" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_67_112_96_", "_74_112_76_",
      })
      text = "_94_67_112_96_112_91_103_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_94", "_67_112_96_", "_112_91_103_"])
    end

    it "testTokenize_happyPath_5" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_67_112_", "_76_112_",
      })
      text = "_94_167_112_91_103_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_94_167_112_91_103_"])
    end

    it "testTokenize_happyPath_6" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_100_", "_101_", "_102_", "_103_", "_104_",
      })
      text = "_100_101_102_103_104_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_100_", "_101_", "_102_", "_103_", "_104_"])
    end

    it "testTokenize_happyPath_7" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_100_101_", "_102_", "_103_104_",
      })
      text = "_100_101_102_103_104_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_100_101_", "_102_", "_103_104_"])
    end

    it "testTokenize_happyPath_8" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_100_101_102_", "_101_102_", "_103_104_",
      })
      text = "_100_101_102_103_104_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_100_101_102_", "_103_104_"])
    end

    it "testTokenize_happyPath_9" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_101_102_", "_101_102_",
      })
      text = "_100_101_102_103_104_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_100", "_101_102_", "_103_104_"])
    end

    it "testTokenize_happyPath_10" do
      tokenizer = CompoundCharacterTokenizer.new(Set{
        "_201_", "_202_",
      })
      text = "_100_101_102_103_104_"

      tokens = tokenizer.tokenize(text)

      tokens.should eq(["_100_101_102_103_104_"])
    end
  end
end
