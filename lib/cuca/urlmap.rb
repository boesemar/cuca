
if __FILE__ == $0  then
 require 'rubygems'
 begin
   require 'cuca'
 rescue LoadError
 end
end

module Cuca

# URLMap will throw this in case we can't find a controller
# file for a URL.
class RoutingError < StandardError	# :nodoc:
end


# == URLMap 
#
# URLMap is used internally to match a URL to a controller file.
# Call with ds = URLMap.new('/path/to/app', 'path/from/url')
#                URLMap.new(base_path, url)
#
# You can then fetch the following values:
#
# * script 		- path to the controller file
# * url			- unmodified URL as passed to initializer
# * assigns 		- hash with variable assigns from the url (magick prefixes)
# * subcall 		- name of subcall or nil if a normal call was made
# * action 		- Action name (Note: action.capitalize+"Controller" is your controller class name)
# * base_url		- Base URL to the action (e.g.: /user/someone/show is -> /user/someone/)
# * base_path		- Unmodified base_path
# * action_path 	- Path to the action script
# * action_path_full 	- Full path to action script
# * path_tree		- an array of each directory on the way from /path/to/app to the script
#                         (to look for include_directories in - see Cuca::Config)
# * action_module	- The module the action should be loaded into (to avoid name conflicts, depends on action_path)
#
#
# == Match on other URL
#
# A widget/controller can make use of the URLMap object to scan on other directories (example to find out if a
# link url will be withing the same controller).
#
# See match? / submatch? and usubmatch?
#
#
# == Notes
#
# URL's ending with '/' will be scanned for default index files.
#
# URL's where last part (action) starts with '-' will be scanned for
# subcalls
#
# If no script is found or any other error it will raise a RoutingError exception
#
#
# == Example
#
#  u = URLMap.new('/home/bones/src/cuca_app/app', 'customer/southwind_lda/show'
#  
#  u.script 	 => '/home/bones/src/cuca_app/app/customer/__customer/show.rb'
#  u.action 	 => 'show'
#  u.base_url    => '/customer/__customer/'
#  u.assigns 	 => { 'customer' => 'southwind_lda' }
#  u.action_path => 'customer/southwind_lda/'
#
class URLMap
 attr_reader :url		# current url
 attr_reader :assigns
 attr_reader :script
 attr_reader :subcall
 attr_reader :base_url
 attr_reader :base_path
 attr_reader :action
 attr_reader :action_path
 attr_reader :action_path_full
 attr_reader :action_module
 attr_reader :path_tree
 
 DEF_ACT = Cuca::App::config['magic_action_prefix'] || '__'
 DEF_IDX = [ 'index', 'default' ]

 private 
 def scan_file(base, file)

   if (file == '') then 	# check for default index file
     DEF_IDX.each do |idxfile|
       if File.exist?("#{base}/#{idxfile}.rb")
          @action = idxfile
          return "#{idxfile}.rb"
       end
     end
     raise RoutingError.new("No default index file found in #{base}")
   end
   
   @action = file
   
   # check if a regular file exists:
#   puts "Checking file on #{check}"
   return (file+".rb") if File.exist?("#{base}/#{file}.rb")
   
   # check if the subcall file exists:
   if (file[0].chr == '-') then
      (action,subcall) = file.scan(/^\-(.*)\-(.*)$/).flatten
      if action.nil? || subcall.nil? || action.strip.empty? then
        raise RoutingError.new("Bad format on subcall: #{file}")
      end
      raise RoutingError.new("Script not found for subcall: #{file}: #{action}.rb") if !File.exist?("#{base}/#{action}.rb")
      @subcall = subcall
      @action = action
      return "#{action}.rb"
   end 
 end


 # scan_dir will look within a realdirectory for an unparsed url 'file' and return 
 # it's real path
 private
 def scan_dir(base, file)
   striped = "#{base}/#{file}"[@base_path.length..-1]
   mount = Cuca::App.config['mount']  || {}
#   $stderr.puts "SCAN DIR: #{striped}"
#   $stderr.puts "MOUNTS:   #{mount.inspect}"
#  $stderr.puts "AGAINST:  #{striped} #{mount.has_key?(striped).inspect}"
   

   
   if mount["#{striped}/"] then
#      $stderr.puts "Found mount point, returning: #{mount["#{striped}/"]}"
      return mount["#{striped}/"]
   end

   if File.directory?("#{base}/#{file}") then
     return file.empty? ? base : "#{base}/#{file}"		# avoid returning double //
   end
   
   d = Dir["#{base}/#{DEF_ACT}*"].map { |f| f.split('/').last }

#   puts "Directory not found, checking for default in #{base}  - #{file}"

