#!/usr/bin/env ruby


$cuca_path = File.dirname(__FILE__)+"/../"

require 'rubygems'
require 'cuca'

require "fcgi"

Signal.trap("INT") do
  $stderr.puts "INT caught"
  exit
end

application = Cuca::App.new

FCGI.each_cgi do |cgi|
  CGI::fix_env(cgi.env_table)
  start = (Time.now.to_f * 1000).to_i
  application.cgicall(cgi)
  stop = (Time.now.to_f * 1000).to_i
  dur_msec = stop - start
  application.logger.info("App::cgicall (#{cgi.path_info}: #{dur_msec} msec [= #{(1000 / dur_msec).to_i} pages / second]")  
end
