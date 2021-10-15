require "http/client"
require "http/server"
require "./api"
require "./cache"
require "hash"
require "json"
require "time"

VERSION = "0.1.0"

puts "Flatorte #{VERSION} // Copyright (C) 2021 Hannes Braun"
puts "Flatorte is powered by TheCitadelofRicks (made by Jannik aka Seil0)."
puts

cache = Cache.new

server = HTTP::Server.new do |context|
  handle_request(context, cache)
end

puts "Listening on http://127.0.0.1:7453"
server.listen(7453)
