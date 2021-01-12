require 'cuca/app'
require 'cuca/widget'

module Cuca


# == Description
#
# Session is used to statefull data
#
# But cuca doesn't help you anymore with saving a it server-side or making cookies.
# This is simply a wrapper around a hash that you need to keep yourself either with the 
# Rack Session middleware or your own implementation.
#
# == Example of use with the Rack Session Middlware
# require 'cuca/session'
#
# class SessionController < ApplicationController
#   before_filter :session_start
#
#   def session_start
#       @session = Cuca::Session.new(request, request.session)
#   end
#   def session
#       @session
#   end
# end
#
# class IndexController < SessionController
#   def run
#      session.page['something'] = "some other thing"   # a variable only available to this page
#   end
#  end

# Flash Memory - will only be kept for the next next time you render a page (good for messages before a redirect)


class SessionFlash
  def initialize(data)
    @data = data
    @rootkey = 'session-flash'
    @data[@rootkey] ||= {}
  end
  def memory
    @data[@rootkey]
  end
  def [](key)
    item = @data[@rootkey][key]
    return nil unless item
    @data[@rootkey].delete(key)
    item
  end
  def []=(key, value)
    @data[@rootkey][key] = value
  end
end

# SessionPage keeps data just for the current page (URL!)
#
# session-page
#   Pk_/some/path
#      data => value
#      data2 => value
#   Expire
#      pk_/some/data => Timestamp

class SessionPage
  def pagekey
    path_a = @request.path_info.split('/').find_all {|x| !x.empty?}
    pk = @request.path_info.split('/').last 
    
    if pk =~ /^-(.+)-/ then   # strip subcalls
      pk = $1
    end
    key = (path_a[0..-2].push(pk)).join('_')

    "Pk_#{key}".intern
  end
 
  def delete(key)
    @data[@rootkey].delete(@pagekey)
    @data[@rootkey][@expirekey].delete(@pagekey)
  end

  # delete all from current page memory 
  def reset
    @data[@rootkey][@pagekey] = {}
  end
 
  # access to pagemem
  def memory
    @data[@rootkey][@pagekey]
  end

  def initialize(data,request)
    @data = data
    @request = request
    @rootkey = 'session-page'
    @expirekey = 'Expire'
    @pagekey = self.pagekey
    @data[@rootkey] ||= {}
    @data[@rootkey][@pagekey] ||= {}
    @data[@rootkey][@expirekey] ||= {}
    @data[@rootkey][@expirekey][@pagekey] = (Time.now + (4*3600)).to_i
    @data[@rootkey][@expirekey].each do |pk, timestamp|
      next if pk == @pagekey
      if timestamp <= Time.now.to_i - (3600*4) then 
        @data[@rootkey].delete(pk)
        @data[@rootkey][@expirekey].delete(pk)
      end
    end
    #preload GET/POST
    request.params.each do |k,v|
      @data[@rootkey][@pagekey][k] = v
    end
  end

  def [](key)
    @data[@rootkey][@pagekey][key]
  end

  def []=(key,val)
    @data[@rootkey][@pagekey][key] = val
  end
end

class Session
  attr :data

  def initialize(request, initial_data=nil)
    if !initial_data then 
      if !request.session then 
        raise "Session not available load Rack Middleware"
      end
      @data = request.session
    else
      @data = initial_data
    end
    @request = request
  end

  def encode
    @data.to_json
  end

  def decode(raw_data)
    @data = JSON.parse(raw_data)
  end

  def [](key)
    @data[key]
  end

  def []=(key,val)
    raise "Reserved key" if key == 'session-page'
    raise "Reserved key" if key == 'session-flash'
    @data[key] = val
  end

  def page
    @page ||= SessionPage.new(@data, @request)
    @page
  end
  def flash
    @flash ||= SessionFlash.new(@data)
    @flash
  end
end
  

end

