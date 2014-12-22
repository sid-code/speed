require './app.rb'
require './server/rack_backend.rb'

use CardGames::GameBackend

run CardGames::Speed::App
