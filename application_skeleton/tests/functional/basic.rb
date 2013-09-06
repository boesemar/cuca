require 'rubygems'

$cuca_path = File.dirname(__FILE__)+"/../../"

require 'cuca'
require 'cuca/test/helpers'

class TC_TestWidget  < Test::Unit::TestCase
 
 include Cuca::Test::Helpers

 def test_index
#   x = get('/index', { :test => 'me' })
#   puts x.inspect
   
#   x = get('/test')
#   puts x.inspect
   
   x = post('/test')
   puts x.inspect
   puts
   puts
   x = post('/test', { :post_var => 'post_value' } )
   puts x.inspect
   puts
   puts
   

 end

end

