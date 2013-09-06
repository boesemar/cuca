
require 'test/unit'
require 'cuca/cgi_emu'
require 'cuca/urlmap'

require 'ostruct'

module Cuca
module Test

# Some function that should help you testing your widgets and controllers
module Helpers


# init the application. call this from the setup method.
def init(app_path = '/', params = {})
 @cgi = CGIEmu.new({'PATH_INFO' => app_path, 'QUERY_PARAMS' => params})
 @app = Cuca::App.new
 @app.load_support_files(Cuca::URLMap.new($cuca_path+'/app', app_path))
end


# this will create a widget instance with params and block
# as passed to this function. Also it will pass current instance
# variables to the assigns.
def widget(widget_class, *args, &block)
 a = {}
 instance_variables.each do |v|
       a[v.gsub(/\@/,'')] = self.instance_variable_get(v)
 end
 return widget_class.new({:assigns => a, :args => args}, &block)
end

# same as above but enable the profiler to stdout
def widget_p(widget_class, *args, &block)
 a = {}
 instance_variables.each do |v|
       a[v.gsub(/\@/,'')] = self.instance_variable_get(v)
 end
 return widget_class.new({:assigns => a, :args => args, :profiler => $stdout}, &block)
end


#
# Functional Tests
#
def cgi_status_to_text(status)
  require 'cgi'
  CGI::HTTP_STATUS[status] || status
end

def cgi_to_result(cgi, other = {})
  op = cgi.out_params

  result = OpenStruct.new  
  result.status     = cgi_status_to_text(op['status'])
  result.status_cgi = op['status']
  result.type       = op['type']
  result.content    = cgi.out_content
  result.cookies    = cgi.output_cookies
  other.each { |k,v| result.send("#{k}=".intern, v) }
  result 
end


def measure_time
  t = Time.now.to_f
  yield
  Time.now.to_f - t
end

def get(target, query_parameters= {})
  @cgi = CGIEmu.new({'PATH_INFO' => target, 
                     'QUERY_PARAMS' => query_parameters,
                     'HTTP_COOKIE' => @test_http_cookie})
  @app = Cuca::App.new
  t = measure_time { @app.cgicall(@cgi) }
  cgi_to_result(@app.cgi, :time => t)
end

def post(target, request_parameters = {})
  require 'uri'
  body = URI.encode_www_form(request_parameters)
  @cgi = CGIEmu.new({'PATH_INFO'      => target, 
                     'REQUEST_METHOD' => 'POST', 
                     'CONTENT_LENGTH' => body.size, 
                     'CONTENT' =>  body,
                     'HTTP_COOKIE' => @test_http_cookie})
  @app = Cuca::App.new
  t = measure_time { @app.cgicall(@cgi) }
  cgi_to_result(@app.cgi, :time => t)
end


end
end
end

