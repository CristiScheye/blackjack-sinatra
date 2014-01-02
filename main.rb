require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do

  def calculate_score(hand)
    values = hand.map{ |card| card[0]}

    score = 0

    values.each do |value|
      if value == 'Ace'
        score += 11
      else 
        score += (value.to_i == 0 ? 10 : value.to_i)
      end
    end

    # Correct for Aces
    values.select{|val| val == 'Ace'}.count.times do
      break if score <= 21
      score -= 10
    end

    score
  end

  def is_busted?(hand)
    calculate_score(hand) > 21
  end

  def is_blackjack?(hand)
    calculate_score(hand) == 21
  end

  def end_game_variables
    @player_turn = false
    @dealer_turn = false
    @game_over = true
  end

  def check_player_score
    if is_busted?(session[:player_cards])
      @msg_fail = "Sorry #{session[:player_name]}, you busted. You lose :("
      session[:player_purse] -= session[:bet]
      end_game_variables
    elsif is_blackjack?(session[:player_cards])
      @msg_success = "Congrats #{session[:player_name]}, you got blackjack! You win :)"
      session[:player_purse] += session[:bet]
      end_game_variables
    end
  end

  def check_dealer_score
    if is_busted?(session[:dealer_cards])  # score > 21
      @msg_success = "Dealer busted! You win :)"
      session[:player_purse] += session[:bet]
      end_game_variables
    elsif is_blackjack?(session[:dealer_cards]) # score == 21
      @msg_fail = 'Dealer hit blackjack. You lose :('
      session[:player_purse] -= session[:bet]
      end_game_variables
    elsif calculate_score(session[:dealer_cards]) < 17
      @dealer_turn = true
    else  #  17 <= score < 21 
      compare_scores(session[:dealer_cards], session[:player_cards])
    end
  end

  def compare_scores(dealer_hand, player_hand)
    end_game_variables
    dealer_score = calculate_score(dealer_hand)
    player_score = calculate_score(player_hand)
    if dealer_score > player_score
      @msg_fail = "Sorry, you lose. Dealer's total of #{dealer_score} beat your score of #{player_score}."
      session[:player_purse] -= session[:bet]
    elsif dealer_score < player_score
      @msg_success = "Congrats, you win! Your total of #{player_score} beat the dealer's score of #{dealer_score}."
      session[:player_purse] += session[:bet]
    else
      @msg_success = "It's a tie."
    end
  end


  def card_image(card)
    if card == 'cover'
      img_name = "<img src='/images/cards/cover.jpg' />"
    else
      img_name = "<img src='/images/cards/#{card[1].downcase}_#{card[0].downcase}.jpg' />"
    end
    img_name
  end

end

before do
  @player_turn = true
  @dealer_turn = false
  @game_over = false
end

get '/' do
  redirect '/new_player'
end

get '/new_player' do
  erb :new_player
end


post '/new_player' do
  if params[:player_name].empty?
    @error = 'Must enter a name'
    halt erb :new_player
  end

  session[:player_name] = params[:player_name]
  #give player $
  session[:player_purse] = 500
  redirect '/blackjack/place_bet'
end

get '/home' do
  erb :home
end

get '/done' do
  erb :done
end

get '/blackjack/place_bet' do
  if session[:player_purse] < 1
    redirect '/you_lose'
  else
    erb :place_bet
  end
end

post '/blackjack/place_bet' do
  if params[:bet].to_i > session[:player_purse] || params[:bet].to_i <= 0
    @error = "Must enter a valid amount, between $1 and $#{session[:player_purse]}"
    halt erb :place_bet
  end

  session[:bet] = params[:bet].to_i
  redirect '/blackjack/new'
end

get '/blackjack/new' do
  #setup deck
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'Jack', 'Queen', 'King', 'Ace']
  suits = ['Spades', 'Diamonds', 'Hearts', 'Clubs']
  session[:deck] = values.product(suits).shuffle!
  

  #setup hands
  session[:player_cards] = []
  session[:dealer_cards] = []

  #deal cards
  2.times do 
    session[:player_cards] << session[:deck].pop
    session[:dealer_cards] << session[:deck].pop
  end

  redirect '/blackjack' # Keeps user from getting new cards at a screen refresh
end

get '/blackjack' do
  check_player_score
  erb :blackjack
end

post '/blackjack/player_hit' do
  session[:player_cards] << session[:deck].pop
  check_player_score
 
  erb :blackjack, layout: false
end

post '/blackjack/player_stay' do
  @player_turn = false
  check_dealer_score # if dealer's score is between 17 and 21, will also compare scores
  
  erb :blackjack, layout: false
end

post '/blackjack/dealer_hit' do
  session[:dealer_cards] << session[:deck].pop
  @player_turn = false
  check_dealer_score # if dealer's score is between 17 and 21, will also compare scores 
  
  erb :blackjack, layout: false
end

get '/you_lose' do
  erb :you_lose
end

post '/refill_purse' do
  session[:player_purse] = 500
  redirect '/blackjack/place_bet'
end