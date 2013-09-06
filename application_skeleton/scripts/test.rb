#!/usr/bin/ruby

require 'webrick'

server = WEBrick::HTTPServer.new(:Port => 2000)
server.mount("/", WEBrick::HTTPServlet::CGIHandler, File.expand_path(File.dirname(__FILE__))+"/../public/test.cgi")
trap("INT"){ server.shutdown }
server.start
