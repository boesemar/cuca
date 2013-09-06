$: << '/home/bones/workspace/cuca_svn/cuca/lib'
require 'cuca'
require 'rubygems'
# require 'cuca'
require 'rack/request'
require 'rack/response'
require 'rack/showexceptions'
require 'rack/handler'
require 'rack/handler/webrick'
require 'rack/lint'

Rack::Handler::WEBrick.run \
  Rack::ShowExceptions.new(Cuca::App.new),
    :Port => 1234
    


# Rack::Handler::WEBrick.run \
#  Rack::ShowExceptions.new(Rack::Lint.new(Cuca::App.new)),
#    :Port => 1234
    
    