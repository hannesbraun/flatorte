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

  if result.lines.size > 5
    result
  else
    # No events, only contains header and trailer lines
    nil
  end
end

def ask_tcor(course, week_index, channel)
  beginning_of_week = Time.local(Time::Location.load("Europe/Berlin")).at_beginning_of_week + Time::Span.new(days: week_index * 7)
  faculty = course_to_faculty(course)

  timetable(course, week_index) do |data|
    if data.subject.empty? && data.room.empty? && data.remark.empty?
      # Empty slot
      next
    end

    day = data.id[0].to_i
    time = id_to_time(data.id[1].to_i, faculty)
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
  str << "DTSTAMP:#{Time.local(Time::Location.load(meta.server_location)).to_utc.to_s("%Y%m%dT%H%M%SZ")}\r\n"
  str << "DTSTART:#{lesson.dstart.to_utc.to_s("%Y%m%dT%H%M%SZ")}\r\n"
  str << "DTEND:#{lesson.dend.to_utc.to_s("%Y%m%dT%H%M%SZ")}\r\n"
  str << encode_property("DESCRIPTION", "#{lesson.teacher}\n\n#{lesson.remark}".strip.gsub("\n", "\\n"))
  str << "\r\n"
  str << "END:VEVENT\r\n"
end

def encode_property(key, value)
  "#{key}:#{value}".split_after(74).join("\r\n ")
end

class String
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
