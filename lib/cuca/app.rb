require 'logger'
require 'cuca/config'
require 'cuca/urlmap2'
require 'concurrent'

$cuca = Concurrent::ThreadLocalVar.new({})

def cuca_register_autoload(object, file)
 autoload(object, file)
end

module Cuca

# Sandbox is used internally run the action script defined by the controller
# In future this can be extended to implement some security features etc..
    class Sandbox

        def self.run(controller_class_name, mod, assigns, request_method, subcall)
            self.class.send(:include, mod)
            controller_class = mod::const_get(controller_class_name)
            controller = controller_class.send(:new, :assigns=>assigns)
            $cuca.value[:controller_object] = controller
        
            controller.run_before_filters
            case request_method
                when 'POST'
                    controller.send('_do'.intern, 'run', subcall)
                    controller.send('_do'.intern, 'post', subcall)
                when 'GET'
                    controller.send('_do'.intern, 'run', subcall)
                    controller.send('_do'.intern, 'get', subcall)
                when 'PUT'
                    controller.send('_do'.intern, 'put', subcall)
                when 'PATCH'
                    controller.send('_do'.intern, 'patch', subcall)
                when 'HEAD'
                    controller.send('_do'.intern, 'head', subcall)
                when 'DELETE'
                    controller.send('_do'.intern, 'delete', subcall)
                when 'OPTIONS'
                    controller.send('_do'.intern, 'options', subcall)        
            end
            controller.run_after_filters
            return [controller.http_status, controller.mime_type, controller.to_s, controller.http_header]
        end
    end # class Sandbox

    # == Cuca Application
    #
    # A Cuca::App object will be created directly by the dispatcher - which again is the
    # direct cgi or fastcgi script that get run by the webserver.
    # Normally you just create a Cuca::App object and run the cgicall method with optional with
    # a cgi object as paramenter.
    # Before doing that you must set $cuca_path to the root of your application directory structure.
    class App


        attr_reader :app_path, :log_path, :public_path, :url_scan, :cgi, :logger, :urlmap, :exception_logger
        def logger=(log); @logger = log ; end
        @@app_config = Cuca::Config.new

        ## Application configuration
        public
        def self.configure
            yield @@app_config
        end

        def self.config
            @@app_config
        end

        # will do a 'require' on all .rb files in path
        def include_files(path)
            return unless File.exist?(path)
            pwd = Dir.pwd
            Dir.chdir(path)
            Dir['*.rb'].each do |f|
                require "#{path}/#{f}"
            end
            Dir.chdir(pwd)
        end

        # this will schedule all files for autoloading
        def autoload_file(node, naming_proc)
            path = node.value[:path]
            fn = path.scan(/.*\/(.*)\.rb/)[0][0]
            classname = naming_proc.call(fn)
            logger.debug "Scheduling Autoload Object #{classname.intern.inspect} ==> #{path}"

            cuca_register_autoload(classname.intern, clean_path(path))
        end

        # removes double slashes from a path-string
        def clean_path(directory)
            directory.gsub(/\/\//, '/')
        end

        def initialize(app_path: nil, log_path: nil, public_path: nil, additional_support_directory:nil)
            @app_path    = app_path || ($cuca_path + "/app")
            @app_path = [@app_path] unless @app_path.kind_of?(Array)
            @public_path = public_path || ($cuca_path + "/public")
            @log_path    = log_path || ($cuca_path + "/log")
            @app_path.freeze
            @public_path.freeze
            @log_path.freeze
            @logger      = Logger.new("#{@log_path}/messages")
            @logger.level = App.config['log_level'] || Logger::WARN


            #Custom exceptions logger
            @exception_logger = Logger.new((App.config['exceptions_log'] ? "#{@log_path}/exceptions" : "/dev/null")) 
            @exception_logger.level = Logger::ERROR
            @exception_logger.formatter = proc do |severity, datetime, progname, msg|
                "#{msg}"
            end

            @additional_support_directory = clean_path(additional_support_directory) if additional_support_directory
            @urlmap = Cuca::URLMap2.new do |config|
                config.base_path = @app_path
            end
        end

        # this will yield all support directories from base path and if defined
        # the naming proc else nil
        def all_support_directories(path_tree)
            path_tree.each do |t|
                (App::config['include_directories'] || []).each do |id|
                    if id.instance_of?(Hash) then
                        yield "#{t}/#{id[:dir]}", id[:class_naming]
                    else
        	            yield "#{t}/#{id}", nil
                    end
                end
            end
        end

        def load_support_files(scan_result)  # :nodoc:
            scan_result.path_tree.each do |pt|
                (App::config['include_directories'] || []).each do |id|
                    dir = id[:dir]
                    pro = id[:class_naming]
            
                    load_path = pt.children.find { |c| c.name == dir }      # raw finder
                    if load_path then
                        load_path.children.each do |file|
                            next unless file.value[:type] == :file
                            if pro then 
                                autoload_file(file, pro)
                            else
                                raise "not implemented"
                                include_files(file.value[:path])
                            end
                        end
                    end
                end
            end
        end
    
        # this will build an error message depending on configuration
        def get_error(title, exception, show_trace = true, file=nil)
            err = "<h3>#{title}</h3>"
            err << "<b>#{exception.class.to_s}: #{CGI::escapeHTML(exception.to_s)}</b><br/><br/>"
#           $stderr.puts "ERROR: #{title} - #{exception.class.to_s}: #{exception.to_s}"
            if (show_trace) then
                exception.backtrace.each do |b|
#                   $stderr.puts "   #{b}"
                    err +="<br/>#{b}"
                end
            else
                begin
                    err = File.open(file).read
                rescue
                end
            end
            err
        end


        def status2code(cgi_status)
            x = CGI::HTTP_STATUS[cgi_status]
            x||= "500 unknown status: #{cgi_status.inspect}"
            x.split(' ').first.to_i
        end

        def sanitize_headers(headers)    
            if headers['cookie'] then 
                headers['set-cookie'] = headers['cookie'].to_s
                headers.delete('cookie')
            end
            if headers['type'] then 
                headers['content-type'] = headers['type'].to_s
                headers.delete('type')
            end
      
            headers
        end

        def rack_response(code, headers, content)
            [code, sanitize_headers(headers), [content]]
        end

        def get_exception_log_message(e, type) 
            msg = "[EXCEPTION] date=[#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}] "
            msg << "type=[#{type}] "
            msg << "user=[#{$cuca.value[:request].env['rack.session']['user'] rescue ""}] "
            msg << "url=[#{$cuca.value[:request].env['HTTP_HOST'] rescue ""}#{$cuca.value[:request].env['REQUEST_PATH'] rescue ""}] "
            msg << "message=[#{e.inspect}]\n"

            return msg
        end

        def rackcall(env, after_init:nil)
            $cuca.value = {}
            $cuca.value[:app] = self
            $cuca.value[:request] = Rack::Request.new(env)
            $cuca.value[:env] = env

            #
            # 1st priority: Serve a file if it exists in the 'public' folder
            #
            file = @public_path + '/' + Rack::Utils.unescape($cuca.value[:request].path_info)
            if File.exists?(file) && File.ftype(file) == 'file' then
                require 'cuca/mimetypes'
                mt = MimeTypes.new
                file_content = File.open(file) { |f| f.read }
                extension = file.scan(/.*\.(.*)$/)[0][0] if file.include?('.')
                extension ||= 'html'
                mime = mt[extension] || 'text/html'
                return rack_response(200, 
                    { 'type' => mime, 
                    'expires' => (Time.now+App.config['http_static_content_expires']).to_s }, 
                    file_content)
            end
 
            begin 
                url_scan = @urlmap.scan($cuca.value[:request].path_info)
                $cuca.value[:url_scan] = url_scan
            rescue RoutingError => e
                err = get_error("Routing Error", e,
                Cuca::App.config['display_errors'], Cuca::App.config['http_500'])
                logger.info "CGICall Syntax Error"
                return rack_response(404, {'content-type' => 'text/html'}, err)
            end
 
            logger.info "RackCall on #{url_scan.url} - #{url_scan.script}"
            script = $cuca.value[:url_scan].script
 
            #
            # 2nd: Check if we have a script for requested action
            #
            if (!File.exists?(script)) then
              return [500, {}, ["Script not found: #{script}"]]
            end
        
            # 3rd: Load additional files
            load_support_files($cuca.value[:url_scan])
 
            # allow external code to be executed at this point
            if after_init then 
                after_init.call
            end
        
            # 4th: Now let's run the actual page script code
            if Cuca::App.config['controller_naming'] then
                controller_class_name = Cuca::App.config['controller_naming'].call($cuca.value[:url_scan].action)
            else
                controller_class_name = url_scan.action.capitalize+"Controller"
            end
 
            # Clear all hints
            Widget::clear_hints()

            # Load the code of the action into the module
            controller_module = $cuca.value[:url_scan].action_module
 
 
            # things fail in this block get error logged and/or displayed in browser
            begin
                # load controller
                begin
                    controller_module.module_eval(File.read(script), script)  unless \
                                controller_module.const_defined?(controller_class_name.intern)
                rescue SyntaxError,LoadError => e
                    err = get_error("Can not load script", e,
                    Cuca::App.config['display_errors'], Cuca::App.config['http_500'])
                    return [500, {}, [err]]
                end
           
                # Catch a common user error
                raise Cuca::ApplicationException.new("Could not find #{controller_class_name} defined in #{script}") \
                    unless controller_module.const_defined?(controller_class_name.intern)
                     
                    
                # run controller
                (status, mime, content, headers) = Sandbox.run(controller_class_name,
                                    controller_module, $cuca.value[:url_scan].assigns,
                                    $cuca.value[:request].request_method, $cuca.value[:url_scan].subcall)

                logger.debug "RackCall OK: #{status}/#{mime}"

                #raise  headers.merge( { 'type' => mime, 'status' => status}).inspect
                headers =  headers.merge( { 'content-type' => mime})
                code = self.status2code(status)
                return rack_response(code, headers, content)

            rescue SyntaxError => e
                err = get_error("Syntax Error", e,
                        Cuca::App.config['display_errors'], Cuca::App.config['http_500'])
                logger.info "CGICall Syntax Error"
                exception_logger.error get_exception_log_message(e, "Syntax Error")
                return rack_response(500, {}, err)
 
 
            rescue Cuca::ApplicationException => e
                err = get_error("Application Error", e,
                        Cuca::App.config['display_errors'], Cuca::App.config['http_500'])
 
                logger.info "CGICall Application Error"
                exception_logger.error get_exception_log_message(e, "Application Error")
                return rack_response(500, {'content-type' => 'text/html'}, err)
 
            rescue => e
                err = get_error("System Error", e,
                        Cuca::App.config['display_errors'], Cuca::App.config['http_500'])
                logger.info "CGICall System Error"
                exception_logger.error get_exception_log_message(e, "Uncaught")
                
                return rack_response(500, {'content-type' => 'text/html'}, err)
            
            end #rescue block
        end # rackcall
    end # App
end # module
