require "../../../../spec_helper"
require "../../../../../src/pdfbox"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/interactive/action/PDActionURITest.java
# PDFBOX-3913: URIs encoded in UTF-8/UTF-16 (BE/LE) are supported.
# PDFBOX-3946: no NPE if URI missing.
describe Pdfbox::Pdmodel::Interactive::Action::PDActionURI do
  it "PDActionURITest#testUTF8URI" do
    action_uri = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    action_uri.uri.should be_nil
    action_uri.uri = "http://çµ„åŒ¶æ›¿ç¶Ž.com/"
    action_uri.uri.should eq("http://経営承継.com/")
  end

  it "PDActionURITest#testUTF16BEURI" do
    action_uri = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    utf16_uri = Pdfbox::Cos::String.parse_hex(
      "FEFF0068007400740070003A002F002F00770077" \
      "0077002E006E00610070002E006500640075002F0063006100740061006C006F0067" \
      "002F00310031003100340030002E00680074006D006C"
    )
    action_uri.cos_object[Pdfbox::Cos::Name.new("URI")] = utf16_uri
    action_uri.uri.should eq("http://www.nap.edu/catalog/11140.html")
  end

  it "PDActionURITest#testUTF16LEURI" do
    action_uri = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    utf16_uri = Pdfbox::Cos::String.parse_hex("FFFE68007400740070003A00")
    action_uri.cos_object[Pdfbox::Cos::Name.new("URI")] = utf16_uri
    action_uri.uri.should eq("http:")
  end

  it "PDActionURITest#testUTF7URI" do
    action_uri = Pdfbox::Pdmodel::Interactive::Action::PDActionURI.new
    action_uri.uri = "http://pdfbox.apache.org/"
    action_uri.uri.should eq("http://pdfbox.apache.org/")
  end
end
