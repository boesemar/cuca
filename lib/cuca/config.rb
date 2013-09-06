module Cuca

 # = Configure the application
 # App::Config is normally called from conf/environment.rb . The attributes below the framework
 # will make use of, but you can always define own ones.
 #
 # == Example
 #
 #  Cuca::App.configure do |conf|
 #      conf.include_directories = %{_widgets _special_widgets}
 #      conf.database            = 'mydb'		# application specific
 #  end
 #
 #
 # == Attributes:
 # 
 # The file *conf/environment.rb* within your application path contains a full list of
 # attributes you can set.
 #
 
 class Config < Hash
   def method_missing(m, *params)
       met = m.id2name

   #    raise NoMethodError 
       if met[met.size-1].chr == '=' then
         self[met[0..met.size-2]] = params[0]
         return
       end

       if met[-2..-1] == '<<' then
         self[met[0..met.size-3]] ||= []
         self[met[0..met.size-3]] << params[0]
         return
       end

       return self[met] unless self[met].nil?
  
      raise NoMethodError
   end
   
   # some default stuff
   def initialize
     self['include_directories'] = %w{_controllers _widgets _layouts}
     self['log_level']  = 3
     self['magic_prefix'] = '__default_'
     self['session_key'] = 'cuca_session'
     self['session_prefix'] = 'cuca.'
     self['session_valid'] = 3600*24
     self['view_directory'] = 'app/_views'	# where to find views for the view/erb generator
     self['http_404'] = '404.html'
     self['http_500'] = '500.html'
     self['default_mime_type'] = 'text/html'
     self['display_errors'] = true
     self['http_static_content_expires'] = 300	# expires http header for static content (only if served by the dispatcher)
   end
   
 end

end
