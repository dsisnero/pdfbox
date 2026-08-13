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
