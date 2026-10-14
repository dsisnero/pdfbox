require "../../../../spec_helper"

# Source of truth:
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/graphics/color/PDOutputIntent.java
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/pdmodel/TestPDDocumentCatalog.java#handleOutputIntents
#
# Characterization spec: the upstream test only exercises construction and the
# string accessors; the destination output profile stream (getDestOutputIntent)
# is asserted here from the Java observable behavior.
module Pdfbox::Pdmodel
  describe OutputIntent do
    it "stores a decodable Flate destination output profile (Java getDestOutputIntent)" do
      doc = Document.new
      icc = File.read(SpecPaths.resolve("spec/resources/pdfbox/pdmodel/sRGB.icc")).to_slice

      intent = OutputIntent.create(doc, icc)

      stream = intent.dest_output_intent
      stream.should_not be_nil
      # Java PDOutputIntent(doc, colorProfile) creates a PDStream with FLATE_DECODE,
      # so the stored bytes inflate back to the ICC profile.
      stream.not_nil!.create_input_stream.gets_to_end.to_slice.should eq(icc)
      stream.not_nil!.get_int(Cos::Name.new("N"), 0).should eq(3)
    end

    it "returns nil when there is no destination output profile" do
      OutputIntent.new.dest_output_intent.should be_nil
    end

    it "round-trips the string accessors" do
      intent = OutputIntent.new
      intent.info = "sRGB IEC61966-2.1"
      intent.output_condition = "sRGB IEC61966-2.1"
      intent.output_condition_identifier = "sRGB IEC61966-2.1"
      intent.registry_name = "http://www.color.org"

      intent.info.should eq("sRGB IEC61966-2.1")
      intent.output_condition.should eq("sRGB IEC61966-2.1")
      intent.output_condition_identifier.should eq("sRGB IEC61966-2.1")
      intent.registry_name.should eq("http://www.color.org")
    end
  end
end
