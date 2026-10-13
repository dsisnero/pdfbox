require "../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/PDFontSetting.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/state/PDExtendedGraphicsState.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Graphics
  private def self.type1_font_dict : Cos::Dictionary
    dict = Cos::Dictionary.new
    dict[Cos::Name::TYPE] = Cos::Name::FONT
    dict[Cos::Name::SUBTYPE] = Cos::Name.new("Type1")
    dict[Cos::Name::BASE_FONT] = Cos::Name.new("Helvetica")
    dict
  end

  describe PDFontSetting do
    it "defaults to a null font and size 1 in a two-element array" do
      setting = PDFontSetting.new
      setting.font.should be_nil
      setting.font_size.should eq(1.0_f32)

      array = setting.cos_object.as(Cos::Array)
      array.size.should eq(2)
      array[0].should be_a(Cos::Null)
      array[1].as(Cos::Float).value.should eq(1.0)
    end

    it "constructs from an existing array and resolves the font" do
      dict = type1_font_dict
      array = Cos::Array.new
      array.add(dict)
      array.add(Cos::Float.new(12.0))

      setting = PDFontSetting.new(array)
      setting.font_size.should eq(12.0_f32)

      font = setting.font.not_nil!
      font.should be_a(Pdfbox::Pdmodel::Font::PDType1Font)
      font.cos_object.should be(dict)
    end

    it "round-trips the font and size" do
      setting = PDFontSetting.new
      font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(type1_font_dict)

      setting.font = font
      setting.font.not_nil!.cos_object.should be(font.cos_object)

      setting.font_size = 9.5_f32
      setting.font_size.should eq(9.5_f32)

      setting.font = nil
      setting.font.should be_nil
      setting.cos_object.as(Cos::Array)[0].should be_a(Cos::Null)
    end
  end

  describe "PDExtendedGraphicsState font setting" do
    it "round-trips /Font through a PDFontSetting" do
      gs = State::PDExtendedGraphicsState.new
      gs.font_setting.should be_nil

      setting = PDFontSetting.new
      setting.font = Pdfbox::Pdmodel::Font::PDFontFactory.create_font(type1_font_dict)
      setting.font_size = 14.0_f32

      gs.font_setting = setting
      resolved = gs.font_setting.not_nil!
      resolved.font.not_nil!.should be_a(Pdfbox::Pdmodel::Font::PDType1Font)
      resolved.font_size.should eq(14.0_f32)

      gs.font_setting = nil
      gs.font_setting.should be_nil
    end
  end
end
