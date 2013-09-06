require 'markaby'

# Modify Markaby's method_missing function so we find our own widgets
#
class ::Markaby::Builder		# :nodoc:
  alias :old_method_missing :method_missing

  def method_missing(sym, *args, &block )	# :nodoc:
    class_name = sym.id2name  

    return old_method_missing(sym, *args, &block) if 
        (class_name[0].chr.upcase != class_name[0].chr) 
    
    if Object.const_defined?(class_name+'Widget') then
        c = Object::const_get(class_name+"Widget")
    else
        # try to find the widget in the action namespace
        return old_method_missing(sym, *args,&block) if $app.nil?
        
        am = $app.urlmap.action_module
        if am.const_defined?(class_name+'Widget') then
           c = am.const_get(class_name+'Widget')
        else
           return old_method_missing(sym, *args, &block)
        end
    end

#    $stderr.puts "Widget in markaby: Class: #{class_name}, \n\n assigns: #{@assigns.inspect} \n\n"

    widget = c.new({:args => args,
                    :assigns => @assigns },
                    &block)

 #   $stderr.puts "Widget:" + widget.inspect
    @builder <<  widget.to_s

#    $stderr.puts "Good"
  end
end

module Cuca

# == Generator
# A generator is a mixin to Cuca::Widget. It should provide functions that generate
# content.
# Visible within a generator function should be all instance variables, all instance
# methods and an easy accessor to widgets defined on the root namespace and 
# within the action namespace ($app.urlmap.action_namespace). For example the view and 
# markaby generators that come with cuca you can call a widget like:
#   Link(a,b,c..) { block}
# and it will initialize the LinkWidget.
module Generator

# == Markaby Generator
#
# Markaby Generator provides the mab and mabtext functions to generate content.
# 
# Usage example within a controller:
#
#  require 'cuca/generator/markaby'
#  class IndexController < ApplicationController
#   include Cuca::Generator::Markaby
#   def run
#     mab { Link('/to/somewhere') { b { "Click" }}}
#   end
#  end
#
# The above will make use of widget 'LinkWidget' (must be defined)
#
# For more information of Markaby pls see the markaby website.
#
# === Performance Warning
#
# Unfortunately Markaby is not famous to be fast. Using it on recuring widgets 
# can significantly slow down your application.
# 
#
module Markaby
   # use this to add markaby code to @content
  def mab(&block)
    @_content << ::Markaby::Builder.new(get_assigns, self, &block).to_s
  end
 
  # Use this to generate html code with a markaby block and have it as a string
  def mabtext(&block)
    ::Markaby::Builder.new(get_assigns, self, &block).to_s
  end

end

end # Module Generator
end # Module Cuca

