require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?
require 'pry'

set :sessions, true

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

get '/new_blackjack' do
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
  redirect '/blackjack'
end

get '/blackjack' do
  erb :blackjack
end
