#!/usr/bin/env ruby
#
# This will create a simple CGI lighttpd config file and run against the cuca application
#
# Takes one optional argument the full path the the ruby interpreter to use
#

require 'ostruct'
require 'optparse'

options = OpenStruct.new
options.ruby_interpreter = '/usr/bin/ruby'
options.dispatcher = 'dispatch.cgi'
options.port       = 2000
options.lighttpd   = 'lighttpd'

op = OptionParser.new do |opts|
	opts.banner = "Usage: server-lighttpd.rb [options]"
	opts.on("-pPORT", "--port=NAME", "TCP Port to listen on (2000)") do |x|
		options.port = x
	end
	opts.on("-iRUBY", "--interpreter=RUBY", "The ruby binary (/usr/bin/ruby)") do |d|
		options.ruby_interpreter = d
	end
	opts.on("-lPROGRAM", "--lighttpd=PROGRAM", "The lighttpd binary (/usr/sbin/lighttpd)") do |d|
		options.lighttpd = d
	end

	opts.on("-dDISPATCHER", "--dispatcher=DISPATCHER", "The cgi program in public/ directory (dispatch.cgi)") do |d|
		options.dispatcher = d
	end
	opts.on("-h", "--help", "Help") do 
		puts opts 
		exit 0
	end
end.parse!(ARGV)

puts options.inspect


if !File.exist?(options.ruby_interpreter) then
   STDERR.puts "Can't find ruby interpreter, use -i"
   exit 1
end

#if !File.exist?(options.lighttpd) then
#   STDERR.puts "Can't find lighttpd binary use -l"
#   exit 1
#end

cuca_path = File.expand_path(File.dirname(__FILE__))+"/../"

if !File.exist?(cuca_path + "/public/" + options.dispatcher) then
   STDERR.puts "Can't find dispatcher #{options.dispatcher} in public directory, use -d"
   exit 1
end


document_root = "#{cuca_path}/public/"
error_log = "#{cuca_path}/log/error.log"
access_log = "#{cuca_path}/log/access.log"
pid_file = '/tmp/lighttpd.pid'
server_program = options.lighttpd
server_port = options.port

config = <<-EOF

server.modules              = ( 
            "mod_access",
            "mod_alias",
            "mod_accesslog",
	    "mod_cgi"
 )

cgi.assign = ( ".cgi" => "#{options.ruby_interpreter}" )

server.document-root       = "#{document_root}"

server.port = #{server_port}

server.errorlog            = "#{error_log}"

server.error-handler-404 = "/#{options.dispatcher}"
# server.error-handler-404 = "/error-404.html"

index-file.names           = ( "index.html" )

accesslog.filename         = "#{access_log}"

server.pid-file            = "#{pid_file}"

dir-listing.encoding        = "utf-8"
server.dir-listing          = "disable"

# server.username            = "www-data"
# server.groupname           = "www-data"



 mimetype.assign = (
 ".rpm" => "application/x-rpm",
 ".pdf" => "application/pdf",
 ".sig" => "application/pgp-signature",
 ".spl" => "application/futuresplash",
 ".class" => "application/octet-stream",
 ".ps" => "application/postscript",
 ".torrent" => "application/x-bittorrent",
 ".dvi" => "application/x-dvi",
 ".gz" => "application/x-gzip",
 ".pac" => "application/x-ns-proxy-autoconfig",
 ".swf" => "application/x-shockwave-flash",
 ".tar.gz" => "application/x-tgz",
 ".tgz" => "application/x-tgz",
 ".tar" => "application/x-tar",
 ".zip" => "application/zip",
 ".mp3" => "audio/mpeg",
 ".m3u" => "audio/x-mpegurl",
 ".wma" => "audio/x-ms-wma",
 ".wax" => "audio/x-ms-wax",
 ".ogg" => "audio/x-wav",
 ".wav" => "audio/x-wav",
 ".gif" => "image/gif",
 ".jpg" => "image/jpeg",
 ".jpeg" => "image/jpeg",
 ".png" => "image/png",
 ".xbm" => "image/x-xbitmap",
 ".xpm" => "image/x-xpixmap",
 ".xwd" => "image/x-xwindowdump",
 ".css" => "text/css",
 ".html" => "text/html",
 ".htm" => "text/html",
 ".js" => "text/javascript",
 ".asc" => "text/plain",
 ".c" => "text/plain",
 ".conf" => "text/plain",
 ".text" => "text/plain",
 ".txt" => "text/plain",
 ".dtd" => "text/xml",
 ".xml" => "text/xml",
 ".mpeg" => "video/mpeg",
 ".mpg" => "video/mpeg",
 ".mov" => "video/quicktime",
 ".qt" => "video/quicktime",
 ".avi" => "video/x-msvideo",
 ".asf" => "video/x-ms-asf",
 ".asx" => "video/x-ms-asf",
 ".wmv" => "video/x-ms-wmv",
 ".bz2" => "application/x-bzip",
 ".tbz" => "application/x-bzip-compressed-tar",
 ".tar.bz2" => "application/x-bzip-compressed-tar"
 )
 
 
EOF


fn = '/tmp/lighttpd-cuca.conf'

f = File.new(fn, 'w')
f << config
f.close

puts "Starting lighttpd on port #{server_port}"
system("#{server_program} -D -f #{fn}")
