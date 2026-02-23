require "../../../spec_helper"

describe Pdfbox::Pdmodel::Font do
  describe "Encoding" do
    describe "WinAnsiEncoding" do
      it "maps space to code 32" do
        encoding = Pdfbox::Pdmodel::Font::WinAnsiEncoding::INSTANCE
        code = encoding.name_to_code_map["space"]
        code.should eq(32)
      end
    end

    describe "MacRomanEncoding" do
      it "maps space to code 32" do
        encoding = Pdfbox::Pdmodel::Font::MacRomanEncoding::INSTANCE
        code = encoding.name_to_code_map["space"]
        code.should eq(32)
      end
    end

    describe "DictionaryEncoding" do
      it "overwrites base encoding with differences" do
        # Create encoding dictionary with BaseEncoding and Differences
        dict = Pdfbox::Cos::Dictionary.new
        dict.set_item(Pdfbox::Cos::Name::TYPE, Pdfbox::Cos::Name::ENCODING)
        dict.set_item(Pdfbox::Cos::Name::BASE_ENCODING, Pdfbox::Cos::Name::WIN_ANSI_ENCODING)
        differences = Pdfbox::Cos::Array.new
        differences.add(Pdfbox::Cos::Integer.get(32))
        differences.add(Pdfbox::Cos::Name.new("a"))
        dict.set_item(Pdfbox::Cos::Name::DIFFERENCES, differences)

        encoding = Pdfbox::Pdmodel::Font::DictionaryEncoding.new(dict, false, nil)
        # Space mapping should be absent (overwritten)
        encoding.name_to_code_map["space"]?.should be_nil
        # 'a' should map to code 32
        encoding.name_to_code_map["a"]?.should eq(32)
      end
    end
  end
end
