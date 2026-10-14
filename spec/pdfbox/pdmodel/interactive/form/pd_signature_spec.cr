require "../../../../spec_helper"

# Source of truth:
# vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/pdmodel/interactive/digitalsignature/PDSignature.java
#
# Characterization spec: upstream covers byte range/contents; these assertions
# cover the signature metadata accessors and are inferred from the Java behavior.
module Pdfbox::Pdmodel::Interactive::Form
  describe PDSignature do
    it "round-trips the signature metadata entries" do
      signature = PDSignature.new
      signature.name.should be_nil
      signature.location.should be_nil
      signature.reason.should be_nil
      signature.contact_info.should be_nil
      signature.filter.should be_nil
      signature.sub_filter.should be_nil
      signature.sign_date.should be_nil

      signature.name = "Alice"
      signature.location = "Paris"
      signature.reason = "Approval"
      signature.contact_info = "alice@example.com"
      signature.filter = PDSignature::FILTER_ADOBE_PPKLITE
      signature.sub_filter = PDSignature::SUBFILTER_ADBE_PKCS7_DETACHED

      signature.name.should eq("Alice")
      signature.location.should eq("Paris")
      signature.reason.should eq("Approval")
      signature.contact_info.should eq("alice@example.com")
      signature.filter.should eq("Adobe.PPKLite")
      signature.sub_filter.should eq("adbe.pkcs7.detached")

      date = Time.utc(2020, 1, 2, 3, 4, 5)
      signature.sign_date = date
      signature.sign_date.not_nil!.should eq(date)
    end

    it "round-trips contents and computes signed content over the byte range" do
      signature = PDSignature.new
      signature.set_contents(Bytes[1_u8, 2_u8, 3_u8])
      signature.contents.should eq(Bytes[1_u8, 2_u8, 3_u8])

      signature.byte_range = [0, 3, 7, 3]
      pdf = "abcdefghij".to_slice
      String.new(signature.signed_content(pdf)).should eq("abchij")
    end
  end
end
