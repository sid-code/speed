require './server/server.rb'

EM.run do
  host = 'localhost'
  port = 8081
  CardGames::Speed::WSServer.new(host, port).run
end
