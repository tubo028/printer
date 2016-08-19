# coding: utf-8

require 'sinatra'
require 'sinatra/reloader'
require 'active_record'
require 'tempfile'

ADMIN_USERNAME = ENV['id'] || ''
ADMIN_PASSWORD = ENV['pw'] || ''
SESSIN_SECRET = ENV['ss'] || 'secret'
set :root, File.dirname(__FILE__)
set :url_root, '/printer'
set :session_secret, SESSIN_SECRET
enable :prefixed_redirects
enable :sessions

helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def basic_auth!
      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="どちらも空白")
        halt(401, "401")
      end
    end
    def authorized?
      return true

      @auth ||= Rack::Auth::Basic::Request.new(request.env)
      username = ADMIN_USERNAME
      password = ADMIN_PASSWORD
      true &&
        @auth.provided? &&
        @auth.basic? &&
        @auth.credentials &&
        @auth.credentials == [username, password]
    end
end

ActiveRecord::Base.establish_connection(
    "adapter" => "sqlite3",
    "database" => "./data.db"
)

class PrintQuery < ActiveRecord::Base  
end

get "/" do
  @error = session[:error]
  @message = session[:message]
  session.clear
  erb :form
end

get "/query/?" do
  basic_auth!
  @qs = PrintQuery.order("id desc").all
  erb :list
end

get "/query/:id" do
  basic_auth!
  match = params[:id].match(/^(\d+)$/)
  id = match ? match[0] : nil
  redirect '/query' unless id

  begin
    @q = PrintQuery.find(id)
  rescue
    halt(404, "404")
  end
  f = Tempfile.create('pygin')
  f.write(@q.source)
  f.close

  lang = @q.language || 'text'
  lang = lang.to_s.strip.downcase.
         gsub('#', 'sharp').gsub('+', 'p')
  lang = 'text' if !(lang =~ /^[a-zA-Z\+#]{1,20}/)
  lang = 'c++' if lang == 'cc'
  lang = 'text' unless system("pygmentize -l '#{lang}' /dev/null > /dev/null")
  @source = `pygmentize -O style=emacs,linenos=1 -l '#{lang}' -f html #{f.path}`
  erb :view
end

post "/submit" do
  session[:error] = {}
  session[:message] = {}

  if !params[:team_name].size.between?(1,50)
    session[:error][:team_name] = "チーム名は1文字以上50文字以下でお願いします"
  end
  if !params[:language].match(/^[a-zA-Z\+#]{1,20}$/)
    session[:error][:langage] ="言語は /^[a-zA-Z\+#]{1,20}$/ に受理されるものでお願いします"
  end
  if !params[:source].size.between?(1,100000)
    session[:error][:source] = "ソースコードは1文字以上100000文字以下でお願いします"
  end
  if !params[:comment].size.between?(0,100000)
    session[:error][:comment] = "コメントは100000文字以下でお願いします"
  end

  redirect '/' if session[:error].size > 0

  PrintQuery.create({:team_name => params[:team_name],
                     :language  => params[:language],
                     :source    => params[:source],
                     :comment   => params[:comment]
                    })
  session[:message] = {}
  session[:message][:send] = "送信しました (" +
                             "Language: #{params[:language]}, " +
                             "Length: #{params[:source].bytesize} bytes, " +
                             "Time: #{Time.now.localtime.strftime("%Y/%m/%d %X")})"
  redirect '/'
end

post %r{/(done|undone)} do |d|
  faild = { :id => params[:id], :status => "faild" }.to_json

  id = params[:id]
  return faild unless id
  return faild unless id =~ /^\d+$/
  @q = PrintQuery.find_by_id(id.to_i)
  return faild unless @q
  @q.printed_at = d == 'done' ? Time.now : nil
  begin
    @q.save
  rescue
    return faild
  end
  { :id => params[:id], :status => "succeeded" }.to_json
end

after do
  ActiveRecord::Base.connection.close
end
