
require 'cgi/session'
require 'cgi/session/pstore'

require 'cuca/app'
require 'cuca/widget'
require 'cuca/sessionflash'
require 'cuca/sessionpage'

module Cuca


# == Description
# Session can be used to store stateful data. It is not loaded by default, to make
# use of it you must require this module and tell a controller to use a session.
#
# == Example Use (permanent data)
#
# Initialize (using a controller):
#
#  class ApplicationController < Cuca::Controller
#    use_session
#  end
#
# Save and Load data (from any widgets e.g. controller):
#
#  class IndexController < ApplicationController
#
#    def run
#       session[:stuff_to_remember] = "hello world"
#       @stuff = session[:stuff_to_remember]
#    end
# end
#
# == Flash Memory
#
# The flash memory can be used to store temporarily data for the current and
# next action. A typical example are messages after a post event, like:
#
#  class LoginController < ApplicationController
#      (...)
#     def post
#         if (params['username'] == 'root' && params['pass'] == 'stuff') then 
#            session.flash[:message] = "You are logged in"
#            session[:username] = 'root'
#            stop :redirect => 'index'
#         end
#     end
#  end
#
# If you want to keep the flash memory for another cycle you can call:
#
#  session.flash.keep
#
#
# == Page Memory
#
# Page memory is a container to store data only valid for the current action.
# It will be erased once you leave to a different action.
# Current request and query parameters (get/post) are automatically available in this
# container.
#
#
# 
# == Configuration
#
# Session is using some values from App::Config :
#
# 'session_prefix'
# 'session_valid'
# 'session_key'
#
class Session
 attr_reader :flash
 attr_reader :page
 attr_reader :cgi

 private
 def make_session
   @sess = CGI::Session.new(@cgi, @session_parameters)
 end

 public
 def reset
   begin
     @sess.delete
   rescue
   end
   make_session
 end


 # returns true/false if a session exists
 def exists?
   begin
      p = @session_parameters.clone
      p['new_session'] = false
      session = CGI::Session.new(cgi, p)
   rescue ArgumentError
      return false
   end
   return true
 end

 def initialize(cgi)
   @cgi = cgi

   @session_parameters = {
          'database_manager' => CGI::Session::PStore,
          'session_key' => App::config["session_key"],
          'session_path' => '/',
#          'new_session' => false,
          'session_expires' => Time.now + App::config["session_valid"].to_i,
          'prefix' => App::config["session_prefix"] }

   make_session


   @flash = SessionFlash.new(self)
   @page  = SessionPage.new(self)
 end

 def []=(key, value) 
   @sess[key] = value
 end
 
 def [](key)
   return @sess[key]
 end

 def close
   @sess.close
 end

 def update
   @sess.update
 end
 
 def delete
   @sess.delete
 end

 
end

class Controller
  # This will create filters that initialize the session before the action and
  # close it afterwards.
  def self.use_session
     priority_before_filter('ses_initialize_session')
     priority_after_filter('ses_close_session')
  end

  def ses_initialize_session
    $session = Session.new($app.cgi)
  end
  def ses_close_session
    $session.close
#    $session = nil
  end
end


class Widget
  def session
     $session
  end
end

end

