require "http/server"
require "option_parser"
require "./api"
require "./cache"

VERSION = "0.1.0"

puts "Flatorte #{VERSION} // Copyright (C) 2021 Hannes Braun"
puts "Flatorte is powered by TheCitadelofRicks (made by Jannik aka Seil0)."
puts

initial_courses = Array(String).new
parser = OptionParser.new do |parser|
  parser.banner = "Usage: flatorte [options]"
  parser.on("-i COURSES", "--init COURSES", "Initially load the given courses") do |_courses|
    parser.banner = "Usage: flatorte --init INFM1,INFM2"
    _courses.split(",").each { |c| initial_courses << c }
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

puts "Listening on http://127.0.0.1:7453"
server.listen(7453)
