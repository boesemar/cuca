require 'rubygems'

$cuca_path = File.dirname(__FILE__)+"/../../"

require 'cuca'
require 'cuca/test/helpers'

class TC_TestWidget  < Test::Unit::TestCase
 
 include Cuca::Test::Helpers

 def setup
   init()
 end

 def test_linkwidget
   link = widget(LinkWidget, '/link/to') { "Something" }
   assert link.to_s.include?('<a') && link.to_s.include?('Something')
 end
 

end
