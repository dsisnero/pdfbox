require "../../../../spec_helper"

# Source of truth: vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/graphics/image/PNGConverterTest.java
# Source of truth: vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/image/PNGConverter.java
# Model surface parity: the pure PNG logic — CRC-32 reference implementation, Chunk#getData
# slicing, checkChunkSane (CRC + bounds), checkConverterState (chunk-set sanity), and
# mapPNGRenderIntent (PNG sRGB intent -> PDF /Intent name). The convertPNGImage image paths
# (RGB/indexed XObject building with ICC profiles and soft masks) are a separate port; the
# AWT BufferedImage/ImageIO pixel comparisons are out of scope.
describe Pdfbox::Pdmodel::Graphics::Image::PNGConverter do
  it "computes the PNG CRC-32 reference values" do
    b1 = "Hello World!".to_slice
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.crc(b1, 0, b1.size).should eq(472456355)
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.crc(b1, 2, b1.size - 4).should eq(-632335482)
  end

  it "rejects a null or empty converter state" do
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(nil).should be_false
    state = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::PNGConverterState.new
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
  end

  it "checks chunk sanity against bounds, type offset and CRC" do
    invalid_chunk = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk.new
    invalid_chunk.bytes = Bytes.new(0)
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(invalid_chunk).should be_false

    valid_chunk = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk.new
    valid_chunk.bytes = Bytes.new(16)
    valid_chunk.start = 4
    valid_chunk.length = 8
    valid_chunk.crc = 2077607535
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(valid_chunk).should be_true
  end

  it "validates converter state through the chunk set" do
    invalid_chunk = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk.new
    invalid_chunk.bytes = Bytes.new(0)

    valid_chunk = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk.new
    valid_chunk.bytes = Bytes.new(16)
    valid_chunk.start = 4
    valid_chunk.length = 8
    valid_chunk.crc = 2077607535

    state = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::PNGConverterState.new
    state.ihdr = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false

    state.idats = [valid_chunk]
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false

    state.ihdr = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.idats = [] of Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false

    state.idats = [valid_chunk]
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.plte = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.plte = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.chrm = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.chrm = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.trns = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.trns = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.iccp = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.iccp = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.srgb = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.srgb = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.gama = invalid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
    state.gama = valid_chunk
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_true

    state.idats = [valid_chunk, invalid_chunk]
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_converter_state(state).should be_false
  end

  it "extracts chunk data within bounds" do
    chunk = Pdfbox::Pdmodel::Graphics::Image::PNGConverter::Chunk.new
    chunk.bytes = "IHDRsomedummyvaluesDummyValuesAtEnd".to_slice
    chunk.length = 19
    chunk.bytes.size.should eq(35)

    String.new(chunk.data).should eq("IHDRsomedummyvalues")

    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(chunk).should be_false
    chunk.start = 4
    String.new(chunk.data).should eq("somedummyvaluesDumm")
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(chunk).should be_false

    chunk.crc = -1729802258
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(chunk).should be_true

    chunk.start = 6
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(chunk).should be_false

    chunk.length = 60
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.check_chunk_sane(chunk).should be_false
  end

  it "maps PNG render intents to PDF /Intent names" do
    n = Pdfbox::Cos::Name
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(0).should eq(n.new("Perceptual"))
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(1).should eq(n.new("RelativeColorimetric"))
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(2).should eq(n.new("Saturation"))
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(3).should eq(n.new("AbsoluteColorimetric"))
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(-1).should be_nil
    Pdfbox::Pdmodel::Graphics::Image::PNGConverter.map_png_render_intent(4).should be_nil
  end
end

# Ports the structural (non-AWT) assertions of PNGConverterTest's
# checkImageConvert / checkImageConvertFail helpers: the produced XObject's
# color space, decode parameters, indexed lookup, soft mask and unsupported-type
# behavior. The Java test's BufferedImage / ImageIO pixel comparisons and the
# exact JDK sRGB profile byte comparison are render/ICC advisory.
private def png_fixture(name : String) : Bytes
  dir = SpecPaths.resolve("vendor/pdfbox/pdfbox/src/test/resources/org/apache/pdfbox/pdmodel/graphics/image")
  ::File.read(::File.join(dir, name)).to_slice
end

private def png_decode_parms(image : Pdfbox::Pdmodel::Graphics::Image::PDImageXObject) : Pdfbox::Cos::Dictionary
  image.cos_object.get_dictionary(Pdfbox::Cos::Name.new("DecodeParms")) ||
    raise "no DecodeParms"
end

