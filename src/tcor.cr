require "http/client"
require "json"
require "uri"

# TCOR_API = "https://tcor.mosad.xyz"
TCOR_API = "http://localhost:8080"

struct LessonRaw
  getter subject, room, remark, id

  def initialize(@subject : String, @room : String, @remark : String, @id : Array(String))
  end
end

def timetable(course, week_index)
  tcor_url = "#{TCOR_API}/timetable?course=#{URI.encode_path(course)}&week=#{week_index}"
  timetable = JSON.parse(HTTP::Client.get(tcor_url).body)
  week = timetable["meta"]["weekNumberYear"].as_i

  timetable["timetable"]["days"].as_a.each do |day|
    timeslots = day["timeslots"]
    timeslots.as_a.each do |timeslot|
      timeslot.as_a.each do |lesson|
        subject = lesson["lessonSubject"].as_s.strip
        room = lesson["lessonRoom"].as_s.strip
        remark = lesson["lessonRemark"].as_s.strip
        id = lesson["lessonID"].as_s.split('.')

        yield LessonRaw.new(subject, room, remark, id)
      end
    end
  end
end

