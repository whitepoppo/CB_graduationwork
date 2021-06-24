require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'pry'
require 'date'

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
    redirect '/toppage'
end

get "/mypage" do
    @name = session[:user]['name'] # 書き換える
    user_id = session[:user]['id']
    # if !params[:reservation].nil?
    @reservations = client.exec_params("SELECT * from reservations WHERE user_id = $1", [user_id]).to_a
    #binding.pry
    # end
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
    reservation = client.exec_params("SELECT * from reservations WHERE date = $1 AND start_time = $2", [date, start_time]).to_a
    #binding.pry
    t = date
    if Date.parse(t) < Date.today
        return erb :reserve
    else
        session[:reservation] = reservation
        return redirect '/reserved'
    end
end

get "/reserved" do
    user_id = session[:user]['id']
    @reservations = client.exec_params("SELECT * from reservations WHERE user_id = $1", [user_id]).to_a
    #binding.pry
    @name = session[:user]['name']
    return erb :reserved
end

get "/menu" do
    return erb :menu
end

get "/cafelog" do
    @posts = client.exec_params("SELECT * from posts").to_a
    return erb :cafelog
end

post "/cafelog" do
    title = params[:title]
    content = params[:content]
    
    if !params[:image].nil? # データがあれば処理を続行する
        tempfile = params[:image][:tempfile] # ファイルがアップロードされた場所
        save_to = "./public/images/#{params[:image][:filename]}" # ファイルを保存したい場所
        FileUtils.mv(tempfile, save_to)
        image_path = params[:image][:filename]
    end
    client.exec_params(
    "INSERT INTO posts (title, content, image_path) VALUES ($1, $2, $3)",
    [title, content, image_path]
    )
    redirect '/cafelog'
end

post "/delete" do
    Comment.find(@posts).destroy
end


get '/posts/new' do
    return erb :new_board
end