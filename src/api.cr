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
