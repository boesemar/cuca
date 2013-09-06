
$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'test/unit'
require 'cuca/mimetypes'


class TestMimeTypes < Test::Unit::TestCase

  def test_mimetypes
     mt = Cuca::MimeTypes.new
     # just check for frequently used extensions
     assert_equal 'video/x-msvideo', mt['avi']
     assert_equal 'text/javascript', mt['js']
     assert_equal 'text/html', mt['html']
     assert_equal 'audio/mpeg', mt['mp3']
  end

  
end
