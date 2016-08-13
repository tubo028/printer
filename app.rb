require 'sinatra'
require 'sinatra/reloader'
require 'active_record'

ActiveRecord::Base.establish_connection(
    "adapter" => "sqlite3",
    "database" => "./data.db"
)

class PrintQuery < ActiveRecord::Base
end

get "/" do 
    @qs = PrintQuery.order("id desc").all
    erb :index
end

get "/submit" do 
  PrintQuery.create({:team_name => "aaa",
                     :language  => "java",
                     :source    => "sfalsjfal"
                    })
  redirect '/'    
end

after do
  ActiveRecord::Base.connection.close
end
