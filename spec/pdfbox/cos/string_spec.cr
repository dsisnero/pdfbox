require "../../spec_helper"

describe Pdfbox::Cos::String do
  it "writes literal and hex forms based on force_hex_form" do
    esc_char_string = "( test#some) escaped< \\chars>!~1239857 "
    esc_char_string_pdf_format = "\\( test#some\\) escaped< \\\\chars>!~1239857 "

    literal = Pdfbox::Cos::String.new(esc_char_string)
    literal_out = IO::Memory.new
    literal.write_pdf(literal_out)
    String.new(literal_out.to_slice).should eq("(#{esc_char_string_pdf_format})")

    hex = Pdfbox::Cos::String.new(esc_char_string, true)
    hex_out = IO::Memory.new
    hex.write_pdf(hex_out)
    String.new(hex_out.to_slice).should eq("<#{hex.to_hex_string}>")
  end

  it "parses valid hex and rejects invalid hex" do
    expected = "Quick and simple test"
    hex = Pdfbox::Cos::String.new(expected).to_hex_string

    parsed = Pdfbox::Cos::String.parse_hex(hex)
    parsed.value.should eq(expected)

    expect_raises(Pdfbox::Error) { Pdfbox::Cos::String.parse_hex("#{hex}xx") }
  end

  it "returns empty string when parsed hex is only a BOM" do
    Pdfbox::Cos::String.parse_hex("FEFF").value.should eq("")
    Pdfbox::Cos::String.parse_hex("FFFE").value.should eq("")
  end

  it "round-trips ASCII and unicode strings" do
    ascii = "This is some regular text. It should all be expressible in ASCII"
    latin1 = "En français où les choses sont accentués. En español, así"
    high_bits = "をクリックしてく"

    Pdfbox::Cos::String.new(ascii).value.should eq(ascii)
    Pdfbox::Cos::String.new(latin1).value.should eq(latin1)
    Pdfbox::Cos::String.new(high_bits).value.should eq(high_bits)
  end

  it "returns hex representation of underlying bytes" do
    expected = "Test subject for testing getHex"
    string = Pdfbox::Cos::String.new(expected)
    string.to_hex_string.should eq("54657374207375626A65637420666F722074657374696E6720676574486578")
  end

  it "compares parsed hex strings by content and decoded value" do
    test1 = Pdfbox::Cos::String.parse_hex("000000FF000000")
    test2 = Pdfbox::Cos::String.parse_hex("000000FF00FFFF")

    test1.should eq(test1)
    test2.should eq(test2)
    test1.to_hex_string.should_not eq(test2.to_hex_string)
    test1.bytes.should_not eq(test2.bytes)
    test1.should_not eq(test2)
    test1.value.should_not eq(test2.value)
  end

  it "returns raw bytes for escaped-character strings" do
    esc_char_string = "( test#some) escaped< \\chars>!~1239857 "
    string = Pdfbox::Cos::String.new(esc_char_string)
    String.new(string.bytes).should eq(esc_char_string)
  end

  it "accepts a COS writer visitor" do
    esc_char_string = "( test#some) escaped< \\chars>!~1239857 "
    esc_char_string_pdf_format = "\\( test#some\\) escaped< \\\\chars>!~1239857 "
    output = IO::Memory.new
    visitor = Pdfbox::Pdfwriter::COSWriter.new(output)

    literal = Pdfbox::Cos::String.new(esc_char_string)
    literal.accept(visitor)
    String.new(output.to_slice).should eq("(#{esc_char_string_pdf_format})")

    output.clear
    forced_hex = Pdfbox::Cos::String.new(esc_char_string, true)
    forced_hex.accept(visitor)
    String.new(output.to_slice).should eq("<#{forced_hex.to_hex_string}>")
  end

  it "writes ASCII as literal and non-ASCII as hex" do
    ascii = Pdfbox::Cos::String.new("This is some regular text. It should all be expressible in ASCII")
    ascii_out = IO::Memory.new
    ascii.write_pdf(ascii_out)
    String.new(ascii_out.to_slice).should eq("(This is some regular text. It should all be expressible in ASCII)")

    text8bit = Pdfbox::Cos::String.new("En français où les choses sont accentués. En español, así")
    text8bit_out = IO::Memory.new
    text8bit.write_pdf(text8bit_out)
    String.new(text8bit_out.to_slice).should eq("<#{text8bit.to_hex_string}>")

    high_bits = Pdfbox::Cos::String.new("をクリックしてく")
    high_bits_out = IO::Memory.new
    high_bits.write_pdf(high_bits_out)
    String.new(high_bits_out.to_slice).should eq("<#{high_bits.to_hex_string}>")
  end

  it "writes strings containing end-of-line bytes as hex" do
    line_feed = Pdfbox::Cos::String.new("Line1\nLine2\nLine3\n")
    output = IO::Memory.new
    line_feed.write_pdf(output)
    String.new(output.to_slice).should eq("<#{line_feed.to_hex_string}>")
  end

  it "includes force_hex_form in equality and hash comparisons" do
    literal = Pdfbox::Cos::String.new("Test1")
    same_literal = Pdfbox::Cos::String.new("Test1")
    forced_hex = Pdfbox::Cos::String.new("Test1", true)

    literal.should eq(same_literal)
    literal.hash.should eq(same_literal.hash)

    literal.should_not eq(forced_hex)
    literal.hash.should_not eq(forced_hex.hash)
  end
end
