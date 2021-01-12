require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'
require 'cuca/urlmap'


class TestAWidget < Cuca::Widget
  def output(param1='one', param2='two')
     content << "#{param1}-#{param2}"
     @v1 = 'test1'
     @v2 = 'test2'
  end

  def get_ivar(var)
    instance_variable_get(var)
  end
end

class TestBWidget < TestAWidget
  def output(param1='one', param2='two')
     super(param1, param2)
     @_content = "(#{content})"
  end
end

class TestCWidget < Cuca::Widget
  def output(&block)
    @_content = block.call
  end
end


class TestBaseWidget < Cuca::Widget
  class << self
      def set_something(whatever)
         define_attr_method 'something', whatever
      end
    
      def append_something(whatever)
         s = run_attr_method('something') || []
         s << whatever
         define_attr_method 'something', s
      end
  end
end


class TestDWidget < TestBaseWidget
  set_something 'stuff'
end

class TestEWidget < TestBaseWidget
  append_something 'a'
  append_something 'b'
  append_something 'c'
end


class WidgetTest < Test::Unit::TestCase

 def setup
   @app = Cuca::App.new
 end

 def test_content
    w = Cuca::Widget.new
    w.content = 'test'
    assert_equal w.content, 'test'
    w.clear
    assert w.content == ''

    t = TestAWidget.new
    assert_equal t.to_s, 'one-two'
 end

 def test_hints
    w = Cuca::Widget.new
    w.hints['hint1'] = 'h1'
    w2 = Cuca::Widget.new
    assert_equal w2.hints['hint1'], 'h1'
    w2.hints['hint2'] = 'h2'
    assert_equal w.hints['hint2'], 'h2'

    Cuca::Widget::clear_hints
 
    assert_equal w.hints, {}
    assert_equal w2.hints, {}
 end

 def test_assigns
   w = Cuca::Widget.new(:assigns => { 'p1' => 'test1', 'p2' => 'test2' })

   assert w.get_assigns['p1'] == 'test1'

   w = TestAWidget.new(:assigns => { 'p1' => 'test1', 'p2' => 'test2' } )
   assert w.get_assigns['p1'] == 'test1'
   assert w.get_assigns['p2'] == 'test2'
 end

 def test_params
    t = TestAWidget.new(:args => ['x', 'z'])
    assert_equal 'x-z', t.to_s
    t = TestAWidget.new(:args => ['three'])
    assert_equal 'three-two', t.to_s
 end

 def test_subclass
    t = TestBWidget.new
    assert_equal '(one-two)', t.to_s
    t = TestBWidget.new(:args=> ['a', 'b'])
    assert_equal '(a-b)', t.to_s
    assert_equal 'test2', t.get_assigns['v2']
 end

 def test_widget_with_block
    w = TestCWidget.new { "BLOCK" }
    assert_equal "BLOCK", w.to_s

    w = TestCWidget.new { "BLOCK2" }
    assert_equal "BLOCK2", w.to_s
 end

 def test_attr_method
   assert_equal 'stuff', TestDWidget.run_attr_method('something')
   assert_equal 'stuff', TestDWidget.something

   a = TestEWidget.run_attr_method('something')
   assert a.instance_of?(Array)
   assert_equal 3, a.length
   assert a.include?('a') 
   assert a.include?('b')  
   assert a.include?('c')
 end


end
