# encoding: utf-8

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
      @games = []
    end
    
    def run
      EM::WebSocket.run(host: @host, port: @port, &handler)
    end

    private
    
    def gen_name
      @name_counter += 1
      "Player_#{@name_counter}"
    end
    
    def handler
      proc do |ws|
        ws.onopen do |handshake|
          @clients[ws] = cl = Client.new(gen_name, ws)
          onopen(cl, handshake)
        end

        ws.onmessage do |msg|
          _onmessage(cl, msg)
        end

        ws.onclose do |msg|
          onclose(cl, msg)
        end
      end
    end

    def onopen(cl, handshake)
    end

    def _onmessage(cl, msg)
      channel, mtype, *rest = msg.split('|')
      
      onmessage(cl, channel, mtype, *rest)
    end

    def onmessage(cl, msg, *rest)
    end

    def onclose(cl, msg)
    end

    class Client
      attr_reader :personae, :name

      def initialize(name, ws)
        @name = name
        @ws = ws
        @personae = []
      end

      def send(*args)
        @ws.send(*args)
      end
    end

  end

end
