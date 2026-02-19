require "../../spec_helper"

describe Pdfbox::Cos::UnmodifiableDictionary do
  it "raises UnsupportedOperationError for mutation methods" do
    dict = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.clear }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.remove_item(Pdfbox::Cos::Name.new("A")) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.add_all(Pdfbox::Cos::Dictionary.new) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_flag(Pdfbox::Cos::Name.new("A"), 1, true) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.need_to_be_updated = true }

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_item(Pdfbox::Cos::Name.new("A"), Pdfbox::Cos::Name.new("A")) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_item("A", Pdfbox::Cos::Name.new("A")) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_boolean(Pdfbox::Cos::Name.new("A"), true) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_boolean("A", true) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_name(Pdfbox::Cos::Name.new("A"), "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_name("A", "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_date(Pdfbox::Cos::Name.new("A"), Time.utc) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_date("A", Time.utc) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_embedded_date(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), Time.utc) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_string(Pdfbox::Cos::Name.new("A"), "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_string("A", "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_embedded_string(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_int(Pdfbox::Cos::Name.new("A"), 0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_int("A", 0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_embedded_int(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), 0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_long(Pdfbox::Cos::Name.new("A"), 0_i64) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_long("A", 0_i64) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_float(Pdfbox::Cos::Name.new("A"), 0.0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { dict.set_float("A", 0.0) }
  end
end
