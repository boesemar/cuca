#!/usr/bin/env ruby

$cuca_path = File.dirname(__FILE__)+"/../"

require 'rubygems'
require 'cuca'

Signal.trap("INT") do
  $stderr.puts "INT caught"
  exit
end

start = (Time.now.to_f * 1000).to_i
application = Cuca::App.new
application.cgicall
stop = (Time.now.to_f * 1000).to_i
dur_msec = stop - start
application.logger.info("App::cgicall: #{dur_msec} msec [= #{(1000 / dur_msec).to_i} pages / second]")
