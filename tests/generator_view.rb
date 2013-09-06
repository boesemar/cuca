require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'
require 'cuca/generator/view'

# Cuca::App.configure do |conf|
#  conf.view_directory="#{$cuca_path}/app/_views"
# end

class TestViewAWidget < Cuca::Widget
  include Cuca::Generator::View

  def output
    @test = 'TEST'
    view('test_template.rhtml')
  end
end

# test viewtext
class TestViewBWidget < Cuca::Widget
  include Cuca::Generator::View

  def output
     @test = 'TEST'
     @_content = viewtext('test_template.rhtml')
  end
end


class TestViewCWidget < Cuca::Widget
  include Cuca::Generator::View
  
  def output 
     @test = 'TEST'
     view_p(templ)
  end

  def templ
    return <<-'EOT'
        <b><%= @test %></b>
EOT
  end
end

class TestViewDWidget < Cuca::Widget
  include Cuca::Generator::View
  
  def output 
     @test = 'TEST'
     @_content = viewtext_p(templ)
  end

  def templ
    return <<-'EOT'
        <b><%= @test %></b>
EOT
  end
end


class TestViewGenerator < Test::Unit::TestCase

 def test_external_template
    assert_equal '<p>TEST</p>', TestViewAWidget.new.to_s
    assert_equal '<p>TEST</p>', TestViewBWidget.new.to_s
 end

 def test_internal_template
    assert_equal '<b>TEST</b>', TestViewCWidget.new.to_s.strip
    assert_equal '<b>TEST</b>', TestViewDWidget.new.to_s.strip
 end

end
