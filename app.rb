require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'pry'

enable :sessions


client = PG::connect(
    :host => "localhost",
    :user => ENV.fetch("USER", "sagawakarin"), :password => '',
    :dbname => "mysite")


get "/toppage" do
    return erb :toppage
end

# get "/signin" do
#     return erb :signin
# end

# post "/signin" do
#     session[:user] = params[:name]
#     redirect '/mypage'
# end

# get "/mypage" do
#     @name = session[:user]
#     return erb :mypage
# end


get '/signup' do
    return erb :signup
end

post '/signup' do
    name = params[:name]
    email = params[:email]
    password = params[:password]
    client.exec_params("INSERT INTO users (name, email, password) VALUES ($1, $2, $3)", [name, email, password])
    user = client.exec_params("SELECT * from users WHERE email = $1 AND password = $2", [email, password]).to_a.first
    session[:user] = user
    return redirect '/mypage'
end

get '/signin' do
    return erb :signin
end

post '/signin' do
    email = params[:email]
    password = params[:password]
    user = client.exec_params("SELECT * FROM users WHERE email = '#{email}' AND password = '#{password}'").to_a.first
    if user.nil?
        return erb :signin
    else
        session[:user] = user
        return redirect '/mypage'
    end
end


delete '/signout' do
    session[:user] = nil
    redirect '/signin'
end

get "/mypage" do
    @name = session[:user]['name'] # 書き換える
    user_id = session[:user]['id']
    @reservations = client.exec_params("SELECT * from reservations WHERE user_id = $1", [user_id]).to_a
    return erb :mypage
end

get "/reserve" do
    return erb :reserve
end

post "/reserve" do
    date = params[:date]
    start_time = params[:start_time]
    end_time = params[:end_time]
    guests = params[:guests]
    user_id = session[:user]['id']
    #binding.pry
    client.exec_params("INSERT INTO reservations (user_id, date, start_time, end_time, guests) VALUES ($1, $2, $3, $4, $5)", [user_id, date, start_time, end_time, guests])
    return redirect '/reserved'
end

get "/reserved" do
    user_id = session[:user]['id']
    @reservations = client.exec_params("SELECT * from reservations WHERE user_id = $1", [user_id]).to_a
    #binding.pry
    @name = session[:user]['name']
    return erb :reserved
end

