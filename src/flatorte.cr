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

require "http/server"
require "option_parser"
require "./api"
require "./cache"
require "./meta"

VERSION = "1.0.0"

puts "Flatorte #{VERSION} // Copyright (C) 2021 Hannes Braun"
puts "Flatorte is powered by TheCitadelofRicks (made by Jannik aka Seil0)."
puts

initial_courses = Array(String).new
key = nil
cert = nil
meta = FlatorteMeta.new
parser = OptionParser.new do |parser|
  parser.banner = "Usage: flatorte [options]"
  parser.on("-i COURSES", "--init COURSES", "Initially load the given courses") do |_courses|
    parser.banner = "Usage: flatorte --init INFM1,INFM2"
    _courses.split(",").each { |c| initial_courses << c }
  end
  parser.on("-k KEY", "--key KEY", "Path to private key file") do |_key|
    parser.banner = "Usage: flatorte --key privkey.pem"
    key = _key
  end
  parser.on("-c CERTIFICATE", "--cert CERTIFICATE", "Path to the file containing the public certificate chain") do |_cert|
    parser.banner = "Usage: flatorte --cert fullchain.pem"
    cert = _cert
  end
  parser.on("-u URL", "--url URL", "The domain under which to reach this server") do |_url|
    parser.banner = "Usage: flatorte --url flatorte.yourdomain.dev"
    meta.url = _url
  end
  parser.on("-p PORT", "--port PORT", "The port to use") do |_port|
    parser.banner = "Usage: flatorte --port 7453"
    meta.port = _port.to_i
  end
  parser.on("-t TIMEZONE", "--timezone TIMEZONE", "The timezone this server is located in") do |_tz|
    parser.banner = "Usage: flatorte --timezone \"Europe/Berlin\""
    meta.server_location = _tz
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end

parser.parse

cache = Cache.new(initial_courses, meta)

server = HTTP::Server.new do |context|
  handle_request(context, cache, meta)
end

if !key.nil? && !cert.nil?
  puts "Listening on https://127.0.0.1:#{meta.port}"
  context = OpenSSL::SSL::Context::Server.new
  context.certificate_chain = cert.as(String)
  context.private_key = key.as(String)
  server.bind_tls "0.0.0.0", meta.port, context
  server.listen
else
  # HTTPS disabled
  puts "Listening on http://127.0.0.1:#{meta.port}"
  server.listen "0.0.0.0", meta.port
end
