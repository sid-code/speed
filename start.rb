
require 'eventmachine'
require 'em-websocket'
require './server/server.rb'

EM.run do
  host = ARGV[0] || "localhost"
  port = ARGV[1] || 8081 
  CardGames::Speed::WSServer.new(host, port).run

  puts "WebSocket server started on #{host}, port #{port}"
end
