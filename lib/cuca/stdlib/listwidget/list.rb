
require 'cuca/generator/view'
require 'cuca/generator/markaby'
require 'cuca/stdlib/listwidget/querydef'
require 'cuca/stdlib/slink'

# this is the parent class for dblist and staticdatalist
class BaseList < Cuca::Widget
 include Cuca::Generator::View
 include Cuca::Generator::Markaby
  
 attr_reader :data
 attr_reader :rewrite_hooks


 # Add a proc to rewrite content of a field
 # proc must take two arguments, |row_content, field_content|
 def add_rewrite_hook(field_id, &proc)
    @rewrite_hooks||= {}
    @rewrite_hooks[field_id] = proc
 end

 def row2hash(row)
    res = {}
    c = columns
    c.each_index do |idx|
      res[c[idx][:id]] = row[idx]
    end
    res
 end

 def rewrite_field(row, field_id, content, additional_content = nil)
#   $stderr.puts "REwrite field(#{row.inspect}, #{field_id.inspect}, #{content.inspect} - hooks #{@rewrite_hooks.inspect}"
   return content unless @rewrite_hooks[field_id]
   if @rewrite_hooks[field_id].arity == 2 then
     return @rewrite_hooks[field_id].call(row2hash(row), content)
   else
     return @rewrite_hooks[field_id].call(row2hash(row), content, additional_content)
   end
 end


 # Use to initialize 
 #
 def setup
 end

 # OVERWRITE
 # return a list of columns
 def columns
   return [{:id=>"one", :display =>'One', :searchable=>false}, {:id=>'two', :display => 'three'}]
 end

 #OVERWRITE:
 # fetch data and write:
 # @data       = [['a','b', 12], ...]
 # @total_rows = 123
 def query(query_definition)
   return
 end

 def load_query_definition
   qd = QueryDef.new(@list_name, (@query_defaults || {}))
   qd.from_params(params)
   if request_method == 'POST' then
       qd.range = nil 		# reset pagination if someone submitted a filter
   end
   qd
 end

 # check query_def was makes sense ... raise error if manipulated!
 def check_query_def
    # check if filters match possible column names
    cn = columns.collect { |c| c[:id] }
    @query_def.filters.each_pair do |f,v|
       raise Cuca::ApplicationException.new("Unknown column in filters: #{f}") unless cn.include?(f)
    end
    
    return if @query_def.order_by == ''
    # check if order_by is a valid column
    raise Cuca::ApplicationException.new("Unknown sort order: #{@query_def.order_by}") \
                    unless cn.include?(@query_def.order_by)
 end
 
 def output(list_name)
   @list_name = list_name

   @columns = columns
   @query_def = load_query_definition
   check_query_def
#   $stderr.puts "Query: Range #{@query_def.range.inspect} Filters: #{@query_def.filters.inspect} Order: #{@query_def.order.inspect} By: #{@query_def.order_by.inspect}"
   query(@query_def)
   @paginate = paginate_links()
   @params = params
   @rewrite_hooks ||= {}

   callback_method = "#{@list_name}_data"

   if !controller.nil? && controller.methods.include?(callback_method) 
      controller.send(callback_method, @data, @total_rows)
   end

   view_p(erb_template)
 end # def

 def list_size_links
   r = []
   [25,50,75,100,-1].each do |n_rows|
      next if n_rows > @total_rows
      next if n_rows == -1 && (@total_rows > 2000)
      t = n_rows > 0 ? n_rows.to_s : 'all'
      start = @query_def.range.first < n_rows ? 0 : @query_def.range.first
      rows = n_rows > 0 ? n_rows : @total_rows * 2
      if (@query_def.range.last - @query_def.range.first) == rows then
        r << "<b>#{t}</b>"
      else
        r << "#{SLinkWidget.new(:args => ['',t,@query_def.to_h('range', (start..start+rows))] )}" 
      end
   end
   r.join(' ')
 end

 private
 def paginate_links()
   @rows_per_page = (@query_def.range.last - @query_def.range.first) + 1
   @total_pages = (@total_rows / @rows_per_page).to_i
   @total_pages = @total_pages + 1 unless ((@total_rows % @rows_per_page) == 0)

   pl = ''
   (0..(@total_pages-1)).map do |e| 
            { :idx =>e, 
              :range=>((e*@rows_per_page)..(e*@rows_per_page+@rows_per_page-1)) }
    end.map do |e|
       rt = @rows_per_page * 2
       r = false
       r = true if e[:idx] == 0
       r = true if e[:idx] == (@total_pages - 1)
       r = true if ((e[:range].min - rt)..(e[:range].max + rt)).include?(@query_def.range.first+1)
       e[:display] = r
       e[:hit] = e[:range].include?(@query_def.range.first+1)
       e
    end.each do |p|
        if p[:display] && !p[:hit]then
          pl << "#{SLinkWidget.new(:args=>['',(p[:idx]+1).to_s,@query_def.to_h('range', p[:range])]).to_s} "
        elsif p[:hit] then
          pl << "<b>#{p[:idx]+1}</b> " 
        else
          pl << '... ' unless pl[-4..-1] == '... '
        end
    end
   
  return pl
end
 
 private
 def erb_template
  <<'ENDTEMPLATE'
 <div class='list'>
 Pages: [ <%= @paginate %> ]
 Rows: [<%= list_size_links %> ]
 <table width>
    <tr>

      <% @columns.each do |c| %>
        <td class='hl'>
           <%
               # this will swap the sort order if the same columns is clicked 
               if @query_def.order_by == c[:id] then
                  order = @query_def.order == 'ASC' ? 'DESC' : 'ASC'
                  display = "#{c[:display]} (#{@query_def.order})"
               else
                  order = 'ASC'
                  display = c[:display]
               end
           %>
           <%= (c[:sortable] == false) ?  display : SLink('',display,
                                       @query_def.to_h('order_by', c[:id], 
                                                       'order', order))
                   %>
       </td>
      <% end %>
      <td></td>

      <form name="<%=@list_name%>_form" method="POST">
      <tr>
        <% @columns.each do |c|
           ftag = "#{@list_name}_filter_#{c[:id]}" %>
            <td>
              <% if c[:searchable] != false then %>
                <input style='float:left;' type="text" name="<%=ftag%>" value="<%=@query_def.filters[c[:id]]%>" >
              <% end %>
            </td>
        <% end %>     

        <td><input style='float:right;' type="submit" value="filter"></td>

      </tr>
      </form>

      <% @additional_data ||= [] %>
      <% @data.each_index do |row_idx| %>
      <tr>
           <% @data[row_idx].each_index do |field_idx| %>
              <% add_data   = @additional_data[row_idx] || nil 
                 cell_align = @columns[field_idx][:align]
                 align_line = cell_align ? " align='#{cell_align}'" : ''
              %>
              <td<%=align_line%>> <%= rewrite_field(@data[row_idx], @columns[field_idx][:id], @data[row_idx][field_idx], add_data) %> </td>
           <% end %>
      </tr>
      <% end %>
  </table>
</div>
ENDTEMPLATE
 end
 
end

