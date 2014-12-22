require './app.rb'
require './server/rack_backend.rb'

Faye::WebSocket.load_adapter('thin')
use CardGames::GameBackend

run CardGames::Speed::App
