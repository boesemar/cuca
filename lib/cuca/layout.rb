module Cuca

# = Layout
# A Layout just behaves as a normal widget plus it will give you the @content_for_layout
# instance variable with the content generated from the controller.
# 
# == Naming
# Name it FilenameLayout (ending always with Layout, for example: 'StandardLayout' or 'FancyLayout').
# When you specify your layout in the controller simply do a 
#  layout 'standard'
#
# == Examples
# Layout Class:
#
#  class PlainLayout < Cuca::Layout
#
#   def output
#     content << <<-EOI
#       <html>
#         <head><title>#{@page_title}</title></head>
#       <body>
#        #{@content_for_layout}
#       <hr>
#       <small>Rendered using the Plain Layout - at #{Time.new.to_s}</small>
#       </body>
#       </html>
#       EOI
#   end
#  end
#
#
# Example Controller that would work with the above layout:
#
#  class IndexController < Cuca::Controller
#   layout 'plain'
#
#   def run
#      @page_title = "Main Page"
#      content << "<h3>Welcome to my Webpage</h3>
#   end
#  end
#
# Note: The above example doesn't make use of a generator - which would simplify the development of 
# larger layouts and controllers.
class Layout < Widget

 # the controller will create the layout. The controller will also set the content_for_layout
 # assign besides other assigns from the controller.
 def initialize(params = {}, &block)
   raise ArgumentError.new("Layout requires :assigns for layout content") if params[:assigns].nil?
   params[:assigns].each_pair do |k,v|
     instance_variable_set("@#{k.to_s}", v)
   end
   super
 end
 
 def to_s
    output
    return content.to_s
 end
end

end
