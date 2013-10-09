# === conf/config.rb 
# Use this file to set initial cuca framework and application configuration 
# values - Only!
#
# You should not use this to load additional libraries or to modify cuca classes. Use
# conf/environment.rb instead.
#
# The cuca framework itself isn't fully loaded at this point.
#
# === Using Cuca::App.configure:
#
# You can pass any information here as you like. Some settings the framework
# will make use of, but this is also the right place to define application
# specific settings.
# You can access these values later anytime with Cuca::App.config[key]

Cuca::App.configure do |config|
  ### future use?
  config.log_level     = 3

  ### Files within these directories will be automatically 'required' before
  ### your controller script get loaded. Cuca will look for these directories
  ### relatively to your action script. It will also require all these directories
  ### in lower levels of your directory layout.
  config.include_directories = %w{_controllers _layouts _models _widgets}

  ### This would be an autoload configuration
  # config.include_directories = [
  #    { :dir => '_controllers', :class_naming => lambda { |f| f.capitalize+'Controller' } },
  #    { :dir => '_widgets',     :class_naming => lambda { |f| f.capitalize+'Widget' } },
  #    { :dir => '_layouts',     :class_naming => lambda { |f| f.capitalize+'Layout' } },
  #    { :dir => '_models',      :class_naming => lambda { |f| f.capitalize } }
  #  ]

  ### For pretty url mapping
  # config.magic_action_prefix = '__'
  
  ### This defines the session cookie definitions
  # config.session_key = 'cuca_session'
  # config.session_prefix = 'cuca.'
  # config.session_valid = 3600*24		# (one day)

  ### the view generator will look for external templates here:
  # config.view_directory = 'app/_views'	
  
  ### Force encoding of views to this one, if undefined default external
  ### encoding will be used. Encoding name must be accepted by Ruby Encoding class
  # config.view_encoding = 'UTF-8'
  
  ### 404 (file not found) and 500 system error page (relative to the public folder)
  # config.http_404 = '404.html'
  # config.http_500 = '500.html'
  
  ### display_errors: Instead of showing a http-500 page this will display an application
  ### trace (similar to php display-errors) on an error event. Switch that off once in
  ### production.
  # config.display_errors = true

  ### Default mime type to be sent within the http header unless specified by the 
  ### Controller
  # config.default_mime_type = 'text/html'

  ### Mount external Directories to the application path. This only works with
  ### directories and have higher priority than local files.
  ### Example:
  # config.mount = { '/customer/special => "#{$cuca_path}/plugins/special",
  #                  '/systeminfo/'     => "/usr/cuca/static/sysinfo/" }
  
  ### 'expires' http header for static content (only if served by the dispatcher), in seconds
  # config.http_static_content_expires = 300

end
