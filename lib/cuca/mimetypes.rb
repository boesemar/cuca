module Cuca

#
# MimeTypes is a self-writing hash.
# Will take the data of the mime.types file
# key is the file extension.
#
# MimeTypes.new['avi'] = > video/x-msvideo
#class MimeTypes < Hash
#
# def initialize(fn = '/etc/mime.types')
#
#    f = File.new(fn, 'r') or throw StandardError("Can't open #{fn}")
#    while (line = f.readline) do
#      line = line.chomp
#      next if line.length == 0
#      next if line[0] == '#'[0]
#      ls = line.scan(/[a-zA-Z\-\/0-9]+/)
#      next if line.size == 0
#      ls[1..-1].each { |e| self[e] = ls[0] }
#    end
#    f.close
#    
#    rescue EOFError
#       f.close
# end
# end

class MimeTypes < Hash # :nodoc:
 def initialize
 super
 {"rpm" => "application/x-rpm",
  "pdf" => "application/pdf",
  "sig" => "application/pgp-signature",
  "spl" => "application/futuresplash",
  "class" => "application/octet-stream",
  "ps" => "application/postscript",
  "torrent" => "application/x-bittorrent", 
  "dvi" => "application/x-dvi", 
  "gz" => "application/x-gzip",
  "pac" => "application/x-ns-proxy-autoconfig",
  "swf" => "application/x-shockwave-flash",
  "tar.gz" => "application/x-tgz",
  "tgz" => "application/x-tgz",
  "tar" => "application/x-tar",
  "zip" => "application/zip",
  "mp3" => "audio/mpeg",
  "m3u" => "audio/x-mpegurl",
  "wma" => "audio/x-ms-wma", 
  "wax" => "audio/x-ms-wax", 
  "ogg" => "audio/x-wav",
  "wav" => "audio/x-wav",
  "gif" => "image/gif",
  "jpg" => "image/jpeg",
  "jpeg" => "image/jpeg",
  "png" => "image/png",
  "xbm" => "image/x-xbitmap",
  "xpm" => "image/x-xpixmap",
  "xwd" => "image/x-xwindowdump",
  "css" => "text/css",
  "html" => "text/html",
  "htm" => "text/html",
  "js" => "text/javascript",
  "asc" => "text/plain",
  "c" => "text/plain",
  "conf" => "text/plain",
  "text" => "text/plain",
  "txt" => "text/plain",
  "dtd" => "text/xml",
  "xml" => "text/xml",
  "mpeg" => "video/mpeg", 
  "mpg" => "video/mpeg",
  "mov" => "video/quicktime",
  "qt" => "video/quicktime",
  "avi" => "video/x-msvideo",
  "asf" => "video/x-ms-asf",
  "asx" => "video/x-ms-asf",
  "wmv" => "video/x-ms-wmv",
  "bz2" => "application/x-bzip",
  "tbz" => "application/x-bzip-compressed-tar",
  "tar.bz2" => "application/x-bzip-compressed-tar"}.each_pair { |k,v| self[k] = v }
 end 
end


end

# puts Cuca::MimeTypes.new['avi']

