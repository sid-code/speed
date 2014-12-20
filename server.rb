require 'eventmachine'
require 'em-websocket'
require './cards.rb'
require './speed.rb'

module CardGames
  module Speed
    class WSServer < CardGames::WSServer

      def onopen(cl, handshake)
        puts "Connection open."
        cl.send("Hello!")
      end

      def onmessage(cl, channel, mtype, *rest)
        case mtype
        when 'search'
          puts "#{cl} is searching"
        end
      end

      def onclose(cl, msg)
        puts "Connection closed: #{msg}"
      end

    end
  end
end

EM.run do
  host = 'localhost'
  port = 8081
  CardGames::Speed::WSServer.new(host, port).run
end
