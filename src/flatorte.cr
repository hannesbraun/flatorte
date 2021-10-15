require "http/client"
require "http/server"
require "./api"
require "./cache"
require "hash"
require "json"
require "time"

VERSION = "0.1.0"

puts "Flatorte #{VERSION}"
puts "Copyright 2021 Hannes Braun"
puts "Powered by the citadel of Ricks"

cache = Cache.new

server = HTTP::Server.new do |context|
  handle_request(context, cache)
end

puts "Listening on http://127.0.0.1:7453"
server.listen(7453)
