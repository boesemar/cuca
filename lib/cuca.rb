require 'cgi'
require 'cuca/cgi_fix'
require 'rubygems'

# All Classes are defined under this namespace
module Cuca


class CucaException < Exception # :nodoc:
end

# Any error on the application
class ApplicationException < Exception
end

end

# To require config and environment
def init_save_require(filename)
 begin
   require filename
 rescue  LoadError => e
   title = "INIT Error [#{filename}]: #{e}"
   $stderr.puts title
   err = ''
   e.backtrace.each do |b|
     err << "    #{b}\n"
   end
   $stderr.puts err
   c = CGI.new
   c.out { "<b>#{title}<br><br>#{err.gsub(/\n/,'<br>')}" }
 end
end



if $cuca_path.nil? then
 $stderr.puts "WARN: $cuca_path not found, assuming #{Dir.pwd}"
 $cuca_path = Dir.pwd
end

require 'cuca/const'

$cuca_path = File.expand_path($cuca_path) + '/'

$cuca_path.freeze

require 'cuca/app'

$LOAD_PATH << $cuca_path+'/lib'

init_save_require($cuca_path+'/conf/config')

require 'cuca/widget'
require 'cuca/controller'
require 'cuca/layout'

init_save_require($cuca_path+'/conf/environment')
