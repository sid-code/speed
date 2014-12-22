# encoding: utf-8

require './server/util.rb'

module CardGames
  class Deck
    attr_reader :cards

    def initialize
      @cards = []
      (1..13).each do |rank|
        Card::SUITS.each do |suit, _|
          @cards << Card.new(rank, suit)
        end
      end
    end

    def shuffle
      @cards.shuffle!
      self
    end

    def deal
      @cards.shift
    end
  end

  class Card
    attr_reader :rank, :suit

    RANK_NAMES = [nil, '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J',
                  'Q', 'K']

    SUITS = {
      spades: "\u2660",
      hearts: "\u2665",
      diamonds: "\u2666",
      clubs: "\u2663",

    }

    def initialize(rank, suit)
      @rank = rank
      @suit = suit
    end

    def to_s
      "#{RANK_NAMES[rank]}#{SUITS[suit]}"
    end

    def to_mstr
      "#{rank}:#{suit.to_s.capitalize}"
    end
  end

  # defines a generic player (one hand)
  class Player
    attr_reader :name, :hand

    def initialize(name)
      @name = name
      @hand = []
    end

    def <<(card)
      @hand << card
    end

    def play(card)
      @hand.delete(card)
    end

    def to_s
      hand_str = @hand.map(&:to_s).join(', ')
      "#{name}: (#{hand_str})"
    end
  end

  class WSServer
    def initialize(host, port)
      @host = host
      @port = port
      @clients = {}
      @name_counter = 0
      @channels = {}
    end
    
    def run
      EM::WebSocket.run(host: @host, port: @port, &handler_em)
    end

    private
    
    def add_game(game, clients)
      id = @channels.size.to_s
      @channels[id] = Channel.new(id, game, clients)
    end

    def gen_name
      @name_counter += 1
      "Player_#{@name_counter}"
    end
    
    def handler_em
      proc do |ws|
        ws.onopen do |handshake|
          @clients[ws] = cl = Client.new(gen_name, ws)
          onopen(cl, handshake)
        end

        ws.onmessage do |msg|
          _onmessage(@clients[ws], msg)
        end

        ws.onclose do |msg|
          onclose(@clients[ws], msg)
        end
      end
    end

    def handler_faye
      proc do |ws|
        ws.on :open do |event|
          @clients[ws] = cl = Client.new(gen_name, ws)
          onopen(cl, event)
        end

        ws.on :message do |event|
          _onmessage(@clients[ws], event.data)
        end

        ws.on :close do |event|
          onclose(@clients[ws], msg)
        end
      end
    end

    def onopen(cl, handshake)
    end

    def _onmessage(cl, msg)
      channel, mtype, *rest = msg.split('|')
      
      onmessage(cl, @channels[channel], mtype.to_sym, *rest)
    end

    def onmessage(cl, msg, *rest)
    end

    def onclose(cl, msg)
    end

    class Channel
      attr_reader :game, :id, :clients, :status

      def initialize(id, game, clients)
        @game = game
        @id = id
        @clients = clients
        @status = {}
      end

      def send(mtype, *payload)
        @clients.each do |cl|
          cl.send(mtype, @id, *payload)
        end
      end
    end

    class Client
      attr_reader :personae, :name, :ws

      def initialize(name, ws)
        @name = name
        @ws = ws

        # maps channel to player
        @personae = {}
      end

      def add_persona(channel, player)
        @personae[channel] = player
      end

      def persona_for(channel)
        @personae[channel]
      end

      def remove_persona(channel)
        @personae.delete(channel)
      end

      def send(mtype, channel='', *rest)
        message = "#{channel}|#{mtype}|#{rest.join('|')}"
        @ws.send(message)
      end

      def rename(newname)
        @name = newname
      end
    end
  end

  class Game
    attr_reader :event_cb, :started
    
    def initialize(&event_cb)
      @event_cb = event_cb
      @started = false
    end

    def event(type, *payload)
      @event_cb.call(type, *payload)
    end

    def start
      @started = true
      event(:start)
    end
  end

end
