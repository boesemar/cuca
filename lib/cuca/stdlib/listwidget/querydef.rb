
# QueryDef is a settings class that hold the settings for the query for listwidget
#
# FIXME: Change name or put into namespace
class QueryDef
 ATTRIBS = ['order_by', 'order','range', 'filters']
 ATTRIBS_ENCODE = 
    { 
      'range' => 
      Proc.new do |e| 
        "#{e.first}-#{e.last}" 
      end,
     'filters' => 
      Proc.new do |e|  
        s = ''; 
        e.each_pair { |k,v| s << "#{k}:#{v};" }; 
        s 
      end,
      'order' => 
      Proc.new do |e|
        ['ASC', 'DESC'].include?(e) ? e : 'ASC'
      end
    }
 ATTRIBS_DECODE = 
    {
       'range' => 
       Proc.new do |e| 
          Range.new(e.split('-')[0].to_i,e.split('-')[1].to_i) 
       end,
       'filters' => 
       Proc.new do |e| 
          h = {}
          e.split(';').each do |p|
               vals = p.split(':')
               h[vals[0]] = vals[1] if (vals.size == 2)
          end
       h
       end,
       'order' => 
        Proc.new do |e|
          ['ASC', 'DESC'].include?(e) ? e : 'ASC'
        end
    }
 ATTRIBS_DEFAULTS = { 'range' => 0..9,
                      'order_by' => '',
                      'order' => 'ASC',
                      'filters' => {} }

 # take from CGI class
 def escape(string)
     string.gsub(/([^ a-zA-Z0-9_.-]+)/n) do
      '%' + $1.unpack('H2' * $1.size).join('%').upcase
    end.tr(' ', '+')
 end
 def unescape(string)
    string.tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n) do
      [$1.delete('%')].pack('H*')
    end
 end

 def method_missing(m, *params)
   met = m.id2name

   #getter 
   if (ATTRIBS.include?(met)) then
     return @data[met] || @attribs_defaults[met].dup
   end
 
   #setter
   raise NoMethodError, met if met[met.size-1].chr != '='
   raise NoMethodError, met if params.size != 1
   met = met[0..met.size-2]		# cut '='
   if ATTRIBS.include?(met) then
     @data[met] = params[0]
   else
     raise NoMethodError
   end
 end

 # value enc/dec
 def ev_enc(name)

   if ATTRIBS_ENCODE.has_key?(name) then
     ATTRIBS_ENCODE[name].call(@data[name])
   else
     @data[name]
   end
 end

 def ev_dec(name, value)
   if ATTRIBS_DECODE.has_key?(name) then
     $stderr.puts "ev_dec #{name} #{value}"
     begin
        return ATTRIBS_DECODE[name].call(value)
     rescue
#        $stderr.puts "Decoding failed: #{name} - #{value}: #{$!}"
        return @attribs_defaults[name].dup
     end
   else
     return value
   end
 end

 # attribute-name enc/dec
 def at_enc(name)
   "#{@list_name}_#{name}"
 end

 def at_dec(name)
    name[@list_name.size..@name.size-1]
 end

 # returns an hash with the values and escaped names and attributes
 # attr and newval with swap a value for this return without changing the actual data
 def to_h(attr1=nil, newval1=nil, attr2=nil, newval2=nil)
   if attr1 then
      @backup = @data.dup
      @data[attr1] = newval1
      @data[attr2] = newval2 unless attr2.nil?
   end

   u = {}
   ATTRIBS.each do |a|
#     $stderr.puts "Encoding: #{a} - #{@data[a]}"
      u[at_enc(a)] = escape(ev_enc(a) || '')
   end
   
   if attr1 then @data = @backup end

   return u
 end

 def from_params(params)
#   $stderr.puts "CGI PARAMS: #{$cgi.params.inspect}"
#   $stderr.puts "*** From Params\n #{params.inspect}\n"
#   $stderr.puts "*** DEFAULT ATTR: #{ATTRIBS_DEFAULTS.inspect}\n"
   ATTRIBS.each do |a|
#     $stderr.puts "Checking: #{at_enc(a)} = #{params[at_enc(a)][0]}"
     v = params[at_enc(a)]
     if v then 
       @data[a] = ev_dec(a,v)
     else
       @data[a] = @attribs_defaults[a].dup
     end
#     $stderr.puts "\n*** ENDFROM_PARAMS: #{@data.inspect}"
   end

   # checking on filters that come by post
#   $stderr.puts "PARAMS: #{params.inspect}"
   params.each_pair do |p,v|
      if p.include?("#{@list_name}_filter_") then
         @data['filters'] ||= {}
         fname = p.scan(/\_filter\_(.*)/)[0][0]
         fdata = v
         @data['filters'][fname] = fdata
         $stderr.puts "Filter update: #{@data['filters'].inspect}"
      end
   end

  
#   $stderr.puts @data.to_yaml
   return self
 end

 def initialize(list_name, default_attribs = {})
  @attribs_defaults = ATTRIBS_DEFAULTS.merge(default_attribs)
  @list_name = list_name 
  @data = {}
 end
end


