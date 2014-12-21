# encoding: utf-8

require './cards.rb'

module CardGames
  module Speed
    class Player < CardGames::Player
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

    class Game < CardGames::Game
      attr_reader :players, :deck

      attr_reader :play_piles, :reserve_piles

      def initialize(players = [], &event_cb)
        @players = players
        @deck = Deck.new.shuffle

        @play_piles = []
        @reserve_piles = []

        super(&event_cb)
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

      def flip
        @reserve_piles.zip(@play_piles).each do |rp, pp|
          pp.unshift(rp.pop)
          if rp.size == 0
            rp.replace(pp[2..-1].shuffle)
            pp.replace([pp[0]])
          end
        end
        check_if_stuck
      end

      def to_s
        buf = ""
        buf << @players.map(&:to_s).join(", ") << "\n"
        buf << @play_piles.map(&:to_s).join(", ")
      end

      def make_play(player, card_index, pile_index)
        return unless @started
        play_card = player.hand[card_index]
        return unless play_card

        pile = @play_piles[pile_index]
        top_card = pile.first

        return unless valid_play(top_card.rank, play_card.rank)
        pile.unshift(player.play(play_card))
        player.fill_hand

        return if check_for_winner
        check_if_stuck

        self
      end

      def update_message_for(player)
        buf = ""
        buf << player.hand.map(&:to_mstr).join(",")
        buf << "|" << player.reserve_cards.size.to_s
        buf << "|" << @play_piles.map { |pile| 
                        @started ? pile.first.to_mstr : "0:" 
                      }.join(",")
        buf << "|" << @players.map(&:name).join(",")
      end

      private
      def check_for_winner
        winner = @players.find { |pl|
                   pl.hand.size == 0 && pl.reserve_cards.size == 0
                 }

        if winner
          event(:win, winner)
        end
      end

      def check_if_stuck
        @players.each do |pl|
          ranks = pl.hand.map(&:rank)
          @play_piles.each do |pile|
            top_rank = pile.first.rank
            if ranks.any? { |rank| valid_play(top_rank, rank) }
              return false
            end
          end
        end

        event(:stuck)
      end


      def valid_play(top_rank, play_rank)
        ok = [top_rank + 1, top_rank, top_rank - 1]
              .map { |rank| (rank-1) % 13 + 1}

        ok.include?(play_rank);
      end
    end

  end

end
