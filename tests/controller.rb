require 'test/unit'

$: << File.expand_path(File.dirname(__FILE__) + '/../lib')

$cuca_path = File.expand_path("#{File.dirname(__FILE__)}/test_app")
require 'cuca'
require 'cuca/urlmap'

class TestAController < Cuca::Controller
  def get
    @_content = 'GET'
  end
  def post
    @_content = 'POST'
  end
end
class TestBController < Cuca::Controller
  def run
    @_content = 'RUN'
  end
end

# test layout - will just put brackets around content
class TestLayout < Cuca::Layout
  def output
    @_content = "(#{@content_for_layout})"
  end
end

# A Controller that defines a layout
class LayoutController < Cuca::Controller
  layout 'test'

  def run
     content << "LAYOUT"
  end
end

# should produce: "(zero-one-two-three-FILTER-aone-atwo)"
class FilterController < Cuca::Controller
 priority_before_filter 'filter_pri'
 before_filter 'filter_three', 30
 before_filter 'filter_one', 1
 before_filter 'filter_two', 10

 priority_after_filter 'afilter_pri'
 after_filter 'afilter_one', 10
 after_filter 'afilter_two', 20

 def run
    content << "(#{@filter.join('-')}-FILTER"
 end

 def filter_pri
   @filter = ['zero']
 end
 
 def afilter_pri
   @_content << ')'
 end
 

 def filter_one
   @filter << 'one'
 end

 def filter_two
  @filter << 'two'
 end

 def filter_three
  @filter << 'three'
 end

 def afilter_one
   @_content << '-aone'
 end

 def afilter_two
   @_content << '-atwo'
 end
end


# this defines a filter that doesn't exist, raises ApplicationException
class BadFilterController < Cuca::Controller
 before_filter 'notexist'
end

class ReturnErrorController < Cuca::Controller
  def run
    http_status 'SERVER_ERROR'
  end
end

class ReturnOtherMimeController < Cuca::Controller
  def run
    mime_type 'text/plain'
    @_content = 'test text'
  end
end



class ChainAController < Cuca::Controller
  before_filter 'a', 1  
  def a 
    @out ||= ''
    @out << 'a'
  end
end


class ChainBController < ChainAController
  before_filter 'b',100
  def b
    @out ||= ''
    @out << 'b'
  end
end

class ChainCController < ChainBController
  before_filter 'c',2
  attr :out
  def c
    @out ||= ''
    @out << 'c'
  end
end


class StopFilterController < Cuca::Controller
  before_filter 'stop_it'
  
  def stop_it
     stop :cancel_execution => true
  end
  
  def run
      raise "Never got here"
  end
end
        
        

class ControllerTests < Test::Unit::TestCase

  def test_basic
    c = Cuca::Controller.new
    assert c.to_s == ''

    a = TestAController.new
    a._do('get')
    assert_equal 'GET', a.to_s
    a = TestAController.new
    a._do('post')
    assert_equal 'POST', a.to_s

    b = TestBController.new
    b._do('run')
    assert_equal 'RUN', b.to_s
    assert_equal "OK", b.http_status
    assert_equal "text/html", b.mime_type
  end

  def test_layout
     l = LayoutController.new
     l._do('run')
     assert_equal '(LAYOUT)', l.to_s
     assert_equal "OK", l.http_status
     assert_equal "text/html", l.mime_type
  end


  def test_filters
    f = FilterController.new
    f.run_before_filters
    f._do('run')
    f.run_after_filters
    assert_equal "(zero-one-two-three-FILTER-aone-atwo)", f.to_s
    assert_equal "OK", f.http_status
  end

  def test_badfilter
   f = BadFilterController.new
   assert_raise Cuca::ApplicationException do
     f.run_before_filters
   end
   assert_equal "SERVER_ERROR", f.http_status
  end

  def test_http_status
    c = ReturnErrorController.new
    c._do('run')
    assert_equal c.http_status, 'SERVER_ERROR'
  end

  def test_mime_type
    c = ReturnOtherMimeController.new
    c._do('run')
    assert_equal c.mime_type, 'text/plain'
  end


  def test_chain_filters
    c = ChainCController.new
    c.run_before_filters
    assert_equal 'acb', c.out
  end

  def test_stop_in_filter
    c = StopFilterController.new
    c.run_before_filters
    c._do('run') 
  end
end
