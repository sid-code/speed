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

end
