$: << '/home/bones/workspace/cuca_svn/cuca/lib'
require 'cuca'
require 'rubygems'
# require 'cuca'
require 'rack/request'
require 'rack/response'
require 'rack/showexceptions'
require 'rack/handler'
require 'rack/handler/thin'
require 'rack/lint'


class MakeError
   def initialize(app)
    @app = app
  end
  
  def call(env)
    status, headers, body = @app.call(env)
    [500, headers,body]
  end
end



app = Cuca::App.new
app.use MakeError


Rack::Handler::Thin.run \
  Rack::ShowExceptions.new(app),
    :Port => 1234
 


# Rack::Handler::WEBrick.run \
#  Rack::ShowExceptions.new(Rack::Lint.new(Cuca::App.new)),
#    :Port => 1234
    
    
