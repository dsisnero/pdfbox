require "../../spec_helper"

describe "COSUpdateInfo behavior" do
  it "tracks need_to_be_updated only after origin document state accepts updates" do
    origin = Pdfbox::Cos::DocumentState.new
    origin.parsing = false

    dictionary = Pdfbox::Cos::Dictionary.new
    dictionary.need_to_be_updated = true
    dictionary.need_to_be_updated?.should be_false

    dictionary.update_state.origin_document_state = origin
    dictionary.need_to_be_updated = true
    dictionary.need_to_be_updated?.should be_true

    dictionary.need_to_be_updated = false
    dictionary.need_to_be_updated?.should be_false

    object = Pdfbox::Cos::Object.new(1_i64, 0_i64, nil)
    object.need_to_be_updated = true
    object.need_to_be_updated?.should be_false

    object.update_state.origin_document_state = origin
    object.need_to_be_updated = true
    object.need_to_be_updated?.should be_true

    object.need_to_be_updated = false
    object.need_to_be_updated?.should be_false
  end
end
