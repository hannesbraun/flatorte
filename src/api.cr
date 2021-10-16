require "uri"
require "./icalendar"
require "./webview"

def handle_request(context, cache)
  resource = URI.decode(URI.parse(context.request.resource).path)
  if resource == "/"
    context.response.content_type = "text/plain"
    context.response.print "Flatorte #{VERSION} // Copyright (C) 2021 Hannes Braun\n"
    context.response.print "This program comes with ABSOLUTELY NO WARRANTY.\n"
    context.response.print "This is free software, and you are welcome to redistribute it\n"
    context.response.print "under certain conditions.\n\n"
    context.response.print "This service is powered by TheCitadelofRicks (made by Jannik aka Seil0).\n"
    return
  end

  if resource == "/calendar" || resource == "/calendar/"
    context.response.content_type = "text/html"
    context.response.print WebView.new.to_s
    return
  end

  course_regex = /^\/calendar\/([^\/?&=]+)\/?$/
  regex_match = course_regex.match(resource)
  if !regex_match.nil?
    course = regex_match[1]

    context.response.content_type = "text/calendar"
    calendar = cache.get(course)
    if calendar.nil?
      # Probably a wrong course name -> 404
      # If TCoR fails... future TODO to report that (maybe)
      context.response.status = HTTP::Status::NOT_FOUND
    else
      context.response.print calendar
    end
    return
  end

  # Error 404
  context.response.content_type = "text/plain"
  context.response.status = HTTP::Status::NOT_FOUND
  context.response.print "Error 404: #{resource} not found\n"
end
