require 'cuca/stdlib/listwidget/list'


# Displays data from memory
#
# Example:
#
# StaticDataList('list_name',
#           :columns => [ { :id => 'id',    :display=>'ID' },
#                         { :id => 'name',  :display=>'Name' } ],
#           :data    => [[ 1, 'Jack'],
#                        [ 2, 'Elvis'],
#                        [ 3, 'Alice']])
class StaticDataListWidget < BaseList
 def setup
   super
 end

 def output(list_name = "noname", data_setup = {})
   @sd_columns = data_setup[:columns] || []
   @sd_data    = data_setup[:data] || []
   @list_name = list_name
   setup
   @sd_columns.freeze
   @sd_data.freeze
   super(@list_name)
 end
 
 def columns
   return @sd_columns
 end

 def filter(data, column_name, value)
   cidx = col_idx_by_id(column_name)
   return data if cidx.nil?
   return data if value.strip.empty?

   new_data = []
   data.each_index do |didx|
     if data[didx][cidx].instance_of?(String) then
#         $stderr.puts "Filter: #{@data[didx][cidx]} on #{value}"
         new_data << data[didx] if data[didx][cidx].include?(value)
#         $stderr.puts @new_data.inspect
     end
   end
#   $stderr.puts "Filter done(#{column_name}, #{value}): #{new_data.inspect}"
   return new_data
 end

 def apply_filters(query_def)
   query_def.filters.each_pair do |k,v|
     @data = filter(@data, k,v)
   end
#   $stderr.puts "Done filtering: #{@data.inspect}"
 end



 def query(query_def)
   cidx = col_idx_by_id(query_def.order_by) || 0
   
   @data = @sd_data.sort { |a,b| a[cidx] <=> b[cidx] }
   @data = @data.reverse if query_def.order == 'DESC'
   apply_filters(query_def)
   @total_rows = @data.size
   @data = @data[query_def.range]
   
 end

 def col_idx_by_id(col)
   @sd_columns.each_index do |idx|
      if @sd_columns[idx][:id] == col then
        return idx
      end 
   end
   return nil
 end

end

