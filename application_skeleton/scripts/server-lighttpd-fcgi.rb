#!/usr/bin/ruby

cuca_path = File.expand_path(File.dirname(__FILE__)+"/../")
document_root = "#{cuca_path}/public/"
error_log = "#{cuca_path}/log/error.log"
access_log = "#{cuca_path}/log/access.log"
pid_file = '/tmp/lighttpd.pid'
dispatcher = "dispatch.fcgi"
server_port = 2000
server_program = "/usr/sbin/lighttpd"

config = <<-EOF

server.modules              = ( 
            "mod_access",
            "mod_alias",
            "mod_accesslog",
	    "mod_fastcgi"
 )

# cgi.assign = ( "" => "/usr/bin/ruby" )

fastcgi.server = ( "/"   =>   (( "bin-path" => "#{cuca_path}/public/#{dispatcher}",
                                 "socket"   => "/tmp/ruby.socket",
                                "min-procs" => 1,
                                "max-procs" => 1 )) )

server.document-root       = "#{document_root}"

server.port = #{server_port}

server.errorlog            = "#{error_log}"

server.error-handler-404 = "/#{dispatcher}"

index-file.names           = ( "index.html" )

accesslog.filename         = "#{access_log}"

# debug.log-request-handling = "enable"

server.pid-file            = "#{pid_file}"

dir-listing.encoding        = "utf-8"
server.dir-listing          = "disable"

server.username            = "www-data"
server.groupname           = "www-data"



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
