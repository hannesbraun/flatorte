require "./hs"

# TCOR_API = "https://tcor.mosad.xyz"
TCOR_API = "http://localhost:8080"

FUTURE_WEEKS = 19

struct Lesson
  getter subject, room, dstart, dend, remark

  def initialize(@subject : String, @room : String, @dstart : Time, @dend : Time, @remark : String)
  end
end

def icalendar(course, future_weeks = FUTURE_WEEKS)
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
    str << "BEGIN:VCALENDAR\n"
    str << "VERSION:2.0\n"
    str << "PRODID:-//HANNESBRAUN//FLATORTE #{VERSION}\n"
    str << "CALSCALE:GREGORIAN\n"

    channels.each do |channel|
      loop do
        begin
          lesson = channel.receive
          encode_lesson(lesson, str)
        rescue Channel::ClosedError
          # No more data to receive from this channel
          break
        end
      end
    end

    str << "END:VCALENDAR\n"
  end

  if result.lines.size > 5
    result
  else
    # No events, only contains header and trailer lines
    nil
  end
end

def ask_tcor(course, week_index, channel)
  tcor_url = "#{TCOR_API}/timetable?course=#{course}&week=#{week_index}"
  timetable = JSON.parse(HTTP::Client.get(tcor_url).body)
  week = timetable["meta"]["weekNumberYear"].as_i

  beginning_of_week = Time.local(Time::Location.load("Europe/Berlin")).at_beginning_of_week + Time::Span.new(days: week_index * 7)
  faculty = course_to_faculty(course)
  timetable["timetable"]["days"].as_a.each do |day|
    timeslots = day["timeslots"]
    timeslots.as_a.each do |timeslot|
      timeslot.as_a.each do |lesson|
        subject = lesson["lessonSubject"].as_s.strip
        room = lesson["lessonRoom"].as_s.strip
        remark = lesson["lessonRemark"].as_s.strip
        id = lesson["lessonID"].as_s.split('.')

        if subject.empty? && room.empty? && remark.empty?
          # Empty slot
          next
        end

        day = id[0].to_i
        time = id_to_time(id[1].to_i, faculty)
        dstart = beginning_of_week + Time::Span.new(days: day, hours: time[0], minutes: time[1])
        dend = dstart + Time::Span.new(hours: 1, minutes: 30)
        channel.send(Lesson.new(subject, room, dstart, dend, remark)) # TODO does not work
      end
    end
  end

  channel.close
end

def encode_lesson(lesson, str)
  str << "BEGIN:VEVENT\n"
  unless lesson.subject.empty?
    str << "SUMMARY:#{lesson.subject[...65]}\n"
  end
  unless lesson.room.empty?
    str << "LOCATION:#{lesson.room[...64]}\n"
  end
  str << "DTSTART;TZID=Europe/Berlin:#{lesson.dstart.to_s("%Y%m%dT%H%M%S")}\n"
  str << "DTEND;TZID=Europe/Berlin:#{lesson.dend.to_s("%Y%m%dT%H%M%S")}\n"
  # TODO teacher is missing
  str << "DESCRIPTION:#{lesson.remark[...61]}\n" # TODO allow multiple lines of descriptions
  str << "END:VEVENT\n"
end
