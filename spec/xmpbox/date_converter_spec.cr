require "../spec_helper"
require "../../src/xmpbox"

describe Xmpbox::DateConverter do
  it "parses partial dates" do
    conv = Xmpbox::DateConverter.to_calendar("2015")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)

    conv = Xmpbox::DateConverter.to_calendar("2015-05")
    conv.should_not be_nil
    conv.not_nil!.month.should eq(5)

    conv = Xmpbox::DateConverter.to_calendar("2015-05-02T12:00:00")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)
    conv.not_nil!.month.should eq(5)
    conv.not_nil!.day.should eq(2)
  end

  it "parses PDF-style dates with D: prefix" do
    conv = Xmpbox::DateConverter.to_calendar("D:2015-02-02T10:11:12")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)
    conv.not_nil!.month.should eq(2)
    conv.not_nil!.day.should eq(2)
    conv.not_nil!.hour.should eq(10)
    conv.not_nil!.minute.should eq(11)
    conv.not_nil!.second.should eq(12)

    conv = Xmpbox::DateConverter.to_calendar("D:2015-02-02")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)
  end

  it "parses dates with UTC timezone" do
    conv = Xmpbox::DateConverter.to_calendar("2015-02-03T10:11:12Z")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)
    conv.not_nil!.month.should eq(2)
    conv.not_nil!.day.should eq(3)
    conv.not_nil!.hour.should eq(10)
    conv.not_nil!.minute.should eq(11)
    conv.not_nil!.second.should eq(12)
    conv.not_nil!.utc?.should be_true
  end

  it "parses dates with timezone offsets" do
    conv = Xmpbox::DateConverter.to_calendar("2015-02-03T10:11:12+05:00")
    conv.should_not be_nil
    conv.not_nil!.offset.should eq(5 * 3600)

    conv = Xmpbox::DateConverter.to_calendar("2015-02-03T10:11:12-05:00")
    conv.should_not be_nil
    conv.not_nil!.offset.should eq(-5 * 3600)
  end

  it "parses dates with milliseconds" do
    conv = Xmpbox::DateConverter.to_calendar("2015-02-02T16:37:19.192Z")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2015)
    conv.not_nil!.millisecond.should eq(192)
  end

  it "parses dates with half-hour timezone" do
    conv = Xmpbox::DateConverter.to_calendar("2015-02-02T16:37:19+05:30")
    conv.should_not be_nil
    conv.not_nil!.offset.should eq(5 * 3600 + 30 * 60)
  end

  it "parses dates without timezone as UTC" do
    conv = Xmpbox::DateConverter.to_calendar("2024-04-09T14:41:38")
    conv.should_not be_nil
    conv.not_nil!.year.should eq(2024)
  end

  it "returns nil for null or empty" do
    Xmpbox::DateConverter.to_calendar(nil).should be_nil
    Xmpbox::DateConverter.to_calendar("").should be_nil
  end

  it "formats to ISO8601 roundtrip" do
    cal = Xmpbox::DateConverter.to_calendar("2015-02-02T16:37:19Z")
    cal.should_not be_nil
    iso = Xmpbox::DateConverter.to_iso8601(cal.not_nil!)
    roundtrip = Xmpbox::DateConverter.to_calendar(iso)
    roundtrip.should_not be_nil
    roundtrip.not_nil!.to_unix.should eq(cal.not_nil!.to_unix)
  end
end
