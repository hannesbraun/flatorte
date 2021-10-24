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

require "http/client"
require "json"
require "uri"

# The TCoR URL to use
TCOR_API = "https://tcor.mosad.xyz"

# Raw string representation of one entry returned by TCoR
struct LessonRaw
  getter subject, teacher, room, remark, id, week, year

  def initialize(@subject : String, @teacher : String, @room : String, @remark : String, @id : Array(String), @week : Int32, @year : Int32)
  end
end

# Requests the timetable for the given course and week
def timetable(course, week_index)
  tcor_url = "#{TCOR_API}/timetable?course=#{URI.encode_path(course)}&week=#{week_index}"
  timetable = JSON.parse(HTTP::Client.get(tcor_url).body)
  week = timetable["meta"]["weekNumberYear"].as_i
  year = timetable["meta"]["year"].as_i

  timetable["timetable"]["days"].as_a.each do |day|
    timeslots = day["timeslots"]
    timeslots.as_a.each do |timeslot|
      timeslot.as_a.each do |lesson|
        subject = lesson["lessonSubject"].as_s.strip
        teacher = lesson["lessonTeacher"].as_s.strip
        room = lesson["lessonRoom"].as_s.strip
        remark = lesson["lessonRemark"].as_s.strip
        id = lesson["lessonID"].as_s.split('.')

        yield LessonRaw.new(subject, teacher, room, remark, id, week, year)
      end
    end
  end
end

# Requests the course list and returns it
def courseList
  tcor_url = "#{TCOR_API}/courseList"
  list = JSON.parse(HTTP::Client.get(tcor_url).body)
  result = Array(String).new(list["meta"]["totalCourses"].as_i)
  list["courses"].as_a.each { |course| result << course["courseName"].as_s }
  return result
end
