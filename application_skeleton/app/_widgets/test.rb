# this demo widget will simply display all parameters and blocks
# it got called with.
#
# This is a demo widget - part of the cuca application skeleton
# You can delete it unless you have any use for it in your applica
require 'cuca/generator/markaby'

class TestWidget < Cuca::Widget
  
  include Cuca::Generator::Markaby
  
  def output(*args, &block)
    @a = @_assigns
    @params = params
    mab { text "Test-Widget (debug): "; br ;
          text "ARGS: " + args.inspect ; br ;
          text "ASSIGNS:" + @a.inspect; br;
	  text "PARAMS: " + @params.inspect ; br;
          text "BLOCK: " + (block_given? ? "YES" : "NO") ; br }
    mab { text "Block returns:" ;br }
    mab(&block)
  end
  
end
