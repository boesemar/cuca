require 'cuca/stdlib/listwidget/list'
require 'active_record'

# List with Active Record model as data source
#
# DBList('dblistname', User, :columns => [ { :id => 'id', :query => 'user.id', :display=>'ID' },
#                                          { :id => 'name',  :display=>'Name', :searchable=>false } ])
#
# Options:
# :joins => ActiveRecord find :joins options.
#
# :columns: Columns possible flags:
#   :id         => [required] name. Likly this is the database column name
#   :query      => [optional] how to query the id (eg: users.name) . If false then treated as virtual column
#   :display    => [optional] title for the column
#   :searchable => [optional] true/false if this column can be searched (default autodetect)
#   :sortable = => [optional] true/false if columns can be sorted (default autodetect)
# DBLIST specific is only :query
class DBListWidget < BaseList
 @@like_expression = 'LIKE'

 def columns
#   $stderr.puts " Getting Columns: #{@columns}"
   @columns.delete_if { |c| !c[:display] }
 end
  
 # returns :query field by :id (only :id is defined in the QueryDef)
 def wc_query_field(field_id)
    @columns.each do |c|
          if c[:id] == field_id then 
             return c[:query]
          end
    end
    field_id
 end

 def quote(input)
   input.gsub(/\\/, '\&\&').gsub(/'/, "''") 
 end
 
 def where_clause(query_def)
   like = @@like_expression || 'LIKE'		# this allows to overwrite to ILIKE for example
   res = []
   query_def.filters.each_pair do |k,v|
       next if (v.nil? || v == '')
       if @model_class.columns_hash.include?(k) && @model_class.columns_hash[k].number? then
         res << "#{wc_query_field(k)} = #{v.to_i}"
       else
         res << "#{wc_query_field(k)} #{like} '%#{quote(v)}%'"
       end
   end
   wc =  "true"
   res.collect { |e| "(#{e})" }.each { |c| wc+=" AND #{c}" }
   wc+= " AND #{@extra_conditions}" if @extra_conditions != ''
#   $stderr.puts "WHERE clause is #{wc}"
   return wc
 end

 # transform a active record result to an [[]]- array
 def normalize_result(ar_res)
   res = []
   ar_res.each do |r|
      c = []
      columns.each do |col| 
         if r.attributes[col[:id]] then
            c << r.send(col[:id].intern)
         else
            c << ''
         end
      end
      res << c
   end
   res
 end
 

 def query(query_def)
   findstuff = {:conditions => where_clause(query_def) }
   findstuff[:order]  = "#{query_def.order_by} #{query_def.order}" unless (query_def.order_by.nil? || query_def.order_by == '')
   findstuff[:offset] = query_def.range.first
   findstuff[:limit]  = query_def.range.last-query_def.range.first+1
   findstuff[:joins]  = @joins || nil
   findstuff[:group]  = @group_by if @group_by.to_s != '' 
   sel = @query_columns.collect do |c| 
      ret = c.has_key?(:query) ? "#{c[:query]} as #{c[:id]}" : c[:id] 
      ret = nil if c[:query] == false
      ret
   end
   findstuff[:select] = sel.compact.join(',')
   @data = @model_class.find(:all, findstuff)
   @additional_data = @data.dup

   rowcount_findstuff = findstuff.dup
   rowcount_findstuff.delete(:limit)
   rowcount_findstuff.delete(:offset)
   rowcount_findstuff.delete(:order)
         
   @data = normalize_result(@data)   
   
   @total_rows= @model_class.count(rowcount_findstuff)
   if @total_rows.kind_of?(Hash) then   # if group_by is defined we'll get this
     @total_rows = @total_rows.size
   end
 end

 def setup
   super
 end


 # this will fix/add searchable/sortable and query flag
 def fixup_columns
    @columns.each_index do |idx| 

      if @columns[idx][:searchable].nil? then
          @columns[idx][:searchable] = @model_class.column_methods_hash[@columns[idx][:id].intern] ? true : false
      end
      @columns[idx][:query] = @columns[idx][:id] if @columns[idx][:query].nil?
      
      if @columns[idx][:sortable].nil? then
          @columns[idx][:sortable] = @columns[idx][:query] == false ? false : true
      end
      
    end
 end

 def output(list_name, model_class = nil, data_setup = {})
   @columns           = data_setup[:columns] || [] 
   @extra_conditions = data_setup[:conditons] || ""
   @joins	      = data_setup[:joins] || ""
   @group_by	     =  data_setup[:group_by] || ""
   @options	      ||= data_setup[:options] 		# can be used by 'setup'
   @model_class = model_class || nil
   setup
   fixup_columns
#   $stderr.puts @columns.inspect
#   @columns.freeze
   @extra_conditions.freeze
   @query_columns = @columns.dup
   @columns = @columns.delete_if { |c| !c[:display] } # don't display columns without a 'display'
   super(list_name)
 end
end
