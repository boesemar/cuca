# This file is -r required when runnung script/console to load
# support files automatically.
# Only for the CLI irb console

require 'cuca/urlmap'

puts "Cuca console: type: url [/some/path] to load support files of your app"
$app = Cuca::App.new

def url(some_path)
  $app.load_support_files(Cuca::URLMap.new($cuca_path+'/app', some_path))
end

url '/'
