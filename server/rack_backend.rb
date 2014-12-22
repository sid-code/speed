require 'faye/websocket'

module CardGames
  SERVER = CardGames::Speed::WSServer.new
  KEEPALIVE_TIME = 15

  class GameBackend
    def initialize(app)
      @app = app
    end

    def call(env)
      if Faye::WebSocket.websocket?(env)
        ws = Faye::WebSocket.new(env, nil, {ping: KEEPALIVE_TIME})

        SERVER.handler_faye.call(ws)
        ws.rack_response
      else
        @app.call(env)
      end
    end
  end
end

