# little fake cgi class that allows automated testing of cgi application

require 'stringio'

class CGIEmu < CGI
   
  attr_reader :out_params
  attr_reader :out_content
  
  attr_reader :output_cookies    # made by CGI::Session

  class EnvTable
    def initialize(options)
     @test_path_info = options['PATH_INFO'] || '/'
     @test_query_params = options['QUERY_PARAMS'] || {}
     @request_method = options['REQUEST_METHOD'] || 'GET'
     @content_length = options['CONTENT_LENGTH'] || 0
     @http_cookie    = options['HTTP_COOKIE']
    
     the_env_table.each_pair { |k,v| ENV[k] = v.to_s }

#     ENV.merge(the_env_table)
    end

    def query_string
      r = [] 
      @test_query_params.each_pair { |k,v| r << "#{k}=#{v}" }
      return r.join('&')
    end

  
    def the_env_table
     {"SERVER_NAME"=>"localhost", 
     "PATH_INFO"=>@test_path_info,
     "REMOTE_HOST"=>"localhost", 
     "HTTP_ACCEPT_ENCODING"=>"x-gzip, x-deflate, gzip, deflate",
     "HTTP_USER_AGENT"=>"Mozilla/5.0 (compatible; Konqueror/3.5; Linux) KHTML/3.5.8 (like Gecko)", 
     "SCRIPT_NAME"=>"", 
     "SERVER_PROTOCOL"=>"HTTP/1.1", 
     "HTTP_ACCEPT_LANGUAGE"=>"en", 
     "HTTP_HOST"=>"localhost:2000", 
     "REMOTE_ADDR"=>"127.0.0.1", 
     "SERVER_SOFTWARE"=>"WEBrick/1.3.1 (Ruby/1.8.6/2007-06-07)",
     "HTTP_REFERER"=>"http://localhost:2000/",
     "HTTP_ACCEPT_CHARSET"=>"utf-8, utf-8;q=0.5, *;q=0.5",
     "REQUEST_URI"=>"http://localhost:2000" + @test_path_info, 
     "SERVER_PORT"=>"2000", 
     "GATEWAY_INTERFACE"=>"CGI/1.1", 
     "QUERY_STRING"=>query_string, 
     "HTTP_ACCEPT"=>"text/html, image/jpeg, image/png, text/*, image/*, */*",
     "SCRIPT_FILENAME"=>"/home/bones/workspace/cuca/scripts/../public/dispatch.cgi",
     "REQUEST_METHOD"=>@request_method, 
     "HTTP_CONNECTION"=>"Keep-Alive",
     "CONTENT_LENGTH" => @content_length,
     "HTTP_COOKIE" => @http_cookie,
#     'CONTENT_TYPE' => "application/x-www-form-urlencoded"
     }
    end

    def [](key)
 #     $stderr.puts "get FROM ENV_TABLE(#{key}) ==> #{the_env_table[key]}"
      return the_env_table[key] || nil
    end
  end
  
  def env_table
    EnvTable.new(@test_options)
  end

  def stdinput
    StringIO.new(@content)
  end

  def initialize(options)
    @content =  options['CONTENT'] || ''
    options.delete('CONTENT')
    @test_options = options
    super()
  end

  def out(params, &block)
    @out_params = params
    @out_content = block.call
  end

end

