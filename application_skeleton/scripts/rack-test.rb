
require 'rubygems'
require 'rack'
require 'rack/session/cookie'


class Middle
  def initialize(app)
    @app = app
  end
  
  def call(env)
    $stderr.puts "CAll for MIDDLE"
    status, headers, body = @app.call(env)
    [400, headers, [body.first.upcase]]
  end
end

class Cuca
  def initialize(app)
    @app = app
  end
  
  def call(env)
    $stderr.puts "CAll for CUCA"
    $stderr.puts "#{@app.inspect}"
    @app.call(env)
    [200, {'Content-Type' => 'text/html'}, ['some Dynamic Website']]
  end
end



class App < Rack::Builder
 
end


app = App.new
app.use Cuca

app.use Middle
puts app.to_app.inspect


Rack::Handler::Thin.run(
          Rack::ShowExceptions.new(
                Rack::Lint.new(
			app.to_app
		)
          ), :Port => 1234)

