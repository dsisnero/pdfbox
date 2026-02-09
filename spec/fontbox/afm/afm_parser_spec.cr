require "../../spec_helper"

describe Fontbox::AFM::Parser do
  describe "#parse" do
    it "raises an error when missing StartFontMetrics" do
      expect_raises(IO::Error) do
        parser = Fontbox::AFM::Parser.new(IO::Memory.new("huhu"))
        parser.parse
      end
    end

    it "raises an error when missing EndFontMetrics" do
      expect_raises(IO::Error, "Unknown AFM key") do
        File.open("spec/resources/fontbox/afm/NoEndFontMetrics.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    it "raises an error on malformed float" do
      expect_raises(IO::Error, "4,1ab") do
        File.open("spec/resources/fontbox/afm/MalformedFloat.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    it "raises an error on malformed integer" do
      expect_raises(IO::Error, "3.4") do
        File.open("spec/resources/fontbox/afm/MalformedInteger.afm") do |io|
          parser = Fontbox::AFM::Parser.new(io)
          parser.parse
        end
      end
    end

    it "parses Helvetica font metrics" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse
        # TODO: verify font metrics
      end
    end

    it "parses Helvetica char metrics" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse
        char_metrics = font_metrics.char_metrics
        # TODO: verify char metrics
      end
    end

    it "parses Helvetica kern pairs" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse
        kern_pairs = font_metrics.kern_pairs
        # TODO: verify kern pairs
      end
    end

    it "parses Helvetica font metrics with reduced dataset" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse(true)
        # TODO: verify reduced dataset
      end
    end

    it "parses Helvetica char metrics with reduced dataset" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse(true)
        char_metrics = font_metrics.char_metrics
        # TODO: verify char metrics
      end
    end

    it "parses Helvetica kern pairs with reduced dataset (empty)" do
      File.open("spec/resources/fontbox/afm/Helvetica.afm") do |io|
        parser = Fontbox::AFM::Parser.new(io)
        font_metrics = parser.parse(true)
        font_metrics.kern_pairs.should be_empty
        font_metrics.kern_pairs0.should be_empty
        font_metrics.kern_pairs1.should be_empty
        font_metrics.composites.should be_empty
      end
    end
  end
end
