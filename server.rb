require 'eventmachine'
require 'em-websocket'
require './cards.rb'
require './speed.rb'

handler = proc do |ws|

  p self
  ws.onopen do |handshake|
    puts "Connection"

    ws.send("Hello connector!")
  end

  ws.onmessage do |msg|
    channel, mtype, *rest = msg.split('|')
    
    case mtype
    when 'search'

    end
  end
end

EM.run do
  host = 'localhost'
  port = 8081
  EM::WebSocket.run(host: host, port: port, &handler)
end
