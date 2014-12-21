require 'eventmachine'
require 'em-websocket'
require 'json'

require './cards.rb'
require './speed.rb'

module CardGames
  module Speed
    class WSServer < CardGames::WSServer

      GAME_SIZE = 2

      def initialize(*args)
        super(*args)
        @searchers = []
      end

      private

      def add_game(game, clients)
        id = @channels.size.to_s
        @channels[id] = Channel.new(id, game, clients)
      end

      def onopen(cl, handshake)
        puts "Connection open."
        cl.send("name", "", cl.name)
      end

      def onmessage(cl, channel, mtype, *rest)
        case mtype
        when :rename
          if @channels.any? { |_, ch| ch.clients.include? cl }
            return cl.send("error", "", "You cannot rename while in a game.")
          end
          newname = rest[0]
          if !newname
            return cl.send("error", "", "You need to specify a name.")
          end
          if newname.size > 19 || newname.size < 3
            return cl.send("error", "", "Names can only be 3-19 characters long.")
          end

          cname = Utility.condense_name(newname)
          if @clients.any? { |_, ocl| cl != ocl && Utility.condense_name(ocl.name) == cname }
            return cl.send("error", "", "That name is taken.")
          end
          cl.rename(newname)

          cl.send("name", "", newname)

        when :start
          return unless channel
          channel.is_ready(cl)
          if channel.all_ready?
            channel.game.start
            channel.update_players
          end
        when :search
          return if @searchers.include? cl
          puts "#{cl} is searching"
          @searchers << cl
          check_searchers
        when :play
          return unless channel
          player = cl.persona_for(channel)

          from = rest[0].to_i
          to = rest[1].to_i
          return unless channel.game.make_play(player, from, to)
          channel.update_players
        when :flip
          return unless channel
          channel.is_ready(cl)
          if channel.all_ready?
            channel.send("flip")
            channel.game.flip
            channel.update_players
          end
        end
      end

      def onclose(cl, msg)
        puts "Connection closed: #{msg}"
        @searchers.delete(cl)
        @clients.delete(cl.ws)
        @channels.each do |id, channel|
          cls = channel.clients
          if cls.include? cl
            cls.delete(cl)
            channel.game.event(:leave, cl)
          end
          if cls.size == 1
            channel.game.event(:win, cls.first)
          elsif cls.size == 0
            @channels.delete(id)
          end
        end
      end

      def handle_game_event(channel, event, *payload)
        case event
        when :start
          channel.send('start');
        when :stuck
          channel.reset_ready
          channel.send('stuck');
        when :win
          channel.send('win', payload[0].name)
        end

      end

      def check_searchers
        if @searchers.size >= GAME_SIZE
          clients = @searchers.pop(GAME_SIZE)
          players = clients.map do |searcher|
            Player.new(searcher.name)
          end

          channel = nil
          game = Game.new(players) do |event, *payload|
            handle_game_event(channel, event, *payload)
          end

          channel = add_game(game, clients)
          
          clients.each.with_index do |cl, index|
            cl.add_persona(channel, players[index])
          end

          game.setup
          channel.send("newgame")
          channel.update_players

          check_searchers
        end
      end

      class Channel < CardGames::WSServer::Channel
        def initialize(*args)
          super(*args)
          reset_ready
        end

        def reset_ready
          @status[:ready] = []
        end

        def is_ready(cl)
          @status[:ready] << cl unless @status[:ready].include? cl
        end

        def all_ready?
          @status[:ready].size == @clients.size
        end

        def update_players
          @clients.each do |cl|
            message = @game.update_message_for(cl.persona_for(self))
            cl.send('update', @id, message)
          end
        end
      end

    end
  end
end

EM.run do
  host = 'localhost'
  port = 8081
  CardGames::Speed::WSServer.new(host, port).run
end
