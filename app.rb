require 'sinatra'
require './server/server.rb'

module CardGames
  module Speed
    class App < Sinatra::Base
      set :port, 80
      set :views, './client'
      get '/' do
        erb :'index.html'
      end
    end
  end
end

