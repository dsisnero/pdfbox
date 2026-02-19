module Xmpbox
  module DateConverter
    private DATE_ONLY_RE  = /^\d{4}-\d{2}-\d{2}T/
    private ISO_OFFSET_RE = /([+-])(\d{2}):(\d{2})$/

    def self.to_calendar(date : String?) : Time?
      return if date.nil?

      trimmed = date.strip
      return if trimmed.empty?

      if DATE_ONLY_RE.matches?(trimmed)
        validate_iso_offset!(trimmed)
        return from_iso8601(trimmed)
      end

      parse_pdf_date(trimmed)
    rescue ex : ArgumentError
      raise IO::Error.new("Error converting date:#{trimmed}", cause: ex)
    end

    def self.to_iso8601(cal : Time, print_millis : Bool = false) : String
      millis = print_millis ? ".#{cal.millisecond.to_s.rjust(3, '0')}" : ""
      offset = cal.offset
      sign = offset < 0 ? "-" : "+"
      abs_offset = offset.abs
      hours = abs_offset // 3600
      minutes = (abs_offset - hours * 3600) // 60
      "%04d-%02d-%02dT%02d:%02d:%02d%s%s%02d:%02d" % {
        cal.year, cal.month, cal.day,
        cal.hour, cal.minute, cal.second,
        millis, sign, hours, minutes,
      }
    end

    private def self.from_iso8601(date : String) : Time
      parse_formats = [
        "%Y-%m-%dT%H:%M:%S.%N%:z",
        "%Y-%m-%dT%H:%M:%S%:z",
        "%Y-%m-%dT%H:%M%:z",
      ]
      parse_formats.each do |time_format|
        begin
          return Time.parse(date, time_format, Time::Location::UTC)
        rescue Time::Format::Error
        end
      end

      if date.matches?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/)
        return Time.parse_utc(date, "%Y-%m-%dT%H:%M:%S")
      end

      raise IO::Error.new("Error converting date:#{date}")
    rescue ex : IO::Error
      raise ex
    rescue ex : Time::Format::Error
      raise IO::Error.new("Error converting date:#{date}", cause: ex)
    end

    private def self.parse_pdf_date(date : String) : Time
      work = date.starts_with?("D:") ? date[2..] : date
      if DATE_ONLY_RE.matches?(work)
        validate_iso_offset!(work)
        return from_iso8601(work)
      end

      pos_t = work.index('T')
      if !pos_t.nil? && pos_t != 10
        raise IO::Error.new("Error converting date:#{work}")
      end

      work = work.gsub(/[-:T]/, "")
      if work.size < 4
        raise IO::Error.new("Error: Invalid date format '#{work}'")
      end

      fields = parse_fields(work)
      second, time_zone_pos = parse_second_and_zone_pos(work)
      location = parse_location(work, time_zone_pos)

      Time.local(
        fields[:year], fields[:month], fields[:day],
        fields[:hour], fields[:minute], second,
        location: location
      )
    end

    private def self.validate_iso_offset!(date : String) : Nil
      match = ISO_OFFSET_RE.match(date)
      return if match.nil?

      sign = match[1][0]
      hours = match[2].to_i
      max_hours = sign == '+' ? 12 : 14

      if hours > max_hours
        raise IO::Error.new("Error converting date:#{date}")
      end
    end

    private def self.parse_fields(work : String) : NamedTuple(year: Int32, month: Int32, day: Int32, hour: Int32, minute: Int32)
      {
        year:   work[0, 4].to_i,
        month:  work.size >= 6 ? work[4, 2].to_i : 1,
        day:    work.size >= 8 ? work[6, 2].to_i : 1,
        hour:   work.size >= 10 ? work[8, 2].to_i : 0,
        minute: work.size >= 12 ? work[10, 2].to_i : 0,
      }
    end

    private def self.parse_second_and_zone_pos(work : String) : Tuple(Int32, Int32)
      second = 0
      time_zone_pos = 12
      if work.size == 14 || work.size - 12 > 5 || (work.size - 12 == 3 && work.ends_with?('Z'))
        second = work[12, 2].to_i
        time_zone_pos = 14
      end
      {second, time_zone_pos}
    end

    private def self.parse_location(work : String, time_zone_pos : Int32) : Time::Location
      return Time::Location.local if work.size < time_zone_pos + 1

      tail = work.byte_slice(time_zone_pos) || ""
      return Time::Location.local if tail.empty?
      return Time::Location::UTC if tail == "Z"

      offset_seconds = parse_offset_seconds(tail)
      Time::Location.fixed(offset_seconds)
    end

    private def self.parse_offset_seconds(tail : String) : Int32
      return 0 if tail.size < 3

      sign = tail[0]
      if sign == '+'
        hours = tail[1, 2].to_i
        minutes = tail.size >= 5 ? tail[3, 2].to_i : 0
        return hours * 3600 + minutes * 60
      end

      hours = -tail[0, 2].to_i
      minutes = tail.size >= 4 ? tail[2, 2].to_i : 0
      hours * 3600 + minutes * 60
    end
  end
end