#   puts d.inspect
#   
  
   raise RoutingError.new("Multiple default actions defined in #{base}") if  d.size > 1 
   raise RoutingError.new("Routing Error in #{base}") if d.empty?


   @assigns[d[0][DEF_ACT.size..-1]] = file
   "#{base}/#{d[0]}"
 end


 private
 def make_module(path)
   const_name = "Appmod_#{path.gsub(/[\/\\]/, '_')}"
   
   if Cuca::Objects::const_defined?(const_name.intern) then
     return Cuca::Objects::const_get(const_name.intern)
   end
 
   m = Module.new
   Cuca::Objects::const_set(const_name.intern, m)
   return m
 end


 # removes double slashes from a path-string
 def clean_path(directory)
   directory.gsub(/\/\//, '/')
 end

 # scan will match an URI to a script and set assigns. (called from initialize)
 private
 def scan
   files = @path_info.split('/')

   files << '' if @path_info[@path_info.size-1].chr == '/'		# add empty element if we point to a directory

   # files now contains something like:
   # ['', 'users', 'show', 'martin', 'contacts']

#   puts files.inspect  
   real_path = @base_path.dup

   @path_tree = [] if files.size > 1

   # scan directory
   files.each_index do |idx| 
     next if idx >= (files.size-1)  # skip last element
     r = scan_dir(real_path, files[idx])
     raise RoutingError.new("Routing Error at #{real_path} - #{files[idx]}") if !r
     @path_tree << r
     real_path = r
   end

   @url               = @path_info
   @base_url	      = "#{files[0..-2].join('/')}/"
   @action_path       = real_path[@base_path.length..-1]
   @action_path_full  = real_path 
   @action_module     = make_module(@action_path)
   
   # scan file (last element)
   r = scan_file(real_path, files.last)

   raise RoutingError.new("Routing Error - script not found at #{real_path} - #{files.last}") if !r
   
   real_path = clean_path("#{real_path}/#{r}")

   @script          = File.expand_path(real_path)
#   @path_tree	    = _tree(@base_path, @script)
   self
 end

 
 # match will check if the supplied url maches with a script
 # returns boolean
 #
 # Example: 
 #  URLMap('/path/to/app', '/customer/southwind_lda/').match?('/path/to/app/customer/__custid/index.rb') => true
 public
 def match?(script)
   m_script = @script
   p_script = File.expand_path(script)
   
#   $stderr.puts "URLMap::match - #{m_script} - #{p_script}"
   return (m_script == p_script)
   rescue RoutingError
     false
 end
 

 # this will match if the current script can be found within a path
 # from the parameters.
 #
 # Example:
 #  URLMap('/path/to/app', '/customer/southwind_lda/').submatch?('/customer/__custid/') => true 
 public
 def submatch?(some_path)
#    $stderr.puts "Submatch: #{some_path} with #{@script} - #{(@script.length < some_path.length).inspect} #{@script.include?(some_path)}"
    return false if @script.length < some_path.length
    return @script.include?(some_path)
 end
 
 # this will match the current script to a part of a url (link):
 #
 # Example:
 #  URLMap('/path/to/app', '/customer/southwind_lda/').submatch?('/customer/other_customer/') => true 
 public
 def usubmatch?(some_path)
    @path_info.include?(some_path)
 end

 # FIXME: needed?
 public
 def has_script?(script)
    return !(@script == '')
 end
 

 def initialize(base_path, path_info, default_actions = ['index'])
   @path_info = path_info
   @base_path = clean_path(File.expand_path(base_path))
   @script    = ''
   @subcall   = nil
   @default_actions = default_actions
   @assigns = {}
   @action = ''
   @action_path = ''
   @path_tree = [@base_path]
   scan
   self
 end

end

end


#
# Testings:
#

if __FILE__ == $0  then
require 'cuca/app'
 
 BASE = '/home/bones/src/cuca/app'
 URL  = 'user/martin/somewhere/notexist/'
 
 puts "Testing on '#{BASE}' - '#{URL}'"
 
 module Cuca
  ds = URLMap.new(BASE, URL)
 begin
  rescue RoutingError => e
  puts "E: Invalid request #{$!}"
 end



  puts "Match with: #{ds.match?('/home/bones/src/cuca/app/user/__default_username/index.rb')}"
  puts "Submatch with /user/__username/ #{ds.submatch?('/user/__username/')}"
  puts "Submatch with '/user/' #{ds.submatch?('/user/')}"
  puts "USubmatch with '/user/' #{ds.usubmatch?('/user/martin')}"
  puts
  puts "Script is:        #{ds.script}"
  puts "Assigns are:      #{ds.assigns.inspect}"
  puts "Subcall:          #{ds.subcall.inspect}"
  puts "Action:           #{ds.action}"  
  puts "Action Path:      #{ds.action_path}"
  puts "Action Path Full: #{ds.action_path_full}"
  puts "Action Module:    #{ds.action_module.inspect}"
  puts "Path tree:        #{ds.path_tree.inspect}"
  end
  
end







# URL:             "/user/martin/show"
# DIR:             "/user/__userid/show'
# MOUNT:           "/user/__userid/" =>>> "/plugin/user"   contains 'show'
# MOUNT:           "/user/__userid/" =>>> "/plugin/user2"  contains 'see'


 





