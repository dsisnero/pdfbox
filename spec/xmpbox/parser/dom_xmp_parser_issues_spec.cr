require "../../spec_helper"
require "../../../src/xmpbox"

describe Xmpbox::Xml::DomXmpParser do
  fixture_dir = File.join(__DIR__, "..", "..", "fixtures", "xmpbox")

  # Port of DomXmpParserTest.java issue-specific tests.
  describe "PDFBox issue tests" do
    it "PDFBOX-5649 parses a strict fixture" do
      path = File.join(fixture_dir, "org", "apache", "xmpbox", "xml", "PDFBOX-5649.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(File.open(path))
      xmp.should_not be_nil
    end

    it "PDFBOX-5835 parses conformance and part from a strict fixture" do
      path = File.join(fixture_dir, "org", "apache", "xmpbox", "xml", "PDFBOX-5835.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(File.open(path))
      pdfaid = xmp.pdfa_identification_schema
      pdfaid.should_not be_nil
      pdfaid.not_nil!.conformance.should eq("A")
      pdfaid.not_nil!.part.should eq(3)
    end

    it "PDFBOX-5976 parses attributes as simple properties" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <rdf:RDF
      	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      	xmlns:pdf="http://ns.adobe.com/pdf/1.3/"
      	xmlns:pdfaid="http://www.aiim.org/pdfa/ns/id/">
      	    <rdf:Description pdfaid:conformance="B" pdfaid:part="3" rdf:about=""/>
      	    <rdf:Description pdf:Producer="WeasyPrint 64.1" rdf:about=""/>
      </rdf:RDF>
      <?xpacket end="r"?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(s)
      pdfaid = xmp.pdfa_identification_schema
      pdfaid.should_not be_nil
      pdfaid.not_nil!.conformance.should eq("B")
      pdfaid.not_nil!.part.should eq(3)
    end

    it "PDFBOX-6106 raises No type defined for pdf:CreationDate in strict mode" do
      s = <<-XML
      <?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d' bytes='647'?>
      <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'
               xmlns:iX='http://ns.adobe.com/iX/1.0/'>
      	<rdf:Description about=''
      	                 xmlns='http://ns.adobe.com/pdf/1.3/'
      	                 xmlns:pdf='http://ns.adobe.com/pdf/1.3/'
      	                 pdf:CreationDate='2004-01-30T17:21:50Z'
      	                 pdf:ModDate='2004-01-30T17:21:50Z'
      	                 pdf:Producer='Acrobat Distiller 5.0.5 (Windows)'/>
      	<rdf:Description about=''
      	                 xmlns='http://ns.adobe.com/xap/1.0/'
      	                 xmlns:xap='http://ns.adobe.com/xap/1.0/'
      	                 xap:CreateDate='2004-01-30T17:21:50Z'
      	                 xap:ModifyDate='2004-01-30T17:21:50Z'
      	                 xap:MetadataDate='2004-01-30T17:21:50Z'/>
      </rdf:RDF><?xpacket end='r'?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should contain("{http://ns.adobe.com/pdf/1.3/}CreationDate")
    end

    it "PDFBOX-5288 parses namespaces declared within rdf:li elements" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Public XMP Toolkit Core 4.0  ">
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/" rdf:about="">
         <xmpMM:DocumentID>uidd:1f0e03977b90b6365a376454ffdf34a7</xmpMM:DocumentID>
         <xmpMM:History>
          <rdf:Seq>
           <rdf:li xmlns:stEvt="http://ns.adobe.com/xap/1.0/sType/ResourceEvent#">
            <rdf:Description>
             <stEvt:action>created</stEvt:action>
             <stEvt:parameters>iDRS PDF output engine 7</stEvt:parameters>
             <stEvt:when>2022-09-12T12:00:07+02:00</stEvt:when>
            </rdf:Description>
           </rdf:li>
          </rdf:Seq>
         </xmpMM:History>
        </rdf:Description>
      </rdf:RDF>
      </x:xmpmeta><?xpacket end="w"?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(s)
      xmpmm = xmp.xmp_media_management_schema
      xmpmm.should_not be_nil
      xmpmm.not_nil!.document_id.should eq("uidd:1f0e03977b90b6365a376454ffdf34a7")

      history = xmpmm.not_nil!.abstract_property("History")
      history.should_not be_nil
      history.should be_a(Xmpbox::Type::ArrayProperty)
      first = history.as(Xmpbox::Type::ArrayProperty).all_properties.first?
      first.should_not be_nil
      first.should be_a(Xmpbox::Type::ResourceEventType)
      evt = first.as(Xmpbox::Type::ResourceEventType)
      evt.action.should eq("created")
      evt.parameters.should eq("iDRS PDF output engine 7")
    end

    it "strict rejects Seq for a Bag property but lenient accepts it" do
      s = <<-XML
      <?xpacket begin='\uFEFF' id='W5M0MpCehiHzreSzNTczkc9d'?>
      <?adobe-xap-filters esc="CRLF"?>
      <x:xmpmeta xmlns:x='adobe:ns:meta/'>
      	<rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>
      		<rdf:Description xmlns:dc='http://purl.org/dc/elements/1.1/'
      		                 dc:format='application/pdf'>
      			<dc:subject>
      				<rdf:Seq>
      					<rdf:li>Important subject</rdf:li>
      					<rdf:li>Unimportant subject</rdf:li>
      				</rdf:Seq>
      			</dc:subject>
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta>
      <?xpacket end='w'?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should contain("Invalid array type, expecting Bag and found Seq")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp = lenient_parser.parse(s)
      dc = xmp.dublin_core_schema
      dc.should_not be_nil
      subjects = dc.not_nil!.unqualified_bag_value_list("subject")
      subjects.should_not be_nil
      subjects.not_nil!.size.should eq(2)
      subjects.not_nil![0].should eq("Important subject")
      subjects.not_nil![1].should eq("Unimportant subject")
    end

    it "strict rejects undefined attribute property, lenient stores it as text" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/">
      	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description xmlns:xmpTPg="http://ns.adobe.com/xap/1.0/t/pg/"
                             xmlns:stDim="http://ns.adobe.com/xap/1.0/sType/Dimensions#"
      		                 rdf:about="">
      			<xmpTPg:MaxPageSize>
      				<rdf:Description stDim:X="4" stDim:Y="3" stDim:Z="inch"/>
      			</xmpTPg:MaxPageSize>
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta><?xpacket end="r"?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should contain("{http://ns.adobe.com/xap/1.0/sType/Dimensions#}X")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp = lenient_parser.parse(s)
      page_text = xmp.xmp_page_text_schema
      page_text.should_not be_nil
      dim = page_text.not_nil!.abstract_property("MaxPageSize")
      dim.should_not be_nil
    end

    it "strict rejects undefined child property, lenient stores it as text" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/"
                 x:xmptk="3.1.1-111">
      	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      		<rdf:Description xmlns:pdf="http://ns.adobe.com/pdf/1.3/"
      		                 rdf:about="">
      			<pdf:Bad>Value</pdf:Bad>
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta><?xpacket end="r"?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should contain("{http://ns.adobe.com/pdf/1.3/}Bad")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp = lenient_parser.parse(s)
      pdf = xmp.adobe_pdf_schema
      pdf.should_not be_nil
      pdf.not_nil!.unqualified_text_property_value("Bad").should eq("Value")
    end

    it "strict rejects xapmeta root, lenient accepts it" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin='\uFEFF' id='W5M0MpCehiHzreSzNTczkc9d'?><?adobe-xap-filters esc="CR"?>
      <x:xapmeta xmlns:x="adobe:ns:meta/">
      	<rdf:RDF xmlns:iX="http://ns.adobe.com/iX/1.0/" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      	</rdf:RDF>
      </x:xapmeta><?xpacket end='w'?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should contain("Expecting local name 'xmpmeta' and found 'xapmeta'")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp2 = lenient_parser.parse(s)
      xmp2.all_schemas.size.should eq(0)
    end

    it "rejects a non-xpacket processing instruction name" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?packet begin="" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="3.1-701">
      </x:xmpmeta><?packet end="w"?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should eq("Bad processing instruction name : packet")
    end

    it "rejects content after the xpacket end" do
      s = <<-XML
      <?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>
      <?xpacket begin='' id='W5M0MpCehiHzreSzNTczkc9d'?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/">
      	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      	</rdf:RDF>
      </x:xmpmeta>
      <?xpacket end="w"?>
      <?xpacket end='r'?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should eq("xmp should end after xpacket end processing instruction")
    end

    it "rejects a wrong rdf namespace" do
      s = <<-XML
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="XXX">
          <rdf:RDF xmlns:rdf="https://www.w3.org/1999/02/22-rdf-syntax-ns#">
          </rdf:RDF>
      </x:xmpmeta><?xpacket end="w"?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should eq("Expecting namespace 'http://www.w3.org/1999/02/22-rdf-syntax-ns#' and found 'https://www.w3.org/1999/02/22-rdf-syntax-ns#'")
    end

    it "raises for a document with no content" do
      parser = Xmpbox::Xml::DomXmpParser.new
      expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(%(<?xml version="1.0" encoding="UTF-8" standalone="no"?>))
      end
    end

    it "rejects xmpmeta with no rdf:RDF child" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d" ?><x:xmpmeta xmlns:x="adobe:ns:meta/"/>
      <?xpacket end="w" ?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should eq("No rdf description found in xmp")
    end

    it "rejects text where an Alt array is expected" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/"
                 x:xmptk="3.1-701">
      	<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      		<rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/"
      		                 rdf:about="">
      			<dc:title>Title</dc:title>
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta><?xpacket end="w"?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        parser.parse(s)
      end
      ex.to_s.should eq("Invalid array definition, expecting Alt and found Text [prefix=dc; name=title]")
    end

    it "parses exif:Flash structured type with Fired boolean child" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin='\uFEFF' id='W5M0MpCehiHzreSzNTczkc9d'?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/"
                 x:xmptk="XMP toolkit 3.0-28, framework 1.6">
      	<rdf:RDF xmlns:iX="http://ns.adobe.com/iX/1.0/"
      	         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      		<rdf:Description xmlns:exif="http://ns.adobe.com/exif/1.0/"
      		                 rdf:about="uuid:d9974396-53ee-11d9-9542-81b7ec7f4613">
      			<exif:Flash rdf:parseType="Resource">
      				<exif:Fired>False</exif:Fired>
      			</exif:Flash>
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta><?xpacket end='w'?>
      XML
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(s)
      exif = xmp.schema("http://ns.adobe.com/exif/1.0/")
      exif.should_not be_nil
      flash = exif.not_nil!.abstract_property("Flash")
      flash.should be_a(Xmpbox::Type::FlashType)
      fired = flash.as(Xmpbox::Type::AbstractStructuredType).property("Fired")
      fired.should_not be_nil
      fired.should be_a(Xmpbox::Type::BooleanType)
      fired.as(Xmpbox::Type::BooleanType).string_value.should eq("false")
    end

    it "strict rejects structured type as attribute, lenient stores text" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin='\uFEFF' id='W5M0MpCehiHzreSzNTczkc9d'?>
      <x:xmpmeta xmlns:x="adobe:ns:meta/"
                 x:xmptk="XMP toolkit 2.9.1-13, framework 1.6">
      	<rdf:RDF xmlns:iX="http://ns.adobe.com/iX/1.0/"
      	         xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
      		<rdf:Description xmlns:exif="http://ns.adobe.com/exif/1.0/"
      		                 exif:FNumber="36/10"
      		                 exif:FileSource="3"
      		                 exif:Flash="1"
      		                 rdf:about="">
      		</rdf:Description>
      	</rdf:RDF>
      </x:xmpmeta><?xpacket end='r'?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should eq("The type 'Flash' in 'exif:Flash=1' is a structured or array type, but attributes are simple types")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp = lenient_parser.parse(s)
      exif = xmp.schema("http://ns.adobe.com/exif/1.0/")
      exif.should_not be_nil
      flash = exif.not_nil!.abstract_property("Flash")
      flash.should_not be_nil
      flash.as(Xmpbox::Type::TextType).string_value.should eq("1")
    end

    it "PDFBOX-6131 parses Open Choice of Integer as a pdfua integer property" do
      path = File.join(fixture_dir, "org", "apache", "xmpbox", "xml", "PDFBOX-6131-0015675.xml")
      parser = Xmpbox::Xml::DomXmpParser.new
      xmp = parser.parse(File.open(path))
      ua_schema = xmp.schema("http://www.aiim.org/pdfua/ns/id/")
      ua_schema.should_not be_nil
      ua_schema.not_nil!.integer_property_value("part").should eq(1)
    end

    it "strict rejects an undefined lowercase photoshop property, lenient stores text" do
      s = <<-XML
      <?xml version="1.0" encoding="UTF-8" standalone="no"?>
      <?xpacket begin="\uFEFF" id="W5M0MpCehiHzreSzNTczkc9d"?><x:xmpmeta xmlns:x="adobe:ns:meta/" x:xmptk="Adobe XMP Core 4.0-c316 44.253921, Sun Oct 01 2006 17:14:39">
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
              <rdf:Description xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/" rdf:about="">
                  <photoshop:headline>
                      <rdf:Seq>
                          <rdf:li/>
                      </rdf:Seq>
                  </photoshop:headline>
              </rdf:Description>
          </rdf:RDF>
      </x:xmpmeta><?xpacket end="w"?>
      XML
      strict_parser = Xmpbox::Xml::DomXmpParser.new
      ex = expect_raises(Xmpbox::Xml::XmpParsingException) do
        strict_parser.parse(s)
      end
      ex.to_s.should eq("No type defined for {http://ns.adobe.com/photoshop/1.0/}headline")

      lenient_parser = Xmpbox::Xml::DomXmpParser.new(strict_parsing: false)
      xmp = lenient_parser.parse(s)
      photoshop = xmp.photoshop_schema
      photoshop.should_not be_nil
      photoshop.not_nil!.headline.should be_nil
      prop = photoshop.not_nil!.abstract_property("headline")
      prop.should_not be_nil
      prop.as(Xmpbox::Type::TextType).string_value.should eq("")
    end
  end
end
