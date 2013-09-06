# mixin this module to build form elements

module Cuca
module FormElements

 private 
 def a2p(attribs)
   a = attribs.dup
   a.delete(:default_value) # reserved attribute
   a.inject([]) { |m,e| m << ((e[1].to_s != '') ? "#{e[0].to_s}='#{e[1].to_s}'" : e[0].to_s) }.join(' ')
 end
 
 private
 def twodig(n)
   n.to_s.length == 1 ? "0"+n.to_s : n.to_s
 end
 
 # this allows to pass a :default_value to the set of attribs 
 private 
 def get_value(name, attribs)
    v[name] || (attribs[:default_value] || '')
 end
 
 def fe_text(name, attribs = {})
    "<input type='text' name='#{name}' value='#{get_value(name, attribs)}' #{a2p(attribs)}>\n"
 end

 def fe_hidden(name, attribs = {})
   "<input type='hidden' name='#{name}' value='#{get_value(name, attribs)}' #{a2p(attribs)}>\n"
 end

 def fe_int(name, attribs = {})
    fe_text(name, attribs)
 end

 def fe_textarea(name, attribs = {})
   a = { :rows => 5, :cols => 50 }.merge(attribs)
   "<textarea name='#{name}' #{a2p(a)}>#{get_value(name, attribs)}</textarea>\n"
 end
 
 # build a form start tag
 def fe_formstart(attribs = {})
   form_name = attribs[:form_name] || @form_name
   a = {:name=>form_name, :method=>'post', :action=>@post_to }.merge(attribs)
   "<form #{a2p(a)}>\n"
 end

 # fe password doesn't show passwords content but default (unless :showvalue defined in attribs)
 def fe_password(name, attribs = {})
    v = attribs[:showvalue] ? get_value(name, attribs) : ''
    attribs.delete(:showvalue)
    "<input type='password' name='#{name}' value='#{v}' #{a2p(attribs)}>\n"
 end

 # :default_value is 'on' or 'off' for checkboxes
 def fe_checkbox(name, attribs = {})
    checker_name = "#{name}_checker"
    newval  = !!(request_parameters[name] || query_parameters[name])
    posted  = (request_parameters[checker_name] || query_parameters[checker_name])
    
    # checkbox html element isn't sent to cgi if not selected
    # so cuca's page variables won't work - this fixes it for most cases.
    if (session.page && (posted && !newval)) then
      session.page[name] = 'off' 
    end
    
    checked = v[name] && (v[name].to_s != 'off')
    checked = attribs[:default_value] == 'on' if (!posted and !v[name]) 
    
    checkedval = checked ? ' CHECKED' : ''
     "<input type='checkbox' name='#{name}' #{a2p(attribs)}#{checkedval}>"+
     "<input type='hidden' name='#{checker_name}' value='1'>\n"		# Needed to detect if element was submitted
 end
         

 
 # this is to build a select box, example:
 # fe_select('gender', [['f', 'female'],['m','Male']]) or
 # ...with options parameters...:
 # fe_select('gender', [['f', 'female', { :id => 'f'} ],['m','Male', {:id=>'m'}]])
 # ...simple...:
 # fe_select('gender', ['f','m'])
 def fe_select(name, options, attribs = {})
   r = "<select name='#{name}' #{a2p(attribs)}>\n"
   options.each do |o|
     ov = o.instance_of?(Array) ? o[0] : o
     params = o[2].inject('') { |m,(k,v)| m << " #{k}='#{v}'" } rescue ''
     sel = ''
     sel = ' selected' if get_value(name, attribs).to_s == ov.to_s     
     if o.instance_of?(Array) then
       r+="<option value='#{o[0]}'#{sel}#{params}>#{o[1]}</option>\n"
     else
      r+="<option value='#{o}'#{sel}#{params}>#{o}</option>\n"
     end
   end
   r+="</select>\n" 
end

  def fe_bool(name,attribs = {})
    r = ''
    attribs = attribs.dup
    truename = attribs[:true] || 'true'   
    falsename = attribs[:false] || 'false'
    trueval = attribs.has_key?(:trueval) ? attribs[:trueval] : 't'
    falseval = attribs.has_key?(:falseval) ? attribs[:falseval] : 'f'
    $stderr.puts "#{name}: #{v[name].inspect} #{trueval.inspect} #{falseval.inspect}"
    attribs.delete(:true)
    attribs.delete(:false)
    attribs.delete(:trueval)
    attribs.delete(:falseval)

    
    r << "\n<select name='#{name}' #{a2p(attribs)}>\n"
    r << "<option #{"selected" if get_value(name, attribs) == trueval} value='#{trueval}'>#{truename}</option>\n"
    r << "<option #{"selected" if get_value(name, attribs) == falseval} value='#{falseval}'>#{falsename}</option>\n"
    r << "</select>\n"
 end

 
 def fe_submit(attribs = {})
   a = { :value => 'Submit', :name=>@submit_name }.merge(attribs)
   "<input type='submit' #{a2p(a)}>\n"
 end
 
 
 def fe_formend
   "</form>\n"
 end
 
 
 def fe_datetime(name, attribs = {})
   require 'date'
   begin
     val = v[name].instance_of?(Time) ? v[name] : DateTime.parse(v[name] || 'now')
   rescue ArgumentError
     val = DateTime.now
   end
   value = "#{val.year}/#{twodig(val.month)}/#{twodig(val.day)} #{val.hour}:#{val.min}"
   "<input type='text' name='#{name}' value='#{value}' #{a2p(attribs)}>\n"
 end
 
 def fe_date(name, attribs = {})
   require 'date'
   if v[name].instance_of?(Date) then
      value = "#{v[name].year}/#{twodig(v[name].month)}/#{twodig(v[name].day)}"
   end
   if v[name].nil? || (v[name].instance_of?(String) && v[name].empty?) then
      value = ''
   end
   if value.nil? then
      val = Date.today
      value = "#{val.year}/#{twodig(val.month)}/#{twodig(val.day)}"
   end
   
   "<input type='text' name='#{name}' value='#{value}' #{a2p(attribs)}> (yyyy/mm/dd)\n"
 end
 

end
end
