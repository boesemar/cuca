
# == ARViewWidget - Display an ActiveRecord record.
#
# This is a small widget to quick&dirty display the content
# of a record.
#
# = Example
# 
#  mab { ARView(User.find(:id=>123)) }
#
class ARViewWidget < Cuca::Widget

 def output(model)
  @model = model

   r = "<table>"
   @model.class.columns.each do |col|
     r << "<tr><td>#{col.name}</td><td>#{@model.send(col.name.intern)}</td></tr>"
   end
   r << "</table>"
   @_content = r
 end

end
