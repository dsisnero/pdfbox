require "../../spec_helper"

# Port of org.apache.pdfbox.cos.TestCOSUpdateInfo.
#
# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/cos/TestCOSUpdateInfo.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/COSUpdateInfo.java
#
# COSUpdateState itself (linking the origin document state, the mutation hooks of
# COSDictionary/COSArray and the dereferencing hook of COSObject) is covered by
# spec/pdfbox/cos/update_state_spec.cr.
describe "Pdfbox::Cos COSUpdateInfo behavior" do
  it "TestCOSUpdateInfo#testIsSetNeedToBeUpdate" do
    origin = Pdfbox::Cos::DocumentState.new
    origin.parsing = false

    # COSDictionary
    test_cos_dictionary = Pdfbox::Cos::Dictionary.new
    test_cos_dictionary.set_need_to_be_updated(true)
    test_cos_dictionary.need_to_be_updated?.should be_false
    test_cos_dictionary.update_state.origin_document_state = origin
    test_cos_dictionary.set_need_to_be_updated(true)
    test_cos_dictionary.need_to_be_updated?.should be_true
    test_cos_dictionary.set_need_to_be_updated(false)
    test_cos_dictionary.need_to_be_updated?.should be_false

    # COSObject
    test_cos_object = Pdfbox::Cos::Object.new(1_i64, 0_i64, nil)
    test_cos_object.set_need_to_be_updated(true)
    test_cos_object.need_to_be_updated?.should be_false
    test_cos_object.update_state.origin_document_state = origin
    test_cos_object.set_need_to_be_updated(true)
    test_cos_object.need_to_be_updated?.should be_true
    test_cos_object.set_need_to_be_updated(false)
    test_cos_object.need_to_be_updated?.should be_false
  end
end
