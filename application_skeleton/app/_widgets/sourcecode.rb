# this demo widget will display the sourcecode of the current 
# action (the file that contains the controller)
#
# This is a demo widget - part of the cuca application skeleton
# You can delete it unless you have any use for it in your applicaiton


require 'cuca/generator/markaby'
class SourceCodeWidget < Cuca::Widget
 include Cuca::Generator::Markaby
 
 def output
   @script = app.urlmap.script
   mab do 
    div(:style=>'background-color:#FAFAFF; border: 1px dashed blue;') do
       b { "Sourcecode of: " }; text "#{@script}"
       pre { escapeHTML(File.open(@script).read)  }	# escapeHTML is defined in Cuca::Widget
    end
   end
 end
end
