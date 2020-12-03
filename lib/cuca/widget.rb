module Cuca
# = Widget
#
# All elements that generate content (e.g. html) are widgets. To implement a widget create
# a class derrived from Cuca::Widget and overwrite the +output+ method. The output method 
# can take any argument or blocks - whatever you need to build your content. At the end you 
# should write your result to @_content. For this it is advisable to use the content accessor 
# or any of the Cuca::Generator 's. 
#
# == Naming
#
# Name all widgets like YournameWidget - when using them in a generator simply call them
# without the 'Widget' and directly with the paramenters of the output.
#
# == Examples
# An example widget without a generator:
#
#  class BigfontWidget < Cuca::Widget
#    def output(text_to_print)
#       content << "<b><i>#{text_to_print}</i></b>"
#    end
#  end
#
#
# Example with the Markaby Generator - makes use of the BigfontWidget example above
#
#  require 'cuca/generators/markaby'
#
#  class HeadlineWidget < Cuca::Widget
#   include Cuca::Generator::Markaby
#
#   def output(text_to_print)
#     @t = text_to_print		# only instance variables are visisble to generators  
#     mab { div.headline { Bigfont(@t) }} 
#   end
#  end
#
class Widget

  # An accessor to @_content
  # All 'generators' (like the mab -function) should append their
  # generated clear text to @_content, latest with the before_to_s method
  def content
    @_content
  end
  
  # overwrite the content
  def content=(newval)
    @_content = newval
  end
  

  # an accessor to the current controller object - if available, otherwise nil
  def controller
    $controller_object || nil
  end

  # Hints is shared a shared container for all widgets. If you want to pass an information
  # from one widget to another this can be useful.
  # The last widget renered is the controller, then the Layout.
  def hints
    @@_hints
  end

  # clear all hints
  def self.clear_hints
    @@_hints = {}
  end
  
  # An accessor to the global cgi variables
  def cgi
    $request
#   $app.cgi
  end

  def request
    $request
  end

  # An accessor to the global logger variables
  def log
   $app.logger
  end

  # An accessor to the Cuca::app object
  def app
   $app
  end
  

  # an accessor to cgi.parameters variables. This is NOT params from the CGI class 
  # (see cgi_fix)
  def params
    $request.params
#    $app.cgi.parameters
  end
  
  # accessor to cgi query parameters (http GET)
  def query_parameters
    $request.GET
#     $app.cgi.query_parameters
  end
  
  # accessor to the cgi request parameters (http POST)
  def request_parameters
    $request.POST
#    $app.cgi.request_parameters
  end
  
  # an accessor to request_method
  def request_method
    $request.request_method
#    return $app.cgi.request_method
  end

  # Escape a string to use with URL etc..
  def escape(text)
    CGI::escape(text)
  end

  # Unescape an escaped string
  def unescape(text)
    CGI::unescape(text)
  end

  # escape a string on HTML codes
  def escapeHTML(text)
    CGI::escapeHTML(text)
  end
  
  # unescape an html escaped string
  def unescapeHTML(text)
   CGI::unescapeHTML(text)
  end

  
  # initialize - don't use widgets directly with .new.
  #
  # params[:assigns] variables in form of hash(var=>val) to make available to
  # the generator blocks if they require/need
  # params[:args] will be passed to the output method
  # block will also be passed to the output method
  def initialize(params = {}, &block)
   @_assigns = params[:assigns] || {} 
   @_args = params[:args] || {}
   @_profiler = params[:profiler] || nil
   @_block = block
   @_content = ""

   @@_hints ||= {}
  end
  
  # will fetch a list of assigns to be passed to a code generator block
  # this includes the :assigns from the constructor plus all instance
  # variables from the widget
  def get_assigns
    a = @_assigns.clone

    self.instance_variables.each do |v|
      vs = v.to_s
      next if vs.match(/^\@\_/)
      next if vs.include?('cancel_execution')		# this is some internal key
      a[vs.gsub(/\@/,'')] = self.instance_variable_get(v)
    end
    a
  end

  # clear widgets generated content
  def clear
   @_content = ""
  end


  # Overwrite this method with a function that takes the arguments and optionally
  # a block as you like.
  def output(*args, &block)
    @_content = "This widget doesnt have any content"
  end

  
  # this method can be implemented by the generator
  # to do finishing touches to @_content. Will be called before
  # @content.to_s is returned to the controller/App
#  def before_to_s
#  end

  # get cleartext for the widget
  def to_s
    if @_profiler then 
       require 'profiler'
       Profiler__::start_profile
    end
       
    output(*@_args, &@_block)
    before_to_s if self.respond_to?(:before_to_s)
    out = @_content.to_s

    if @_profiler then
        Profiler__::stop_profile
        @_profiler.puts "____________________PROFILER #{self.class.inspect} ______________________"
        Profiler__::print_profile(@_profiler)
    end

    out
  end


  # this can be used by derrived classes
  def self.define_attr_method(name, value=nil)
    sing = class << self; self; end
    sing.class_eval "def #{name}; #{value.inspect}; end"
#  $stderr.puts "def #{name}; #{value.to_s.inspect}; end"
  end

  # tries to run a class method if defined and return it
  def self.run_attr_method(name)
    return nil unless self.respond_to?(name.intern)
       
    self.send(name.intern)
  end


end

end # Module
