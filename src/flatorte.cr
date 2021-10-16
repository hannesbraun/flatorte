require "http/server"
require "option_parser"
require "./api"
require "./cache"

VERSION = "0.1.0"

PORT = 7453

puts "Flatorte #{VERSION} // Copyright (C) 2021 Hannes Braun"
puts "Flatorte is powered by TheCitadelofRicks (made by Jannik aka Seil0)."
puts

initial_courses = Array(String).new
key = nil
cert = nil
parser = OptionParser.new do |parser|
  parser.banner = "Usage: flatorte [options]"
  parser.on("-i COURSES", "--init COURSES", "Initially load the given courses") do |_courses|
    parser.banner = "Usage: flatorte --init INFM1,INFM2"
    _courses.split(",").each { |c| initial_courses << c }
  end
  parser.on("-k KEY", "--key KEY", "Path to private key file") do |_key|
    parser.banner = "Usage: flatorte --init INFM1,INFM2"
    key = _key
  end
  parser.on("-c CERTIFICATE", "--cert CERTIFICATE", "Path to the file containing the public certificate chain") do |_cert|
    parser.banner = "Usage: flatorte --init INFM1,INFM2"
    cert = _cert
  end
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end
end

parser.parse

cache = Cache.new(initial_courses)

server = HTTP::Server.new do |context|
  handle_request(context, cache)
end

if !key.nil? && !cert.nil?
  puts "Listening on https://127.0.0.1:7453"
  context = OpenSSL::SSL::Context::Server.new
  context.certificate_chain = "cert.pem"
  context.private_key = "key.pem"
  server.bind_tls "0.0.0.0", PORT, context
  server.listen
else
  # HTTPS disabled
  puts "Listening on http://127.0.0.1:7453"
  server.listen "0.0.0.0", PORT
end
