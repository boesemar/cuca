require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'
require 'cuca/generator/markaby'

# Outputs parameters
class TestMabAWidget < Cuca::Widget
 include Cuca::Generator::Markaby

 def output(param1='one', param2='two')
    mab { b { param1 }; b { param2 }}
 end
end

# Outputs a markaby block
class TestMabBWidget < Cuca::Widget
  include Cuca::Generator::Markaby
  
  def output(&block)
    mab { b { text capture(&block) } }
  end
end

# Takes intance variable @i and output's it
class TestMabCWidget < Cuca::Widget
  include Cuca::Generator::Markaby

  def output()
   @i = 'test'
   mab { text @i }
  end
end

# takes instance variable from TestC and mab's it with 'i'
class TestMabDWidget < TestMabCWidget
  include Cuca::Generator::Markaby

  def output()
   super
   clear
   mab { i { @i }  }
  end
end

# should produce 'onetwothree' - check multicall 
class TestMabEWidget < TestMabCWidget
  include Cuca::Generator::Markaby

  def output()
   mab { 'one'  }
   mab { 'two'  }
   s = mabtext { 'three'  }
   content << s
  end
end

# uses instance methods as markaby reference, outputs '<b>TestMe</b>'
class TestMabFWidget < Cuca::Widget
   include Cuca::Generator::Markaby
  
   def testme
     'TestMe'
   end

   def output
     mab {  b { testme  } }
   end
end

# G embedds F
class TestMabGWidget < Cuca::Widget
 include Cuca::Generator::Markaby

  def output
    mab { i { TestMabF() }}
  end
end

class TestTextReturnsWidget < Cuca::Widget
  include Cuca::Generator::Markaby
  
  def world
    "world"
  end
  
  def hello
    "hello"
  end
  
  def output
    mab do 
      hello
      text " "
      world
    end
  end
end



class TestGeneratorMarkaby < Test::Unit::TestCase

 def test_basic
    t = TestMabAWidget.new
    assert_equal '<b>one</b><b>two</b>', t.to_s

    t = TestMabAWidget.new(:args => ['xxx', 'yyy'])
    assert_equal '<b>xxx</b><b>yyy</b>', t.to_s
 end

 def test_markabyblock
    t = TestMabBWidget.new { i { 'abc' }}
    assert_equal '<b><i>abc</i></b>', t.to_s

    t = TestMabBWidget.new { h1 { 'cde' }}
    assert_equal '<b><h1>cde</h1></b>', t.to_s
 end

 def test_ivar 
    t = TestMabCWidget.new  
    assert_equal 'test', t.to_s
   
    t2 = TestMabDWidget.new
    assert_equal '<i>test</i>', t2.to_s
 end

 def test_multicall
  assert_equal 'onetwothree', TestMabEWidget.new.to_s
 end

 def test_instancemethod
  assert_equal '<b>TestMe</b>', TestMabFWidget.new.to_s
 end

 def test_embedding_others
  assert_equal '<i><b>TestMe</b></i>', TestMabGWidget.new.to_s
 end

 def test_text_returns
   assert_equal 'hello world', TestTextReturnsWidget.new.to_s, "This only works with markaby < 0.8.0"
 end

end
