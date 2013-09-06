require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'
require 'cuca/urlmap'
require 'cuca/cgi_emu'


class TestApp < Test::Unit::TestCase

  def test_basic
    app = Cuca::App.new
    assert app.app_path
    assert app.public_path
    assert app.log_path
    assert app.logger.instance_of?(Logger)
    assert_equal $app.object_id, app.object_id
  end

  def test_configure
    Cuca::App.configure do |conf|
      conf.test_var = 'test'
    end
    assert_equal 'test', Cuca::App.config['test_var']
  end

  def test_support_files_loading
    app = Cuca::App.new
    um = Cuca::URLMap.new("#{$cuca_path}/app/", "/user/list.rb")
    app.load_support_files(um)
  end


 
end
