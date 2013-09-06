#!/usr/bin/ruby

require 'webrick'
require 'cgi'


# this is for http debugging
class CucaHandler < WEBrick::HTTPServlet::CGIHandler
  alias :old_do_GET :do_GET
  
  def do_GET(req, res)
#    puts "------------ Request ----------\n #{req.to_s}"
    start = (Time.now.to_f * 100).to_i
    r = old_do_GET(req, res)
    stop = (Time.now.to_f * 100).to_i
#    $stderr.puts "WEBRICK: Time: #{stop - start} ms"
#    puts "------------ RESPONSE ----------\n #{res.to_s}"
  end
  
end

server = WEBrick::HTTPServer.new(:Port => 2000)
server.mount("/", CucaHandler, File.expand_path(File.dirname(__FILE__))+"/../public/dispatch-fwdev.cgi")

trap("INT"){ server.shutdown }
server.start
