require "../../spec_helper"

describe Fontbox::Type1::Type1Font do
  describe ".create_with_pfb" do
    it "parses OpenSans-Regular.pfb" do
      file = ::File.new("spec/resources/fonts/OpenSans-Regular.pfb")
      begin
        font = Fontbox::Type1::Type1Font.create_with_pfb(file)

        font.version.should eq("1.10")
        font.font_name.should eq("OpenSans-Regular")
        font.full_name.should eq("Open Sans Regular")
        font.family_name.should eq("Open Sans")
        font.notice.should eq("Digitized data copyright (c) 2010-2011, Google Corporation.")
        font.fixed_pitch?.should be_false
        font.force_bold?.should be_false
        font.italic_angle.should eq(0.0_f32)
        font.weight.should eq("Book")
        font.encoding.should be_a(Fontbox::BuiltInEncoding)
        font.ascii_segment.size.should eq(4498)
        font.binary_segment.size.should eq(95911)
        font.charstrings.size.should eq(938)

        font.charstrings.each_key do |name|
          font.path(name).should_not be_nil
          font.has_glyph?(name).should be_true
        end
      ensure
        file.close
      end
    end

    it "parses DejaVuSerifCondensed.pfb with several binary segments" do
      file = ::File.new("spec/resources/fonts/DejaVuSerifCondensed.pfb")
      begin
        font = Fontbox::Type1::Type1Font.create_with_pfb(file)

        font.version.should eq("Version 2.33")
        font.font_name.should eq("DejaVuSerifCondensed")
        font.full_name.should eq("DejaVu Serif Condensed")
        font.family_name.should eq("DejaVu Serif Condensed")
        font.notice.should eq("Copyright [c] 2003 by Bitstream, Inc. All Rights Reserved.")
        font.fixed_pitch?.should be_false
        font.force_bold?.should be_false
        font.italic_angle.should eq(0.0_f32)
        font.weight.should eq("Book")
        font.encoding.should be_a(Fontbox::BuiltInEncoding)
        font.ascii_segment.size.should eq(5959)
        font.binary_segment.size.should eq(1_056_090)
        font.charstrings.size.should eq(3399)
      ensure
        file.close
      end
    end

    it "rejects empty PFB input" do
      expect_raises(Exception) do
        Fontbox::Type1::Type1Font.create_with_pfb(Bytes.empty)
      end
    end
  end
end
