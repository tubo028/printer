root_dir = File.dirname(__FILE__)
app_file = File.join(root_dir, 'app.rb')
require app_file

run Sinatra::Application
