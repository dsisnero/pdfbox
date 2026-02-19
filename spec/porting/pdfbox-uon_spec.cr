require "../spec_helper"

describe "Porting parity pdfbox-uon" do
  # Source of truth:
  # vendor/pdfbox/xmpbox/src/test/java/org/apache/xmpbox/DateConverterTest.java
  # vendor/pdfbox/xmpbox/src/main/java/org/apache/xmpbox/DateConverter.java
  it "parses partial and prefixed date formats like Java DateConverter" do
    conv_date = Xmpbox::DateConverter.to_calendar("2015")
    conv_date.should_not be_nil
    conv_date = conv_date.as(Time)
    conv_date.year.should eq(2015)
    conv_date.month.should eq(1)
    conv_date.day.should eq(1)

    conv_date = Xmpbox::DateConverter.to_calendar("2015-05")
    conv_date.should_not be_nil
    conv_date = conv_date.as(Time)
    conv_date.year.should eq(2015)
    conv_date.month.should eq(5)

    conv_date = Xmpbox::DateConverter.to_calendar("2015-05-02")
    conv_date.should_not be_nil
    conv_date = conv_date.as(Time)
    conv_date.year.should eq(2015)
    conv_date.month.should eq(5)
    conv_date.day.should eq(2)

    conv_date = Xmpbox::DateConverter.to_calendar("D:2015-02-03T10:11:12")
    conv_date.should_not be_nil
    conv_date = conv_date.as(Time)
    conv_date.year.should eq(2015)
    conv_date.month.should eq(2)
    conv_date.day.should eq(3)
    conv_date.hour.should eq(10)
    conv_date.minute.should eq(11)
    conv_date.second.should eq(12)
  end

  it "parses timezone offsets and missing seconds" do
    plus_offset = Xmpbox::DateConverter.to_calendar("D:2015-02-03T10:11:12+05:00")
    plus_offset.should_not be_nil
    plus_offset = plus_offset.as(Time)
    plus_offset.offset.should eq(5 * 3600)

    minus_offset = Xmpbox::DateConverter.to_calendar("D:2015-02-03T10:11:12-05:00")
    minus_offset.should_not be_nil
    minus_offset = minus_offset.as(Time)
    minus_offset.offset.should eq(-5 * 3600)

    with_seconds = Xmpbox::DateConverter.to_calendar("2015-12-08T12:07:00-05:00")
    with_seconds.should_not be_nil
    with_seconds = with_seconds.as(Time)
    without_seconds = Xmpbox::DateConverter.to_calendar("2015-12-08T12:07-05:00")
    without_seconds.should_not be_nil
    without_seconds = without_seconds.as(Time)
    with_seconds.to_unix.should eq(without_seconds.to_unix)

    utc = Xmpbox::DateConverter.to_calendar("2011-11-20T10:09Z")
    utc.should_not be_nil
    utc = utc.as(Time)
    utc.offset.should eq(0)
  end

  it "parses fractional seconds and local datetime without zone" do
    conv_date = Xmpbox::DateConverter.to_calendar("2025-09-03T15:43:47.989082+00:00")
    conv_date.should_not be_nil
    conv_date = conv_date.as(Time)
    conv_date.millisecond.should eq(989)

    local_without_zone = Xmpbox::DateConverter.to_calendar("2024-04-09T14:41:38")
    local_without_zone.should_not be_nil
    local_without_zone = local_without_zone.as(Time)
    local_without_zone.offset.should eq(0)
    local_without_zone.year.should eq(2024)
    local_without_zone.month.should eq(4)
    local_without_zone.day.should eq(9)
  end

  it "raises on invalid strings and returns nil for nil or blank" do
    expect_raises(IO::Error) { Xmpbox::DateConverter.to_calendar("123") }
    expect_raises(IO::Error) { Xmpbox::DateConverter.to_calendar("2008-12-31T19:48:30+19:00") }
    expect_raises(IO::Error) { Xmpbox::DateConverter.to_calendar("2009-03-16T01:15:19-0-4:00") }

    Xmpbox::DateConverter.to_calendar(nil).should be_nil
    Xmpbox::DateConverter.to_calendar("").should be_nil
    Xmpbox::DateConverter.to_calendar("   ").should be_nil
  end

  it "formats ISO8601 consistently with Java-style output" do
    cal = Xmpbox::DateConverter.to_calendar("2015-02-02T16:37:19.192+09:09")
    cal.should_not be_nil
    cal = cal.as(Time)
    formatted = Xmpbox::DateConverter.to_iso8601(cal, print_millis: true)
    round_trip = Xmpbox::DateConverter.to_calendar(formatted)
    round_trip.should_not be_nil
    round_trip = round_trip.as(Time)

    round_trip.to_unix.should eq(cal.to_unix)
    round_trip.offset.should eq(cal.offset)
  end
end
