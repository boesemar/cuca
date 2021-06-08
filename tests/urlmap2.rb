require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

require 'cuca/urlmap2'

class URLMapTest < Test::Unit::TestCase
    def path_app1
        File.expand_path("#{File.dirname(__FILE__)}/test_app/app")
    end
    def path_app2
        File.expand_path("#{File.dirname(__FILE__)}/test_app2/app")
    end

    def test_one
        u = Cuca::URLMap2.new do |config|
            config.base_path = [path_app1]
        end
        puts "=============== app1 tree is ===================="
        puts u.tree.to_s
        puts "================================================="
        sr = u.scan('/test')        
        assert_equal 'test', sr.action
        assert_equal '/test', sr.url
        sr = u.scan('/user/martin/index')
        assert_equal 'martin', sr.assigns['username']
        assert sr.script.include?('/app/user/__username/index.rb')
   
        sr = u.scan('/test')        # app2 overrides /test not not here!
        assert sr.script.include?('/test_app/')
    end

    def test_override
        u = Cuca::URLMap2.new do |config|
            config.base_path = [path_app1, path_app2]
        end
        puts "=============== app1+app2 tree is ===================="
        puts u.tree.to_s
        puts "================================================="
        sr = u.scan('/test')        # app2 overrides /test
        assert sr.script.include?('/test_app2/')
    end
end