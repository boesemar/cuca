require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'cuca'
require 'cuca/urlmap'


Cuca::App.configure do |c|
 c.magic_prefix = '__'
end

#
# test/app
#        /user
#            list.rb
#            /__username/
#                       index.rb
#        /agent/
#            index.rb
#            list.rb


class URLMapTest < Test::Unit::TestCase
  def path
    File.expand_path("#{File.dirname(__FILE__)}/test_app/app")
#    File.expand_path("#{__FILE__}/test_app/")
  end
  
  def test_user_list
     map = ::Cuca::URLMap.new(path, '/user/list')
     assert map.script.include?('/user/list.rb')
     assert !map.subcall
     assert_equal map.action, 'list'    
     assert map.script.include?(map.action_path)		# action path must be part of script
     assert map.script.include?(map.action_path_full)      
  end

  def test_default_action
     map = ::Cuca::URLMap.new(path, '/agent/')
     assert_equal map.action, 'index' 

     assert_raise Cuca::RoutingError do
         ::Cuca::URLMap.new(path, '/')		# no default index
     end
  end
  
  def test_user_list_subcall
     map = ::Cuca::URLMap.new(path, '/user/-list-test')
     assert map.subcall
     assert_equal map.action, 'list'
     assert map.script.include?('/user/list.rb')
  end
  
  def test_invalid_path
    assert_raise Cuca::RoutingError do
       ::Cuca::URLMap.new(path, '/some/invalid/path')
    end
  end
  
  def test_invalid_subcall
    assert_raise Cuca::RoutingError do
      map = ::Cuca::URLMap.new(path, '/user/-list')      
    end
  end
  
  def test_magic_path
     map = ::Cuca::URLMap.new(path, '/user/martin/')
     assert map.assigns.has_key?('username')
     assert_equal map.assigns['username'], 'martin' 
  end

  def test_mount
    Cuca::App.configure do |c|
      c.mount = { '/user/__username/agent/' => "#{path}/agent/" }	
    end
    
    map = ::Cuca::URLMap.new(path, '/user/martin/agent/index')
    assert map.script.include?('/agent/index.rb')
      
    Cuca::App.configure do |c|
      c.mount = {}
    end
  end  

  def test_module
    map  = ::Cuca::URLMap.new(path, '/agent/index')
    map2 = ::Cuca::URLMap.new(path, '/agent/list')
    assert_equal map.action_module.object_id, map2.action_module.object_id
    
    map2 = ::Cuca::URLMap.new(path, '/user/list')
    
    assert !(map.action_module.object_id == map2.action_module.object_id)
  end
  
  def test_path_tree
     map  = ::Cuca::URLMap.new(path, '/agent/index')
     assert_equal 2,  map.path_tree.size
     map  = ::Cuca::URLMap.new(path, '/test')
     assert_equal 1,  map.path_tree.size               
  end


end
