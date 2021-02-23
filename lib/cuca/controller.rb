module Cuca

# :nodoc:
class BreakControllerException < StandardError
 # flags can be:
 # :layout => 'new_layout' or false
 # :redirect => '/to/new/url'	= dont render, just redirect
 # :error => "something happend" = display an application error 
attr_reader :flags
 def initialize(flags = {})
   @flags = flags
 end
end


# = Cuca Controller
#
# A controller handles the get/post request for your website and has the ability to
# generate an output directly making use of other Widgets and Layouts.
#
# The Controller class itself behaves just like Cuca::Widget, but instead of overwriting
# the output method you must implement run or post or get or any combination.
#
# Additionally you can also define a wrapping layout (using the layout function) and you can
# run code before and after a certain action is called using before/after_filter's.
#
# == Naming
#
# When you open a url like: http://your.website.com/users/list cuca will load the file /users/list.rb 
# from your application path (usually app/users/list.rb). Within that file you must define one
# class derrived from Cuca::Controller with name FilenameController. The /users/list.rb example must
# therefor implement the ListController class.
# 
# == Subcalls
#
# Sometimes you might want to implement another URL that is logically joined with your
# current page ("Ajax"?). To do this you can implement a (get|post|run)_subcallname method within
# your controller. This one will get called if you open http://your.website.com/-controller-subcallname .
#
# == Routing / Pretty URL's
#
# Depending on your directory structure within the app folder you can define variable directory names 
# that will hint you within the controller.
#
# Example:
# File: app/user/__default_username/show.rb will map to http://user/johnrambo/show and define instance variable 
# @username within the Controller defined in show.rb
# 
# The magic URL prefix (default: __) can be change within App::Config
#
# == Defining a Layouts
#
# In most cases a layout is defined on the controller class definition with the
# layout instruction:
#
#  class IndexController
#      layout 'standard'
#  end
#
# In some cases you want to render a different layout or disable it at all. For
# this you can call within your action the 'layout' instance method that will
# temporarily the instruct the controller to render another layout or no layout
# (if false).
#
#
# == Interrupting the program
#
# If you want to stop your program you can call the 'stop' method. Stop take some arguments
# that allows you to redirect, display error or set a different layout.
#
#
# == Filters
#
# A filter method can be run before or after the controller code is executed. It can be used
# to prepare data, restrict access or format the generated content for example.
# See: before_filter and after_filter
#
# == Examples
#
# Hello world (index.rb):
#
#  class IndexController < Cuca::Controller
#   def run
#      content << "Hello World"
#   end
#  end
# 
# Using filters and layouts and generate page using the Markaby generator (fancy.rb):
#
#  require 'cuca/generators/markaby'
#
#  class FancyController < Cuca::Controller
#    include Cuca::Generator::Markaby
#    layout 'fancy'
#    before_filter 'set_title'
# 
#    def set_title
#      @page_title = "A Fancy Page"
#    end
# 
#    def get
#       mab do
#          h1 { "Welcome to the Fancy Page called #{@page_title}" }
#          p { text "Welcome to my" 
#             b { "paragraph" } 
#          }
#       end
#    end
#  end
#
# 
class Controller < Widget

 attr_reader :cancel_execution  # this can be set by anyone, 
				# methods get/post/run will not be executed

 
 # Tells the app what to send to the browser 'text/html'
 def mime_type(mt=nil)
  @_mime_type = mt unless mt.nil?
  @_mime_type
 end

 # A ruby cgi status type 'OK', 'NOT_FOUND'....to be sent within the http header
 def http_status(hs=nil)
  @_http_status = hs unless hs.nil?
  @_http_status
 end

 # Add additional http header for the response
 # No validation made
 def http_header(field=nil, value=nil)
   @_http_header ||= {}
   @_http_header[field] = value if field
   @_http_header
 end

 # get layout
 private	# ??
 def self.def_layout
   self.run_attr_method('def_layout_name')
 end

 # define a layout for the Controller
 public
 def self.layout(name)
   define_attr_method(:def_layout_name,  name)
 end
 
 # define a layout for the current instance
 def layout(name)
   $stderr.puts "Overwriting Layout: #{self.class.def_layout.inspect} with #{name}"
   @_layout = name
 end


 private
 def self.define_filter_method(chain_name, method_name, priority=50)
   begin
     filters = self.send(chain_name)
     filters = "#{filters};#{method_name}|#{priority.to_s}"
     define_attr_method(chain_name, filters)
   rescue NoMethodError => e
     define_attr_method(chain_name, "#{method_name}|#{priority.to_s}")
   end
 end

 # One or more before filter can set by an application Controller
 # The instance methods will be run before the action get ran (get/post/run)
 # If you have many filters and need order you can set the priority option.
 # Lower priorities will run first.
 public
 def self.before_filter(method, priority = 50)
    define_filter_method(:def_before_filter, method, priority)
 end

 # Priority before filters will be ran before any before filters
 # this should be only used internally or for core extension
 public
 def self.priority_before_filter(method)
   define_filter_method(:def_priority_before_filter, method)
 end

 # Priority after filters will be ran after any after filters
 # this should be only used internally or for core extension
 # also this gets called no matter if anyone raises :stop method
 public
 def self.priority_after_filter(method)
   define_filter_method(:def_priority_after_filter, method)
 end

 # after_filter - get run after the controller action has be executed
 # If you have many filters and need order you can set the priority option.
 # Lower priorities will be ran first.
 public
 def self.after_filter(method, priority = 50)
   define_filter_method(:def_after_filter, method, priority)
 end

 private
 def run_filters(chain_name, debug_filter_names)
   filter_str = self.class.run_attr_method(chain_name.to_s)
   return if filter_str.nil?

   filters = []
   filter_str.split(';').each do |f|
        next if f.strip == ''
        mp = f.split('|')
        filters << [mp[0], mp[1]]
   end

   sorted_filters = filters.sort { |a,b| a[1].to_i <=> b[1].to_i }

   sorted_filters.each do |f|
     break if @cancel_execution
     filter = f[0]
     begin
       if (!self.respond_to?(filter.intern)) then
           http_status "SERVER_ERROR"
           raise ApplicationException.new("Filter not found in chain #{debug_filter_names}: #{filter}")
       end
       ret = self.send(filter.intern)
       @cancel_execution = true if ret == false 
      rescue BreakControllerException => bc
        handle_exception(bc)
      end
   end
 end


 # this will run defined before filters on a controller instance
 public
 def run_before_filters
   run_filters(:def_priority_before_filter, 'Priority Before Filters')
   run_filters(:def_before_filter, 'Before Filters')
 end

 # run defined after_filters
 public 
 def run_after_filters
   run_filters(:def_after_filter, 'After Filters') \
      unless @_stop_no_after_filters
   ce = @cancel_execution
   @cancel_execution = false
   run_filters(:def_priority_after_filter, 'Priority After Filters')
   @cancel_execution = ce
 end


 # this method will stop execution of the controller
 # it's usefull to break somewhere in the middle or to 
 # set a different layout
 # flags can be
 # :layout - Set a new layout, or 'false' for no layout
 # :redirect - redirect to a different page
 # :error - An error message (for application errors)
 # :no_after_filters - Do not execute any after filters defined
 def stop(flags = {})
   raise BreakControllerException.new(flags)
 end

 
 # this piece of code will handle a thrown exception BreakControllerException
 def handle_exception(e)
   if e.flags.has_key?(:layout) then
       @_layout = e.flags[:layout]
   end

   if e.flags.has_key?(:no_after_filters) then
       @_stop_no_after_filters = true
   end

   if e.flags.has_key?(:redirect) then
     @_layout = false
     to = e.flags[:redirect]
     clear
     @_content = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0 Transitional//EN\"><html><head><title>Redirecting...</title><meta http-equiv=\"REFRESH\" content=\"0;url=#{to}\"></HEAD></HTML>"
     @cancel_execution = true
   end

   if e.flags.has_key?(:error) then
     @_layout = false
     http_status "SERVER_ERROR"
     clear
     @error_message = e.flags[:error]
     @cancel_execution = true
     trace = ''
     if Cuca::App.config['display_errors'] then
       e.backtrace.each do |b|
          trace<< "<br/>#{b}"
       end
     end
     mab { html { body { h2 "Error"; text @error_message; br; text trace }}}
   end
   
   if e.flags.has_key?(:cancel_execution) then
     @cancel_execution = true
   end
 end

 def action_name
   $cuca.value[:url_scan].action
 end
 
 private
 # Overwrite this method to handle get and post events
 def run
 end
 
 # Overwrite this method to handle get events
 def get
 end

 # Overwrite this method to handle post events
 def post
 end



 # This is the method as called from App. It will call 'get', 'post', 'run' and handle
 # exceptions. what within [post,get,run]
 # TOTHINKABOUT: run before filter from this method?
 public
 def _do(what, subcall = nil)	
   return if @cancel_execution
   
   method_name = what
   method_name = "#{method_name}_#{subcall}" if subcall
   begin
      self.send(method_name) if self.respond_to?(method_name.intern)
   rescue BreakControllerException => e
      handle_exception(e)
   end
 end


 def initialize(*args)
    @cancel_execution = false
    super(*args)

    # FIXME: to think about...
    get_assigns.each_pair do |k,v|
      instance_variable_set("@#{k}", v)
    end

    @_mime_type   = Cuca::App.config['default_mime_type']
    @_http_status = 'OK'
 end

 private
 def load_layout
   l = @_layout.nil? ? self.class.def_layout : @_layout
   return nil if (l.nil? || l == false)
   lname = l.capitalize+"Layout"

   begin
     layout_class = Object::const_get(lname)
   rescue => e
     raise ApplicationException, "Could not load layout: #{lname}: #{e}"
     return nil
   end
 end

 public
 def output
   layout_class = load_layout
   return content unless layout_class
   c = content.to_s
   a = get_assigns
   a[:content_for_layout] = c
   @_content = layout_class.new(:assigns=>a)
 end
end


end # Module
