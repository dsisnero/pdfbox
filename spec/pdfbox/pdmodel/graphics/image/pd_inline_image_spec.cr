# Port of org.apache.pdfbox.pdmodel.graphics.image.PDInlineImageTest
# (model-level assertions from testInlineImage and doInlineCcittImage;
# AWT BufferedImage/ImageIO rendering assertions are out of scope)
require "../../../../spec_helper"

describe Pdfbox::Pdmodel::Graphics::Image::PDInlineImage do
  it "testInlineImage - model getters from parameters dict" do
    dict = Pdfbox::Cos::Dictionary.new
    dict.set_boolean("IM", true)
    width = 31
    height = 27
    dict.set_int("W", width)
    dict.set_int("H", height)
    dict.set_int("BPC", 1)

    rowbytes = width // 8
    rowbytes += 1 if rowbytes * 8 < width
    datalen = rowbytes * height
    data = Bytes.new(datalen)
    data.each_index do |i|
      data[i] = (i // 4 % 2 == 0) ? 0b10101010_u8 : 0_u8
    end

    resources = Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, data, resources)

    inline_image.stencil?.should be_true
    inline_image.width.should eq(width)
    inline_image.height.should eq(height)
    inline_image.bits_per_component.should eq(1)
  end

  it "testInlineImage - getCOSObject returns the parameters dict" do
    dict = Pdfbox::Cos::Dictionary.new
    dict.set_boolean("IM", true)
    dict.set_int("W", 31)
    dict.set_int("H", 27)
    dict.set_int("BPC", 1)

    resources = Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes[1, 2, 3], resources)
    inline_image.cos_object.should eq(dict)
  end

  it "testInlineImage - empty? false with data" do
    dict = Pdfbox::Cos::Dictionary.new
    dict.set_boolean("IM", true)
    dict.set_int("W", 1)
    dict.set_int("H", 1)
    dict.set_int("BPC", 1)

    resources = Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes[0xFF], resources)
    inline_image.empty?.should be_false

    empty = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes.empty, resources)
    empty.empty?.should be_true
  end

  it "doInlineCcittImage - model getters and color space" do
    width = 23
    height = 10
    dict = Pdfbox::Cos::Dictionary.new
    dict.set_int("W", width)
    dict.set_int("H", height)
    dict.set_int("BPC", 1)
    decode_array = Pdfbox::Cos::Array.new
    decode_array.add(Pdfbox::Cos::Integer::ONE)
    decode_array.add(Pdfbox::Cos::Integer::ZERO)
    dict.set_item("D", decode_array)
    dict.set_boolean("IM", true)
    dict.set_item("F", Pdfbox::Cos::Name.new("CCF"))
    columns = Pdfbox::Cos::Dictionary.new
    columns.set_int("Columns", width)
    dict.set_item("DP", columns)

    ba = Bytes[8, 0x10, 0x20, 0x40, 0x81, 2, 4, 8, 0x10, 0, 0x40, 4, 0, 0x40, 4, 0, 0x40, 4]
    resources = Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, ba, resources)

    inline_image.stencil?.should be_true
    inline_image.empty?.should be_false
    inline_image.interpolate?.should be_false
    inline_image.cos_object.should eq(dict)
    inline_image.color_space.should eq(Pdfbox::Pdmodel::Graphics::Color::PDDeviceGray::INSTANCE)
    inline_image.bits_per_component.should eq(1)
    inline_image.suffix.should eq("tiff")
  end

  it "getSuffix - no filter is png, DCT is jpg" do
    resources = Pdfbox::Pdmodel::PDResources.new(Pdfbox::Cos::Dictionary.new)

    dict = Pdfbox::Cos::Dictionary.new
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes[1, 2, 3], resources)
    inline_image.suffix.should eq("png")

    dict.set_item("F", Pdfbox::Cos::Name.new("DCTDecode"))
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes[1, 2, 3], resources)
    inline_image.suffix.should eq("jpg")

    dict.set_item("F", Pdfbox::Cos::Name.new("CCITTFaxDecode"))
    inline_image = Pdfbox::Pdmodel::Graphics::Image::PDInlineImage.new(dict, Bytes[1, 2, 3], resources)
    inline_image.suffix.should eq("tiff")
  end
end
