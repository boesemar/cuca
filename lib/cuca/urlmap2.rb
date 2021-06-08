#
# The old UrlMap would just parse a directory and match a URL to a script.
#
# Urlmap2 instead will build a tree in memory out of many source directories and then perform searches to it.
# That way we can join separate directories on-disk into one unique tree to find URL's, as if they were one.
#
# See demo-code below
#

require 'ostruct'
require_relative './tree'
#require 'cuca/tree'




module Cuca
    module Objects; end
    class RoutingError < StandardError	# :nodoc:
    end

    class URLMap2
        attr :tree

        # removes double slashes from a path-string
        def self.clean_path(directory)
            directory.gsub(/\/\//, '/')
        end
        
        class Config < OpenStruct; end

        def initialize
            @config = Config.new(base_path: [], index_page: 'index')
            yield @config
            @tree = Tree.new(Tree::Node.new('/', value: { :type => :directory, :path => @config.base_path.first}))
            Tree::Node.update_compare = lambda do |a,b|
                return true if b.name[0..1] == '__' && a.name[0..1] == '__'
                b.name == a.name
            end
        
            Tree::Node.find_compare = lambda do |a,b|                
                if a.name[0..1] == '__' && b.value[:type] == :directory then 
                   return { a.name[2..-1] => b.name }    
                end
                if b.name =~ /^\-(.*)\-(.*)$/ then 
                    action = $1
                    return (a.name == action)
                end
                b.name == a.name
            end

            @config.base_path.each do |path|
                add_directory(URLMap2.clean_path(path))
            end

        end

        # this will add an app-directory to the @tree
        def add_directory(path)
            def path2nodes(p, base_path)
                part_path_a = []
                nodes = p.split('/').map do |n| 
                    part_path_a << n
                    part_path = part_path_a.join('/')
                    n = n[0..-4] if n =~ /\.rb$/
                    Tree::Node.new(n, value: { :type => :directory, :path=>"#{base_path}/#{part_path}", :base_path => part_path } )
                end
                if !File.directory?("#{base_path}/#{p}") then #p.split('/').last[-1] != '/' then 
                    nodes[-1].value[:type] = :file
                end
                nodes
            end

            file_list = []
            Dir.glob("#{path}/**/*").each do |file|
                next if !File.directory?(file) && file !~ /\.rb$/
                part_file = file[path.size+1..-1]
                file_list << part_file
            end
            file_list = file_list.sort { |d| d.count('/') }
            file_list.each do |f|
                @tree.root.add_nodes_r(path2nodes(f, path))
            end
        end

        def make_module(path)
            const_name = "Appmod_#{path.gsub(/[\/\\\-\.]/, '_')}"
            
            if Cuca::Objects::const_defined?(const_name.intern) then
              return Cuca::Objects::const_get(const_name.intern)
            end
          
            m = Module.new
            Cuca::Objects::const_set(const_name.intern, m)
            return m
        end
         
        # scan a user path
        def scan(url)
            split_url_raw = url.split('/').find_all { |e| e!='' }
            split_url = split_url_raw.map { |u| Tree::Node.new(u, value: {:type => :directory})  }
            if url[-1] != '/' then 
                split_url.last.value = {:type => :file}
            end
            match = @tree.root.scan_path(split_url)            
            if !match then 
                raise RoutingError, "Can not find path in tree #{url}"
            end

            node = match[:node]

            result = OpenStruct.new

            # if we point to a directory, fall-back to index
            if node.value[:type] != :file then 
                index = node.children.find { |x| x.name == 'index' }
                if !index then 
                    raise RoutingError, "Can't find index page in #{node.inspect}, we have #{node.children.map { |c| c.inspect}.join("<br>")}"
                end
                node = index    
                result.action = 'index'
            else
                # sucalls
                if split_url.last.name =~ /^\-(.*)\-(.*)$/ then 
                    result.action = $1
                    result.subcall = $2
                end
            end

            assigns = match[:assigns]


            result.url = url
            result.assigns = assigns
            result.script = node.value[:path]
            result.action ||= split_url.last.name
            result.base_url = split_url_raw.join('/')
            result.action_module = make_module(node.value[:base_path]) ## result.base_url)
            
            p = node
            pt = []
            begin
                val = p.value || {}
                pt << p if val[:type] == :directory
                p = p.parent
            end while p
            
            result.path_tree = pt

            last_part = split_url.last
            if last_part =~ /^\-(.*)\-(.*)$/ then 
                result.subcall = $2
                result.action = $1
            end

            result
        end
    end
end


if __FILE__ == $0  then
    um = Cuca::URLMap2.new do |config|
        config.base_path = ["/home/bones/git/m3ms-3/app", "/tmp/cuca"]
    end
#    puts um.tree.root.to_s
    require 'yaml'
#   puts um.tree.to_s
#    puts um.scan("/customer/ita/-supergraph-stuff").inspect
   puts um.scan(ARGV.first).inspect
   puts '-----'
   puts um.scan(ARGV.first).path_tree.map {|x| x.inspect}.join("\n")# inspect
end