require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValue.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueMDP.java
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueTimeStamp.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDSeedValue do
    it "has the documented defaults and /Type /SV" do
      seed = PDSeedValue.new
      seed.cos_object.get_name_as_string(Cos::Name::TYPE).should eq("SV")

      seed.filter.should be_nil
      seed.sub_filter.should be_empty
      seed.digest_method.should be_empty
      seed.v.should eq(0.0_f32)
      seed.reasons.should be_empty
      seed.legal_attestation.should be_empty
      seed.mdp.should be_nil
      seed.time_stamp.should be_nil

      seed.filter_required?.should be_false
      seed.sub_filter_required?.should be_false
      seed.digest_method_required?.should be_false
      seed.v_required?.should be_false
      seed.reason_required?.should be_false
      seed.legal_attestation_required?.should be_false
      seed.add_rev_info_required?.should be_false
    end

    it "round-trips the required flags" do
      seed = PDSeedValue.new
      seed.filter_required = true
      seed.sub_filter_required = true
      seed.digest_method_required = true
      seed.v_required = true
      seed.reason_required = true
      seed.legal_attestation_required = true
      seed.add_rev_info_required = true

      seed.filter_required?.should be_true
      seed.sub_filter_required?.should be_true
      seed.digest_method_required?.should be_true
      seed.v_required?.should be_true
      seed.reason_required?.should be_true
      seed.legal_attestation_required?.should be_true
      seed.add_rev_info_required?.should be_true

      seed.filter_required = false
      seed.filter_required?.should be_false
    end

    it "round-trips the entries" do
      seed = PDSeedValue.new

      seed.filter = Cos::Name.new("Adobe.PPKLite")
      seed.filter.should eq("Adobe.PPKLite")

      seed.sub_filter = ["adbe.pkcs7.detached"]
      seed.sub_filter.should eq(["adbe.pkcs7.detached"])

      seed.digest_method = ["SHA256"]
      seed.digest_method.should eq(["SHA256"])

      seed.v = 1.0_f32
      seed.v.should eq(1.0_f32)
    end

    it "stores reasons/legal attestation as strings (Name-only getter)" do
      seed = PDSeedValue.new

      seed.reasons = ["I am the author"]
      seed.cos_object.get_array(Cos::Name.new("Reasons")).not_nil![0]
        .as(Cos::String).value.should eq("I am the author")
      # Java getReasons() casts entries to COSName (a PDFBox inconsistency that
      # would ClassCastException); the Crystal port is lenient and yields nil.
      seed.reasons.should eq([nil])

      seed.legal_attestation = ["Content"]
      seed.cos_object.get_array(Cos::Name.new("LegalAttestation")).not_nil![0]
        .as(Cos::String).value.should eq("Content")
      seed.legal_attestation.should eq([nil])
    end

    it "rejects a disallowed digest method" do
      seed = PDSeedValue.new
      expect_raises(ArgumentError) { seed.digest_method = ["MD5"] }
    end

    it "round-trips the MDP and time stamp dictionaries" do
      seed = PDSeedValue.new

      mdp = PDSeedValueMDP.new
      mdp.p = 2
      seed.mdp = mdp
      seed.mdp.not_nil!.p.should eq(2)
      expect_raises(ArgumentError) { PDSeedValueMDP.new.p = 4 }

      time_stamp = PDSeedValueTimeStamp.new
      time_stamp.url = "http://timestamp.example"
      time_stamp.timestamp_required = true
      seed.time_stamp = time_stamp
      seed.time_stamp.not_nil!.url.should eq("http://timestamp.example")
      seed.time_stamp.not_nil!.timestamp_required?.should be_true

      seed.mdp = nil
      seed.mdp.should be_nil
    end
  end

  describe PDSignatureField do
    it "round-trips the seed value dictionary" do
      document = Pdfbox::Pdmodel::Document.new
      begin
        acro_form = PDAcroForm.new(document)
        field = PDSignatureField.new(acro_form)
        field.seed_value.should be_nil

        seed = PDSeedValue.new
        seed.filter = Cos::Name.new("Adobe.PPKLite")
        field.seed_value = seed
        field.seed_value.not_nil!.filter.should eq("Adobe.PPKLite")

        field.seed_value = nil
        field.seed_value.should be_nil
      ensure
        document.close
      end
    end
  end
end
