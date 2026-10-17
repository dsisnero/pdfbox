require "../../spec_helper"

# Port of org.apache.pdfbox.cos.UnmodifiableCOSDictionaryTest (12 methods).
#
# Source of truth:
#   vendor/pdfbox/pdfbox/src/test/java/org/apache/pdfbox/cos/UnmodifiableCOSDictionaryTest.java
#   vendor/pdfbox/pdfbox/src/main/java/org/apache/pdfbox/cos/UnmodifiableCOSDictionary.java
#
# Java names map as: COSDictionary -> Pdfbox::Cos::Dictionary,
# COSDictionary#asUnmodifiableDictionary -> #as_unmodifiable_dictionary,
# UnsupportedOperationException -> Pdfbox::Cos::UnsupportedOperationError,
# Calendar -> Time, COSName.A -> Name.new("A"), COSName.PARAMS -> Name.new("Params").
# Java's `setItem(key, null)` (which removes the item) has no Crystal overload
# because Crystal models "absent" with `delete`; every non-null overload is
# covered here.
describe Pdfbox::Cos::UnmodifiableDictionary do
  it "testUnmodifiableCOSDictionary" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.clear }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.remove_item(Pdfbox::Cos::Name.new("A")) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.add_all(Pdfbox::Cos::Dictionary.new) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_flag(Pdfbox::Cos::Name.new("A"), 0, true) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_need_to_be_updated(true) }
  end

  it "testSetItem" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary
    standard_encoding = Pdfbox::Pdmodel::Font::Encoding::Encoding.get_instance(Pdfbox::Cos::Name::STANDARD_ENCODING).not_nil!

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_item(Pdfbox::Cos::Name.new("A"), Pdfbox::Cos::Name.new("A"))
    end
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_item(Pdfbox::Cos::Name.new("A"), standard_encoding)
    end
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_item("A", Pdfbox::Cos::Name.new("A"))
    end
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_item("A", standard_encoding)
    end
  end

  it "testSetBoolean" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_boolean(Pdfbox::Cos::Name.new("A"), true) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_boolean("A", true) }
  end

  it "testSetName" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_name(Pdfbox::Cos::Name.new("A"), "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_name("A", "A") }
  end

  it "testSetDate" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary
    calendar = Time.utc

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_date(Pdfbox::Cos::Name.new("A"), calendar) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_date("A", calendar) }
  end

  it "testSetEmbeddedDate" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary
    calendar = Time.utc

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_embedded_date(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), calendar)
    end
  end

  it "testSetString" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_string(Pdfbox::Cos::Name.new("A"), "A") }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_string("A", "A") }
  end

  it "testSetEmbeddedString" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_embedded_string(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), "A")
    end
  end

  it "testSetInt" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_int(Pdfbox::Cos::Name.new("A"), 0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_int("A", 0) }
  end

  it "testSetEmbeddedInt" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) do
      unmodifiable.set_embedded_int(Pdfbox::Cos::Name.new("Params"), Pdfbox::Cos::Name.new("A"), 0)
    end
  end

  it "testSetLong" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_long(Pdfbox::Cos::Name.new("A"), 0_i64) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_long("A", 0_i64) }
  end

  it "testSetFloat" do
    unmodifiable = Pdfbox::Cos::Dictionary.new.as_unmodifiable_dictionary

    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_float(Pdfbox::Cos::Name.new("A"), 0.0) }
    expect_raises(Pdfbox::Cos::UnsupportedOperationError) { unmodifiable.set_float("A", 0.0) }
  end
end
