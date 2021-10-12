require "http/client"
require "http/server"
require "hash"
require "json"
require "time"

TCOR_API = "https://tcor.mosad.xyz"

struct Lesson
  getter subject, room, dstart, dend, remark

  def initialize(@subject : String, @room : String, @dstart : Time, @dend : Time, @remark : String)
  end
end

def is_winter
  month = Time.local.month
  month >= 9 || month <= 2
end

def id_to_time(id)
  case id
  when 0
    {8, 0}
  when 1
    {9, 45}
  when 2
    if is_winter
      {11, 35}
    else
      {12, 0}
    end
  when 3
    {14, 0}
  when 4
    {15, 45}
  when 5
    {17, 30}
  else
    {0, 0}
  end
end

# Subcache for every course, containing a hash mapping the lessons to their week
cache = Hash(String, Tuple(Array(Lesson), Time)).new

server = HTTP::Server.new do |context|
  resource = context.request.resource

  if resource == "/"
    context.response.content_type = "text/html"
    # TODO welcome screen
    next
  end

  course = Path.new(resource).basename

  if course.includes?("/") || Path.new(resource).dirname != "/"
    # Invalid path
    context.response.status = HTTP::Status::NOT_FOUND
    next
  end

  beginning_of_week = Time.local(Time::Location.load("Europe/Berlin")).at_beginning_of_week
  unless cache.has_key?(course.upcase)
    cache[course.upcase] = {Array(Lesson).new, Time.local - Time::Span.new(days: 1)}
  end

  cache_age = (Time.local - cache[course.upcase][1])
  if cache_age.hours > 2 || cache_age.days > 0
    # Update cache
    lessons = Array(Lesson).new

    (0...3).each do |week_index|
      tcor_url = "#{TCOR_API}/timetable?course=#{course}&week=#{week_index}"
      timetable = JSON.parse(HTTP::Client.get(tcor_url).body)
      week = timetable["meta"]["weekNumberYear"].as_i

      timetable["timetable"]["days"].as_a.each do |day|
        timeslots = day["timeslots"]
        timeslots.as_a.each do |timeslot|
          timeslot.as_a.each do |lesson|
            subject = lesson["lessonSubject"].as_s
            if subject.empty?
              next
            end
            room = lesson["lessonRoom"].as_s
            remark = lesson["lessonRemark"].as_s
            id = lesson["lessonID"].as_s.split('.')
            day = id[0].to_i
            time = id_to_time(id[1].to_i)
            dstart = beginning_of_week + Time::Span.new(days: day, hours: time[0], minutes: time[1])
            dend = dstart + Time::Span.new(hours: 1, minutes: 30)
            lessons.push(Lesson.new(subject, room, dstart, dend, remark))
          end
        end
      end

      beginning_of_week += Time::Span.new(days: 7)
    end

    cache[course.upcase] = {lessons, Time.local}
  end

  ics = String.build do |str|
    str << "BEGIN:VCALENDAR\n"
    str << "VERSION:2.0\n"
    str << "CALSCALE:GREGORIAN\n"

    cache[course.upcase][0].each do |lesson|
      str << "BEGIN:VEVENT\n"
      unless lesson.subject.empty?
        str << "SUMMARY:#{lesson.subject}\n"
      end
      unless lesson.room.empty?
        str << "LOCATION:#{lesson.room}\n"
      end
      str << "DTSTART;TZID=Europe/Berlin:#{lesson.dstart.to_s("%Y%m%d%H%M%S")}\n"
      str << "DTEND;TZID=Europe/Berlin:#{lesson.dend.to_s("%Y%m%d%H%M%S")}\n"
      str << "END:VEVENT\n"
    end

    str << "END:VCALENDAR\n"
  end

  context.response.content_type = "text/calendar"
  context.response.print ics
end

puts "Listening on http://127.0.0.1:7453"
server.listen(7453)
