require 'sinatra'
require './server/server.rb'

module CardGames
  module Speed
    class App < Sinatra::Base
      get '/' do
        erb :'client/index.html'
      end
    end
  end
end