describe "#convert_png_image" do
  n = Pdfbox::Cos::Name

  it "converts a truecolor PNG to a DeviceRGB Flate XObject" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture("png.png"))
      image.should_not be_nil
      img = image.not_nil!
      img.width.should eq(343)
      img.height.should eq(287)
      img.bits_per_component.should eq(8)
      img.color_space.should be(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      img.suffix.should eq("png")
      png_decode_parms(img).get_int(n.new("Predictor"), 0).should eq(15)
      png_decode_parms(img).get_int(n.new("Colors"), 0).should eq(3)
      png_decode_parms(img).get_int(n.new("Columns"), 0).should eq(343)
      png_decode_parms(img).get_int(n.new("BitsPerComponent"), 0).should eq(8)
    ensure
      doc.close
    end
  end

  it "accepts a gAMA chunk of 2.2 (testImageConversionRGBGamma)" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture("png_rgb_gamma.png"))
      image.should_not be_nil
      image.not_nil!.width.should eq(100)
      image.not_nil!.color_space.should be(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
    ensure
      doc.close
    end
  end

  it "uses an ICCBased color space from the iCCP chunk (testImageConversionRGB16BitICC)" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture("png_rgb_romm_16bit.png"))
      image.should_not be_nil
      cs = image.not_nil!.color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDICCBased)
      cs.name.should eq("ICCBased")
      cs.number_of_components.should eq(3)
      image.not_nil!.bits_per_component.should eq(16)
    ensure
      doc.close
    end
  end

  it "converts a non-transparent indexed PNG to an Indexed XObject (testImageConversionRGBIndexed)" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture("png_indexed.png"))
      image.should_not be_nil
      cs = image.not_nil!.color_space
      cs.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDIndexed)
      indexed = cs.as(Pdfbox::Pdmodel::Graphics::Color::PDIndexed)
      indexed.base_color_space.should be(Pdfbox::Pdmodel::Graphics::Color::PDDeviceRGB::INSTANCE)
      indexed.high_value.should be > 0
      png_decode_parms(image.not_nil!).get_int(n.new("Colors"), 0).should eq(1)
      image.not_nil!.cos_object[n.new("SMask")]?.should be_nil
    ensure
      doc.close
    end
  end

  it "adds a DeviceGray soft mask for indexed PNGs with a tRNS chunk" do
    ["png_indexed_1bit_alpha.png", "png_indexed_2bit_alpha.png",
     "png_indexed_4bit_alpha.png", "png_indexed_8bit_alpha.png"].each do |name|
      doc = Pdfbox::Pdmodel::Document.create
      begin
        image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture(name))
        image.should_not be_nil
        image.not_nil!.color_space.should be_a(Pdfbox::Pdmodel::Graphics::Color::PDIndexed)

        smask = image.not_nil!.cos_object[n.new("SMask")]?
        smask.should_not be_nil
        mask = smask.not_nil!
        mask = mask.object if mask.is_a?(Pdfbox::Cos::Object)
        mask.should be_a(Pdfbox::Cos::Stream)
        stream = mask.as(Pdfbox::Cos::Stream)
        stream.get_int(n.new("BitsPerComponent"), 0).should eq(8)
        stream.get_int(n.new("Width"), 0).should eq(image.not_nil!.width)
        stream.get_int(n.new("Height"), 0).should eq(image.not_nil!.height)
      ensure
        doc.close
      end
    end
  end

  it "tags an sRGB indexed PNG with the Perceptual intent and ICCBased base (testImageConversionIntentIndexed)" do
    doc = Pdfbox::Pdmodel::Document.create
    begin
      image = Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture("929316.png"))
      image.should_not be_nil
      image.not_nil!.cos_object[n.new("Intent")].should eq(n.new("Perceptual"))

      cs = image.not_nil!.color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDIndexed)
      cs.name.should eq("Indexed")
      base = cs.base_color_space.as(Pdfbox::Pdmodel::Graphics::Color::PDICCBased)
      base.name.should eq("ICCBased")
      base.number_of_components.should eq(3)
    ensure
      doc.close
    end
  end

  it "returns nil for unsupported PNG color types (checkImageConvertFail)" do
    ["png_alpha_rgb.png", "png_alpha_gray.png", "png_gray.png", "png_gray_with_gama.png"].each do |name|
      doc = Pdfbox::Pdmodel::Document.create
      begin
        Pdfbox::Pdmodel::Graphics::Image::PNGConverter.convert_png_image(doc, png_fixture(name)).should be_nil
      ensure
        doc.close
      end
    end
  end
end
