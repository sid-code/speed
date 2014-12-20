# encoding: utf-8

require './cards'

module CardGames
  class SpeedPlayer < Player
    attr_reader :reserve_cards 

    def initialize(*args)
      super(*args)
      @reserve_cards = []
    end

    def fill_hand(size = 5)
      until @hand.size >= size
        return unless card = @reserve_cards.shift
        @hand << card
      end
    end

    def <<(card)
      @reserve_cards << card
    end
  end

  class SpeedGame
    attr_reader :players, :deck

    attr_reader :play_piles, :reserve_piles

    def initialize(players = [])
      @players = players
      @deck = Deck.new.shuffle

      @play_piles = []
      @reserve_piles = []
    end

    def <<(player)
      @players << player
    end

    def num_players
      @players.size
    end


    def setup
      num_players.times do
        @play_piles << []
        @reserve_piles << []
      end

      @play_piles.each do |pile|
        pile.replace([deck.deal])
      end

      @reserve_piles.cycle(4).each do |pile|
        pile << @deck.deal
      end

      @players.cycle do |pl|
        break unless card = @deck.deal
        pl << card
      end

      @players.each do |pl|
        pl.fill_hand
      end
    end

    def to_s
      buf = ""
      buf << @players.map(&:to_s).join(", ") << "\n"
      buf << @play_piles.map(&:to_s).join(", ")
    end

    def make_play(player, card_index, pile_index)
      play_card = player.hand[card_index]
      pile = @play_piles[pile_index]
      top_card = pile.first

      return unless valid_play(top_card.rank, play_card.rank)
      pile.unshift(player.play(play_card))
      player.fill_hand

      self
    end

    def check_if_stuck
      @players.each do |pl|
        ranks = pl.hand.map(&:ranks)
        @piles.each do |pile|
          top_rank = pile.first.rank
          if ranks.any? { |rank| valid_play(top_rank, rank) }
            return false
          end
        end
      end
    end

    private

    def valid_play(top_rank, play_rank)
      ok = [top_rank + 1, top_rank, top_rank - 1]
            .map { |rank| (rank-1) % 13 + 1}

      ok.include?(play_rank);
    end
  end

# if __FILE__ == $0
#   g = SpeedGame.new
#   p1 = SpeedPlayer.new('p1')
#   p2 = SpeedPlayer.new('p2')
#   g << p1
#   g << p2
#   g.setup
#   puts g
#   play = gets.strip.split(' ').map(&:to_i)
#   p g.make_play(p1, *play)
#   
# end
end
