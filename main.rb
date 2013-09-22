require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'

set :sessions, true

helpers do

  def calculate_score(hand)
    values = hand.map{ |card| card[0]}

    score = 0

    values.each do |value|
      if value == 'A'
        score += 11
      else 
        score += (value.to_i == 0 ? 10 : value.to_i)
      end
    end

    # Correct for Aces
    values.select{|val| val == 'A'}.count.times do
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
      @msg = "Sorry #{session[:player_name]}, you busted. You lose :("
      end_game_variables
    elsif is_blackjack?(session[:player_cards])
      @msg = "Congrats #{session[:player_name]}, you got blackjack! You win :)"
      end_game_variables
    end
  end

  def check_dealer_score
    if is_busted?(session[:dealer_cards])  # score > 21
      @msg = "Dealer busted! You win :)"
      end_game_variables
    elsif is_blackjack?(session[:dealer_cards]) # score == 21
      @msg = 'Dealer hit blackjack. You lose :('
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
      @msg = "Sorry, you lose. Dealer's total of #{dealer_score} beat your score of #{player_score}."
    elsif dealer_score < player_score
      @msg = "Congrats, you win! Your total of #{player_score} beat the dealer's score of #{dealer_score}."
    else
      @msg = "It's a tie."
    end
  end

end

before do
  @player_turn = true
  @dealer_turn = false
  @game_over = false
end

get '/' do
  if session[:player_name]
    redirect '/home'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end


post '/new_player' do
  if params[:player_name].empty?
    @error = 'Must enter a name'
    erb :new_player
  else
    session[:player_name] = params[:player_name]
    redirect '/home'
  end
end

get '/home' do
  erb :home
end

get '/blackjack/new' do
  #setup deck
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
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
  @msg = 'You chose to hit'
  session[:player_cards] << session[:deck].pop

  check_player_score
 
  erb :blackjack
end

post '/blackjack/player_stay' do
  @msg = 'You chose to stay.'
  @player_turn = false

  check_dealer_score # if dealer's score is between 17 and 21, will also compare scores
  
  erb :blackjack
end

post '/blackjack/dealer_hit' do
  session[:dealer_cards] << session[:deck].pop
  @player_turn = false

  check_dealer_score # if dealer's score is between 17 and 21, will also compare scores 
  
  erb :blackjack
end
