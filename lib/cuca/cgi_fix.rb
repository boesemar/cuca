#!/usr/local/bin/ruby

require 'cgi'

# We'll add three methods to the cgi class in order to separete get/post requests:
# * parameters -- all (mixed) get and post
# * query_parameters -- get
# * request_parameters -- post
#
class CGI # :nodoc:
  class << self
    def fix_env(ec)
      if (ec['PATH_INFO'].nil? || ec['PATH_INFO'] == '') then
         pi =  ec['REQUEST_URI']
         pi = pi[0..(pi.index('?')-1)] if pi.include?('?')
         ec['PATH_INFO'] = pi
      end
    
      if (ec['QUERY_STRING'].nil? || ec['QUERY_STRING'] == '') then
         ec['QUERY_STRING'] = ec['REQUEST_URI'].include?('?') ?
             ec['REQUEST_URI'].scan(/.?\?(.*)/)[0][0] :
             ""
      end
      ec
    end
  end 
   
   
  def env_table
    CGI::fix_env(ENV)
    ENV
  end

  def parameters
    query_parameters.merge(request_parameters)
  end

  def query_parameters
     res = {}
     query_string.split(/[&;]/).each do |p|
              k, v = p.split("=")
              v = '' if v.nil?
              res[CGI.unescape(k)] = CGI.unescape(v)
     end
     res
  end

  def request_parameters
   if request_method == 'POST' then
     res = {}
     params.each_pair { |k,v| res[k] = v[0] }
     return res
   else
    return {}
   end
  end

 # cgi implementation test
 def cgidump
   s = ""
   s << "-----ENV------<br>"
   self.env_table.each_pair { |k,v| s << "#{k} => #{v}<br>" }
   s << "--------------<br>"
   s << "Server Software: #{self.server_software}<br>"
   s << "PATH INFO: #{self.path_info}<br>"      
 end

end
