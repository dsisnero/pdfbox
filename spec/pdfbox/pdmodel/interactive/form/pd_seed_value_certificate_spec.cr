require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSeedValueCertificate.java
#
# Characterization spec: upstream has no dedicated test, so these assertions are
# inferred from the Java observable behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDSeedValueCertificate do
    it "has /Type /SVCert and is a direct object by default" do
      cert = PDSeedValueCertificate.new
      cert.cos_object.get_name_as_string(Cos::Name.new("Type")).should eq("SVCert")
      cert.cos_object.direct?.should be_true
    end

    it "has nil entries and false required flags by default" do
      cert = PDSeedValueCertificate.new
      cert.subject.should be_nil
      cert.issuer.should be_nil
      cert.oid.should be_nil
      cert.subject_dn.should be_nil
      cert.key_usage.should be_nil
      cert.url.should be_nil
      cert.url_type.should be_nil

      cert.subject_required?.should be_false
      cert.issuer_required?.should be_false
      cert.oid_required?.should be_false
      cert.subject_dn_required?.should be_false
      cert.key_usage_required?.should be_false
      cert.url_required?.should be_false
    end

    it "round-trips the required flags" do
      cert = PDSeedValueCertificate.new
      cert.subject_required = true
      cert.issuer_required = true
      cert.oid_required = true
      cert.subject_dn_required = true
      cert.key_usage_required = true
      cert.url_required = true

      cert.subject_required?.should be_true
      cert.issuer_required?.should be_true
      cert.oid_required?.should be_true
      cert.subject_dn_required?.should be_true
      cert.key_usage_required?.should be_true
      cert.url_required?.should be_true

      cert.subject_required = false
      cert.subject_required?.should be_false
    end

    it "round-trips subject/issuer/OID byte arrays" do
      cert = PDSeedValueCertificate.new
      a = Bytes[1_u8, 2_u8, 3_u8]
      b = Bytes[4_u8, 5_u8]

      cert.subject = [a, b]
      cert.subject.not_nil!.should eq([a, b])
      cert.add_subject(Bytes[9_u8])
      cert.subject.not_nil!.should eq([a, b, Bytes[9_u8]])
      cert.remove_subject(Bytes[4_u8, 5_u8])
      cert.subject.not_nil!.should eq([a, Bytes[9_u8]])

      cert.issuer = [a]
      cert.issuer.not_nil!.should eq([a])
      cert.add_issuer(b)
      cert.issuer.not_nil!.should eq([a, b])
      cert.remove_issuer(a)
      cert.issuer.not_nil!.should eq([b])

      cert.oid = [a]
      cert.oid.not_nil!.should eq([a])
      cert.add_oid(b)
      cert.oid.not_nil!.should eq([a, b])
      cert.remove_oid(a)
      cert.oid.not_nil!.should eq([b])
    end

    it "round-trips subject distinguished names" do
      cert = PDSeedValueCertificate.new
      cert.subject_dn = [{"cn" => "John Doe", "o" => "Doe"}, {"cn" => "John Smith"}]

      expected = [] of Hash(::String, ::String?)
      expected << {"cn" => "John Doe".as(::String?), "o" => "Doe".as(::String?)}
      expected << {"cn" => "John Smith".as(::String?)}
      cert.subject_dn.not_nil!.should eq(expected)
    end

    it "round-trips key usages and validates characters" do
      cert = PDSeedValueCertificate.new
      cert.key_usage = ["101XXXXXX"]
      cert.key_usage.not_nil!.should eq(["101XXXXXX"])

      cert.add_key_usage("X0X000000")
      cert.key_usage.not_nil!.should eq(["101XXXXXX", "X0X000000"])

      cert.add_key_usage('1', '0', 'X', '0', '0', '0', '0', '0', '0')
      cert.key_usage.not_nil!.should eq(["101XXXXXX", "X0X000000", "10X000000"])

      cert.remove_key_usage("101XXXXXX")
      cert.key_usage.not_nil!.should eq(["X0X000000", "10X000000"])

      expect_raises(ArgumentError) { cert.add_key_usage("2XXXXXXXX") }
    end

    it "round-trips URL and URLType" do
      cert = PDSeedValueCertificate.new
      cert.url = "http://example.com/enroll"
      cert.url.should eq("http://example.com/enroll")

      cert.url_type = "Browser"
      cert.url_type.should eq("Browser")
      cert.url_type = "ASSP"
      cert.url_type.should eq("ASSP")
    end
  end

  describe PDSeedValue do
    it "round-trips the certificate seed value dictionary (/Cert)" do
      seed = PDSeedValue.new
      seed.seed_value_certificate.should be_nil

      cert = PDSeedValueCertificate.new
      cert.url = "http://timestamp.example"
      seed.seed_value_certificate = cert
      seed.seed_value_certificate.not_nil!.url.should eq("http://timestamp.example")

      seed.seed_value_certificate = nil
      seed.seed_value_certificate.should be_nil
    end
  end
end
