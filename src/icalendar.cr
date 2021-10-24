# Flatorte - A WebCal server for courses at the Offenburg University
# Copyright (C) 2021 Hannes Braun
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

require "channel"
require "time"
require "uuid"
require "./hs"
require "./tcor"

FUTURE_WEEKS = 19

struct Lesson
  getter subject, teacher, room, dstart, dend, remark

  def initialize(@subject : String, @teacher : String, @room : String, @dstart : Time, @dend : Time, @remark : String)
  end
end

# Requests and builds the iCalendar from the given information
#
# If the calendar is empty, nil will be returned instead of an empty calendar
def icalendar(course, meta, future_weeks = FUTURE_WEEKS)
  channels = Array(Channel(Lesson)).new(FUTURE_WEEKS)

  (0...future_weeks).each do |week_index|
    channel = Channel(Lesson).new(36)
    channels << channel
    spawn do
      begin
        ask_tcor(course, week_index, channel)
      rescue
        channel.close
      end
    end
  end

  result = String.build do |str|
    str << "BEGIN:VCALENDAR\r\n"
    str << "VERSION:2.0\r\n"
    str << "PRODID:-//HANNESBRAUN//FLATORTE #{VERSION}\r\n"
    str << "CALSCALE:GREGORIAN\r\n"

    str << "BEGIN:VTIMEZONE\r\n"
    str << "TZID:Europe/Berlin\r\n"
    str << "X-LIC-LOCATION:Europe/Berlin\r\n"
    str << "BEGIN:DAYLIGHT\r\n"
    str << "TZOFFSETFROM:+0100\r\n"
    str << "TZOFFSETTO:+0200\r\n"
    str << "TZNAME:CEST\r\n"
    str << "DTSTART:19700329T020000\r\n"
    str << "RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=3\r\n"
    str << "END:DAYLIGHT\r\n"
    str << "BEGIN:STANDARD\r\n"
    str << "TZOFFSETFROM:+0200\r\n"
    str << "TZOFFSETTO:+0100\r\n"
    str << "TZNAME:CET\r\n"
    str << "DTSTART:19701025T030000\r\n"
    str << "RRULE:FREQ=YEARLY;BYDAY=-1SU;BYMONTH=10\r\n"
    str << "END:STANDARD\r\n"
    str << "END:VTIMEZONE\r\n"

    channels.each do |channel|
      loop do
        begin
          lesson = channel.receive
          encode_lesson(lesson, str, meta)
        rescue Channel::ClosedError
          # No more data to receive from this channel
          break
        end
      end
    end

    str << "END:VCALENDAR"
  end
end

def ask_tcor(course, week_index, channel)
  faculty = course_to_faculty(course)

  timetable(course, week_index) do |data|
    if data.subject.empty? && data.room.empty? && data.remark.empty?
      # Empty slot
      next
    end

    day = data.id[0].to_i
    time = id_to_time(data.id[1].to_i, faculty)
    beginning_of_week = Time.week_date(data.year, data.week, Time::DayOfWeek::Monday)
    dstart = beginning_of_week + Time::Span.new(days: day, hours: time[0], minutes: time[1])
    dend = dstart + Time::Span.new(hours: 1, minutes: 30)
    channel.send(Lesson.new(data.subject, data.teacher, data.room, dstart, dend, data.remark))
  end

  channel.close
end

def encode_lesson(lesson, str, meta)
  str << "BEGIN:VEVENT\r\n"
  unless lesson.subject.empty?
    str << encode_property("SUMMARY", lesson.subject)
    str << "\r\n"
  end
  unless lesson.room.empty?
    str << encode_property("LOCATION", lesson.room)
    str << "\r\n"
  end
  str << encode_property("UID", "#{UUID.random.to_s}@flatorte.hannesbraun.net")
  str << "\r\n"
  str << "DTSTAMP;TZID=Europe/Berlin:#{Time.local(Time::Location.load(meta.server_location)).to_s("%Y%m%dT%H%M%S")}\r\n"
  str << "DTSTART;TZID=Europe/Berlin:#{lesson.dstart.to_s("%Y%m%dT%H%M%S")}\r\n"
  str << "DTEND;TZID=Europe/Berlin:#{lesson.dend.to_s("%Y%m%dT%H%M%S")}\r\n"
  str << encode_property("DESCRIPTION", "#{lesson.teacher}\n\n#{lesson.remark}".strip.gsub("\n", "\\n"))
  str << "\r\n"
  str << "END:VEVENT\r\n"
end

def encode_property(key, value)
  "#{key}:#{value}".split_after(74).join("\r\n ")
end

class String
  # Splits the string into segments with a maximum of `len` characters
  def split_after(len : Int32)
    result = [] of String
    i = 0
    while i < self.size
      result << self[i, 75]
      i += 75
    end
    return result
  end
end
