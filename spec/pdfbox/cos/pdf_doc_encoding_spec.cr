require "../../spec_helper"

describe "PDFDocEncoding" do
  deviations = [
    '\u02D8', '\u02C7', '\u02C6', '\u02D9', '\u02DD', '\u02DB', '\u02DA', '\u02DC',
    '\u2022', '\u2020', '\u2021', '\u2026', '\u2014', '\u2013', '\u0192', '\u2044',
    '\u2039', '\u203A', '\u2212', '\u2030', '\u201E', '\u201C', '\u201D', '\u2018',
    '\u2019', '\u201A', '\u2122', '\uFB01', '\uFB02', '\u0141', '\u0152', '\u0160',
    '\u0178', '\u017D', '\u0131', '\u0142', '\u0153', '\u0161', '\u017E', '\u20AC',
  ].map(&.to_s)

  it "round-trips all PDFDocEncoding deviations" do
    deviations.each do |deviation|
      cos_string = Pdfbox::Cos::String.new(deviation)
      cos_string.value.should eq(deviation)
    end
  end

  it "handles PDFBOX-3864 unicode chars under 256 not in PDFDocEncoding" do
    (0..255).each do |i|
      hex = "FEFF%04X" % i
      cs1 = Pdfbox::Cos::String.parse_hex(hex)
      cs2 = Pdfbox::Cos::String.new(cs1.value)
      cs1.should eq(cs2)
    end
  end
end
