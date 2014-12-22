require 'sinatra'
require './server/server.rb'

module CardGames
  module Speed
    class App < Sinatra::Base
      set :port, 80
      get '/' do
        erb :'client/index.html'
      end
    end
  end
end
